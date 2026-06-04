package com.replymate.reply_mate

import android.app.Application
import android.util.Log

/**
 * Restores foreground service when the process starts (e.g. after swipe-away restart).
 */
class ReplyMateApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Application.onCreate")
        try {
            if (com.google.firebase.FirebaseApp.getApps(this).isEmpty()) {
                com.google.firebase.FirebaseApp.initializeApp(this)
                Log.d(TAG, "Firebase initialized in Application.onCreate")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize Firebase in Application.onCreate", e)
        }
    }

    companion object {
        private const val TAG = "ReplyMateApp"
    }
}
