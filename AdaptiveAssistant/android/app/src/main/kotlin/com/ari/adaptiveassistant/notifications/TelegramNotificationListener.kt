package com.ari.adaptiveassistant.notifications

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class TelegramNotificationListener : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        val notification = sbn ?: return
        val extras = notification.notification.extras
        val title = extras.getString("android.title") ?: ""
        val text = extras.getCharSequence("android.text")?.toString() ?: ""
        NotificationCache.add(
            mapOf(
                "package" to notification.packageName,
                "title" to title,
                "text" to text,
                "timestamp" to notification.postTime
            )
        )
    }
}
