package com.grabbit.grabbit

import android.content.ContentResolver
import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Platform Channel for GRABBIT's file index.
 *
 * Responsibilities:
 * - Initial full scan via MediaStore (called once on first launch)
 * - Incremental updates via ContentObserver on MediaStore.Files
 * - File operations: move, copy, delete via SAF when needed
 * - App info: PackageManager queries for App Manager feature
 *
 * The Flutter side (Dart) handles all SQLite/FTS5 operations.
 * This channel only provides raw file metadata from the Android system.
 */
class GrabbitIndexChannel(private val flutterEngine: FlutterEngine) {

    companion object {
        private const val METHOD_CHANNEL = "com.grabbit/index"
        private const val EVENT_CHANNEL = "com.grabbit/file_events"
    }

    private var contentObserver: ContentObserver? = null
    private var eventSink: EventChannel.EventSink? = null

    fun register() {
        // Method channel for on-demand operations
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanAll" -> {
                    // TODO: Full MediaStore scan, return list of file metadata maps
                    result.success(emptyList<Map<String, Any?>>())
                }
                "scanIncremental" -> {
                    val since = call.argument<Long>("since") ?: 0L
                    // TODO: Query MediaStore for files modified after `since`
                    result.success(emptyList<Map<String, Any?>>())
                }
                "getInstalledApps" -> {
                    // TODO: PackageManager query
                    result.success(emptyList<Map<String, Any?>>())
                }
                "deleteFile" -> {
                    val path = call.argument<String>("path")
                    // TODO: SAF-aware file deletion
                    result.success(path != null)
                }
                "moveFile" -> {
                    val from = call.argument<String>("from")
                    val to = call.argument<String>("to")
                    // TODO: SAF-aware file move
                    result.success(from != null && to != null)
                }
                else -> result.notImplemented()
            }
        }

        // Event channel for real-time file system changes
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                startObserving()
            }

            override fun onCancel(arguments: Any?) {
                stopObserving()
                eventSink = null
            }
        })
    }

    private fun startObserving() {
        val context = flutterEngine.dartExecutor.binaryMessenger
        // Note: actual context comes from the Activity — this is a skeleton
        // contentObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
        //     override fun onChange(selfChange: Boolean, uri: Uri?) {
        //         eventSink?.success(mapOf("type" to "changed", "uri" to uri?.toString()))
        //     }
        // }
        // context.contentResolver.registerContentObserver(
        //     MediaStore.Files.getContentUri("external"),
        //     true,
        //     contentObserver!!
        // )
    }

    private fun stopObserving() {
        // contentResolver.unregisterContentObserver(contentObserver!!)
        contentObserver = null
    }
}
