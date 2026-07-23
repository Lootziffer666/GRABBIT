package com.grabbit.grabbit

import android.app.Activity
import android.content.ContentUris
import android.content.Intent
import android.provider.Settings
import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Platform Channel for GRABBIT's file index.
 *
 * Handles:
 * - Full scan via MediaStore (first launch)
 * - Incremental scan (files modified since X)
 * - Real-time ContentObserver events
 * - File operations (delete, move, rename, copy)
 * - App list from PackageManager
 */
class GrabbitIndexChannel(
    private val activity: Activity,
    private val flutterEngine: FlutterEngine
) {
    companion object {
        private const val METHOD_CHANNEL = "com.grabbit/index"
        private const val EVENT_CHANNEL = "com.grabbit/file_events"
    }

    private var contentObserver: ContentObserver? = null
    private var eventSink: EventChannel.EventSink? = null

    fun register() {
        // Method channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanAll" -> {
                    Thread {
                        try {
                            val files = performFullScan()
                            Handler(Looper.getMainLooper()).post {
                                result.success(files)
                            }
                        } catch (e: Exception) {
                            Handler(Looper.getMainLooper()).post {
                                result.error("SCAN_ERROR", e.message, null)
                            }
                        }
                    }.start()
                }
                "scanIncremental" -> {
                    val since = call.argument<Long>("since") ?: 0L
                    Thread {
                        try {
                            val files = performIncrementalScan(since)
                            Handler(Looper.getMainLooper()).post {
                                result.success(files)
                            }
                        } catch (e: Exception) {
                            Handler(Looper.getMainLooper()).post {
                                result.error("SCAN_ERROR", e.message, null)
                            }
                        }
                    }.start()
                }
                "getInstalledApps" -> {
                    Thread {
                        try {
                            val apps = getInstalledApps()
                            Handler(Looper.getMainLooper()).post {
                                result.success(apps)
                            }
                        } catch (e: Exception) {
                            Handler(Looper.getMainLooper()).post {
                                result.error("APPS_ERROR", e.message, null)
                            }
                        }
                    }.start()
                }
                "openApp" -> result.success(openApp(call.argument<String>("package")))
                "openAppDetails" -> result.success(openAppDetails(call.argument<String>("package")))
                "uninstallApp" -> result.success(uninstallApp(call.argument<String>("package")))
                "deleteFile" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        result.success(deleteFile(path))
                    } else {
                        result.error("INVALID_ARG", "path required", null)
                    }
                }
                "moveFile" -> {
                    val from = call.argument<String>("from")
                    val to = call.argument<String>("to")
                    if (from != null && to != null) {
                        result.success(moveFile(from, to))
                    } else {
                        result.error("INVALID_ARG", "from and to required", null)
                    }
                }
                "copyFile" -> {
                    val from = call.argument<String>("from")
                    val to = call.argument<String>("to")
                    if (from != null && to != null) {
                        result.success(copyFile(from, to))
                    } else {
                        result.error("INVALID_ARG", "from and to required", null)
                    }
                }
                "renameFile" -> {
                    val path = call.argument<String>("path")
                    val newName = call.argument<String>("newName")
                    if (path != null && newName != null) {
                        result.success(renameFile(path, newName))
                    } else {
                        result.error("INVALID_ARG", "path and newName required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Event channel for real-time file changes
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

    // ── Full Scan ─────────────────────────────────────────────────────────

    private fun performFullScan(): List<Map<String, Any?>> {
        return queryMediaStore(selection = null, selectionArgs = null)
    }

    // ── Incremental Scan ──────────────────────────────────────────────────

    private fun performIncrementalScan(sinceMs: Long): List<Map<String, Any?>> {
        // MediaStore stores dates in seconds
        val sinceSeconds = sinceMs / 1000
        return queryMediaStore(
            selection = "${MediaStore.Files.FileColumns.DATE_MODIFIED} > ?",
            selectionArgs = arrayOf(sinceSeconds.toString())
        )
    }

    // ── MediaStore Query ──────────────────────────────────────────────────

    private fun queryMediaStore(
        selection: String?,
        selectionArgs: Array<String>?
    ): List<Map<String, Any?>> {
        val files = mutableListOf<Map<String, Any?>>()
        val resolver = activity.contentResolver

        val uri = MediaStore.Files.getContentUri("external")
        val projection = arrayOf(
            MediaStore.Files.FileColumns._ID,
            MediaStore.Files.FileColumns.DATA,           // full path
            MediaStore.Files.FileColumns.DISPLAY_NAME,
            MediaStore.Files.FileColumns.SIZE,
            MediaStore.Files.FileColumns.DATE_MODIFIED,
            MediaStore.Files.FileColumns.DATE_ADDED,
            MediaStore.Files.FileColumns.MIME_TYPE,
        )

        val cursor = resolver.query(
            uri,
            projection,
            selection,
            selectionArgs,
            "${MediaStore.Files.FileColumns.DATE_MODIFIED} DESC"
        ) ?: return files

        cursor.use {
            val idCol = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
            val dataCol = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATA)
            val nameCol = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DISPLAY_NAME)
            val sizeCol = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.SIZE)
            val modCol = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_MODIFIED)
            val addedCol = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_ADDED)
            val mimeCol = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MIME_TYPE)

            while (it.moveToNext()) {
                val path = it.getString(dataCol) ?: continue
                val name = it.getString(nameCol) ?: File(path).name
                val ext = name.substringAfterLast('.', "").lowercase().ifEmpty { null }
                val parent = File(path).parent ?: ""
                val size = it.getLong(sizeCol)
                val modified = it.getLong(modCol) * 1000 // convert to ms
                val created = it.getLong(addedCol) * 1000
                val mime = it.getString(mimeCol)

                // Guess source from path
                val source = guessSource(path)

                files.add(mapOf(
                    "path" to path,
                    "name" to name,
                    "ext" to ext,
                    "size" to size,
                    "modified" to modified,
                    "created" to created,
                    "parent" to parent,
                    "source" to source,
                    "mime" to mime,
                ))
            }
        }

        return files
    }

    // ── Source Guessing ───────────────────────────────────────────────────

    private fun guessSource(path: String): String {
        val lower = path.lowercase()
        return when {
            lower.contains("/dcim/") || lower.contains("/camera/") -> "camera"
            lower.contains("screenshot") -> "screenshot"
            lower.contains("/download") -> "download"
            lower.contains("whatsapp") -> "whatsapp"
            lower.contains("telegram") -> "telegram"
            lower.contains("chatgpt") || lower.contains("openai") -> "chatgpt"
            lower.contains("bluetooth") -> "bluetooth"
            lower.contains("/recording") -> "recording"
            else -> "unknown"
        }
    }

    // ── App List ──────────────────────────────────────────────────────────

    private fun getInstalledApps(): List<Map<String, Any?>> {
        val pm = activity.packageManager
        val apps = mutableListOf<Map<String, Any?>>()

        val packages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledPackages(0)
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledPackages(0)
        }

        for (pkg in packages) {
            val appInfo = pkg.applicationInfo ?: continue
            val label = pm.getApplicationLabel(appInfo).toString()
            val isSystem = (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
            val installTime = pkg.firstInstallTime
            val lastUpdate = pkg.lastUpdateTime

            apps.add(mapOf(
                "package" to pkg.packageName,
                "label" to label,
                "installed" to installTime,
                "last_used" to null,
                "is_system" to if (isSystem) 1 else 0,
                "size_bytes" to 0L, // requires StorageStatsManager, expensive
            ))
        }

        return apps
    }

    private fun openApp(packageName: String?): Boolean {
        if (packageName == null) return false
        val intent = activity.packageManager.getLaunchIntentForPackage(packageName) ?: return false
        activity.startActivity(intent)
        return true
    }

    private fun openAppDetails(packageName: String?): Boolean {
        if (packageName == null) return false
        activity.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.parse("package:$packageName")))
        return true
    }

    private fun uninstallApp(packageName: String?): Boolean {
        if (packageName == null) return false
        activity.startActivity(Intent(Intent.ACTION_DELETE, Uri.parse("package:$packageName")))
        return true
    }

    // ── File Operations ───────────────────────────────────────────────────

    private fun deleteFile(path: String): Boolean {
        return try {
            val file = File(path)
            if (file.exists()) {
                file.delete()
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun moveFile(from: String, to: String): Boolean {
        return try {
            val source = File(from)
            val dest = File(to)
            dest.parentFile?.mkdirs()
            source.renameTo(dest)
        } catch (e: Exception) {
            false
        }
    }

    private fun copyFile(from: String, to: String): Boolean {
        return try {
            val source = File(from)
            val dest = File(to)
            dest.parentFile?.mkdirs()
            source.copyTo(dest, overwrite = true)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun renameFile(path: String, newName: String): Boolean {
        return try {
            val source = File(path)
            val dest = File(source.parentFile, newName)
            source.renameTo(dest)
        } catch (e: Exception) {
            false
        }
    }

    // ── ContentObserver ───────────────────────────────────────────────────

    private fun startObserving() {
        contentObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                // Notify Flutter side about file change
                val event = mapOf(
                    "type" to "changed",
                    "uri" to (uri?.toString() ?: "")
                )
                eventSink?.success(event)
            }
        }

        activity.contentResolver.registerContentObserver(
            MediaStore.Files.getContentUri("external"),
            true,
            contentObserver!!
        )
    }

    private fun stopObserving() {
        contentObserver?.let {
            activity.contentResolver.unregisterContentObserver(it)
        }
        contentObserver = null
    }
}
