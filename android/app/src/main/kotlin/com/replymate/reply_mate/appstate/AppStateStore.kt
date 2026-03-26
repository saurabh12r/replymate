package com.replymate.reply_mate.appstate

import android.content.Context

/**
 * Minimal persisted app state for guarding early receivers during startup.
 */
object AppStateStore {
    private const val PREFS = "app_state"
    private const val KEY_READY = "app_ready"

    fun isAppReady(context: Context): Boolean {
        return try {
            context.applicationContext
                .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getBoolean(KEY_READY, false)
        } catch (_: Exception) {
            false
        }
    }

    fun setAppReady(context: Context, ready: Boolean) {
        try {
            context.applicationContext
                .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_READY, ready)
                .apply()
        } catch (_: Exception) {
        }
    }
}

