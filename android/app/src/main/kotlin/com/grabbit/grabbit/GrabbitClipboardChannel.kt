package com.grabbit.grabbit

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Platform Channel for GRABBIT's Persistent Clipboard.
 *
 * Input methods (all feed the same Flutter EventChannel):
 * 1. Tasker/MacroDroid BroadcastReceiver (ClipboardReceiver)
 * 2. Shizuku IClipboard listener (if available)
 * 3. Foreground ClipboardManager listener (fallback)
 *
 * Output methods:
 * - Normal clipboard set (ClipboardManager.setPrimaryClip)
 * - Shizuku bypass for >512KB content (IClipboard.setPrimaryClip)
 */
class GrabbitClipboardChannel(
    private val activity: Activity,
    private val flutterEngine: FlutterEngine
) {
    companion object {
        private const val METHOD_CHANNEL = "com.grabbit/clipboard"
        private const val EVENT_CHANNEL = "com.grabbit/clipboard_events"
    }

    private var eventSink: EventChannel.EventSink? = null
    private var clipboardManager: ClipboardManager? = null
    private var foregroundListener: ClipboardManager.OnPrimaryClipChangedListener? = null

    fun register() {
        clipboardManager = activity.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager

        // Method channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isShizukuAvailable" -> {
                    result.success(checkShizukuAvailable())
                }
                "startClipboardListener" -> {
                    startListening()
                    result.success(true)
                }
                "stopClipboardListener" -> {
                    stopListening()
                    result.success(true)
                }
                "setClipboardShizuku" -> {
                    val content = call.argument<String>("content")
                    if (content != null) {
                        result.success(setClipboardContent(content))
                    } else {
                        result.error("INVALID_ARG", "content required", null)
                    }
                }
                "setClipboard" -> {
                    val content = call.argument<String>("content")
                    if (content != null) {
                        result.success(setClipboardContent(content))
                    } else {
                        result.error("INVALID_ARG", "content required", null)
                    }
                }
                "getCurrentClipboard" -> {
                    result.success(getCurrentClipboard())
                }
                "getClipboardMethod" -> {
                    // Tell Flutter which method is active
                    result.success(getActiveMethod())
                }
                else -> result.notImplemented()
            }
        }

        // Event channel — all clipboard events flow through here
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                startListening()
            }

            override fun onCancel(arguments: Any?) {
                stopListening()
                eventSink = null
            }
        })
    }

    // ── Listening Methods ──────────────────────────────────────────────────

    private fun startListening() {
        // 1. Register BroadcastReceiver callback for Tasker/MacroDroid
        ClipboardReceiver.onClipReceived = { content, sourceApp, sourceLabel ->
            Handler(Looper.getMainLooper()).post {
                emitClipEvent(content, sourceApp, sourceLabel, "tasker")
            }
        }

        // 2. Register the BroadcastReceiver dynamically
        val filter = IntentFilter(ClipboardReceiver.ACTION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            activity.registerReceiver(ClipboardReceiver(), filter, Context.RECEIVER_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            activity.registerReceiver(ClipboardReceiver(), filter)
        }

        // 3. Foreground clipboard listener (catches copies when GRABBIT is open)
        foregroundListener = ClipboardManager.OnPrimaryClipChangedListener {
            val clip = clipboardManager?.primaryClip
            if (clip != null && clip.itemCount > 0) {
                val text = clip.getItemAt(0).coerceToText(activity).toString()
                if (text.isNotEmpty()) {
                    emitClipEvent(text, null, null, "foreground")
                }
            }
        }
        clipboardManager?.addPrimaryClipChangedListener(foregroundListener!!)

        // 4. Shizuku listener (if available) — TODO: implement when Shizuku SDK added
        // ShizukuClipboardHelper.startListening { content ->
        //     emitClipEvent(content, null, null, "shizuku")
        // }
    }

    private fun stopListening() {
        ClipboardReceiver.onClipReceived = null
        foregroundListener?.let {
            clipboardManager?.removePrimaryClipChangedListener(it)
        }
        foregroundListener = null
    }

    private fun emitClipEvent(
        content: String,
        sourceApp: String?,
        sourceLabel: String?,
        method: String
    ) {
        eventSink?.success(mapOf(
            "content" to content,
            "source_app" to sourceApp,
            "source_label" to sourceLabel,
            "method" to method,
            "timestamp" to System.currentTimeMillis()
        ))
    }

    // ── Output Methods ────────────────────────────────────────────────────

    private fun setClipboardContent(content: String): Boolean {
        return try {
            val clip = ClipData.newPlainText("grabbit", content)
            clipboardManager?.setPrimaryClip(clip)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun getCurrentClipboard(): String? {
        return try {
            val clip = clipboardManager?.primaryClip
            if (clip != null && clip.itemCount > 0) {
                clip.getItemAt(0).coerceToText(activity).toString()
            } else null
        } catch (_: Exception) {
            null
        }
    }

    // ── Status ────────────────────────────────────────────────────────────

    private fun checkShizukuAvailable(): Boolean {
        return try {
            // Check if Shizuku package is installed
            activity.packageManager.getPackageInfo("moe.shizuku.privileged.api", 0)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun getActiveMethod(): String {
        // Returns which clipboard capture method is currently active
        return when {
            checkShizukuAvailable() -> "shizuku"
            ClipboardReceiver.onClipReceived != null -> "tasker"
            else -> "foreground"
        }
    }
}
