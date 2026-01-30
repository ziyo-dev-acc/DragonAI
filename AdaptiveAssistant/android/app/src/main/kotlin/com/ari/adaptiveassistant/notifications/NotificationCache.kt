package com.ari.adaptiveassistant.notifications

import java.util.concurrent.LinkedBlockingDeque

object NotificationCache {
    private const val MAX = 50
    private val queue = LinkedBlockingDeque<Map<String, Any?>>(MAX)

    fun add(entry: Map<String, Any?>) {
        synchronized(queue) {
            if (queue.size == MAX) {
                queue.pollFirst()
            }
            queue.offerLast(entry)
        }
    }

    fun getLastTelegram(senderContains: String?): Map<String, Any?>? {
        synchronized(queue) {
            val items = queue.toList().reversed()
            return items.firstOrNull { item ->
                val pkg = item["package"] as? String ?: ""
                if (pkg != "org.telegram.messenger") return@firstOrNull false
                val title = item["title"] as? String ?: ""
                return@firstOrNull senderContains?.let { title.contains(it, ignoreCase = true) } ?: true
            }
        }
    }
}
