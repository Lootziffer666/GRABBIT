package com.grabbit.grabbit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * BroadcastReceiver for clipboard content from Tasker/MacroDroid.
 *
 * Tasker Setup:
 *   Event: Clipboard Changed
 *   Action: Send Intent
 *     Action: com.grabbit.CLIPBOARD_RECEIVED
 *     Extra: clip:%CLIP
 *     Package: com.grabbit.grabbit
 *     Target: Broadcast Receiver
 *
 * MacroDroid Setup:
 *   Trigger: Clipboard Change
 *   Action: Intent Broadcast
 *     Action: com.grabbit.CLIPBOARD_RECEIVED
 *     Extra: clip=[clipboard]
 *     Package: com.grabbit.grabbit
 *
 * This receiver takes the clipboard text and forwards it to Flutter
 * via the clipboard EventChannel sink.
 */
class ClipboardReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "GrabbitClip"
        const val ACTION = "com.grabbit.CLIPBOARD_RECEIVED"
        const val EXTRA_CLIP = "clip"
        const val EXTRA_SOURCE_APP = "source_app"
        const val EXTRA_SOURCE_LABEL = "source_label"

        // Static reference to the event sink (set by GrabbitClipboardChannel)
        var onClipReceived: ((String, String?, String?) -> Unit)? = null
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action != ACTION) return

        val clipText = intent.getStringExtra(EXTRA_CLIP)
        if (clipText.isNullOrEmpty()) {
            Log.d(TAG, "Received empty clipboard intent — ignoring")
            return
        }

        val sourceApp = intent.getStringExtra(EXTRA_SOURCE_APP)
        val sourceLabel = intent.getStringExtra(EXTRA_SOURCE_LABEL)

        Log.d(TAG, "Received clip: ${clipText.take(50)}... (${clipText.length} chars)")

        // Forward to Flutter via callback
        onClipReceived?.invoke(clipText, sourceApp, sourceLabel)
    }
}
