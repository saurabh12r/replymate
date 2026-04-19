package com.replymate.reply_mate.services

import android.app.Service
import android.content.Intent
import android.os.IBinder

class DummySmsService : Service() {
    override fun onBind(intent: Intent): IBinder? {
        return null
    }
}
