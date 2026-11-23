package com.example.cuhokhancap

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var localNotificationChannel: MethodChannel? = null
    private var pendingLocalNotificationTap: Map<String, String>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannels()

        localNotificationChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "admin_cuuho/local_notifications",
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "showLocalNotification" -> {
                        try {
                            val args = call.arguments as? Map<*, *>
                            if (args == null) {
                                result.error("invalid-arguments", "Thiếu dữ liệu thông báo.", null)
                            } else {
                                result.success(showLocalNotification(args))
                            }
                        } catch (error: Exception) {
                            result.error(
                                "notification-error",
                                "Không hiển thị được thông báo trên thiết bị.",
                                error.javaClass.simpleName,
                            )
                        }
                    }

                    "consumePendingNotificationTap" -> {
                        val pending = pendingLocalNotificationTap
                        pendingLocalNotificationTap = null
                        result.success(pending)
                    }

                    "clearPendingNotificationTap" -> {
                        pendingLocalNotificationTap = null
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
        }

        // Keep the existing contact bridge unchanged.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cuhokhancap/contact")
            .setMethodCallHandler { call, result ->
                val phone = call.argument<String>("phone") ?: ""
                if (call.method !in listOf("dial", "sms")) {
                    result.notImplemented()
                } else if (!Regex("^\\+?[0-9]{5,15}$").matches(phone)) {
                    result.error("invalid-phone", "Số điện thoại không hợp lệ", null)
                } else {
                    try {
                        val intent = if (call.method == "dial") {
                            Intent(Intent.ACTION_DIAL, Uri.fromParts("tel", phone, null))
                        } else {
                            Intent(Intent.ACTION_SENDTO, Uri.fromParts("smsto", phone, null))
                        }
                        startActivity(intent)
                        result.success(null)
                    } catch (error: Exception) {
                        result.error("unavailable", "Không mở được ứng dụng liên hệ", null)
                    }
                }
            }

        // Initial launch from a local notification: Dart consumes this after
        // registering its MethodChannel handler.
        captureLocalNotificationTap(intent, notifyDart = false)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // App already running: deliver immediately and retain as a fallback
        // until Dart confirms that it has consumed the pending tap.
        captureLocalNotificationTap(intent, notifyDart = true)
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val sound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val audio = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        val urgent = NotificationChannel(
            "admin_cuuho_khan_cap",
            "Cứu hộ khẩn cấp",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Yêu cầu cứu hộ mới và các ca cần Admin xử lý khẩn cấp."
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 350, 180, 350)
            setSound(sound, audio)
        }

        val dispatch = NotificationChannel(
            "admin_cuuho_dieu_phoi",
            "Phản hồi điều phối",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "Thông tin nhận, từ chối và hết hạn lời mời cứu hộ."
            enableVibration(false)
            setSound(sound, audio)
        }

        // Retain the previous channel so already queued/older notifications
        // remain compatible after updating the app.
        val legacy = NotificationChannel(
            "cuu_ho_quan_tri",
            "Thông báo cứu hộ (cũ)",
            NotificationManager.IMPORTANCE_HIGH,
        )

        manager.createNotificationChannels(listOf(urgent, dispatch, legacy))
    }

    private fun showLocalNotification(args: Map<*, *>): Boolean {
        val title = args["title"] as? String ?: "Thông báo cứu hộ"
        val body = args["body"] as? String ?: ""
        val data = args["data"] as? Map<*, *> ?: return false

        val payload = data.entries.mapNotNull { entry ->
            val key = entry.key as? String ?: return@mapNotNull null
            val value = entry.value as? String ?: return@mapNotNull null
            key to value
        }.toMap()

        val requestId = payload["maYeuCau"] ?: return false
        val adminId = payload["maAdmin"] ?: return false
        val notificationId = payload["maThongBao"] ?: return false
        if (requestId.isBlank() || adminId.isBlank() || notificationId.isBlank()) {
            return false
        }

        val requestedChannel = args["channelId"] as? String
        val channelId = if (requestedChannel == "admin_cuuho_khan_cap") {
            "admin_cuuho_khan_cap"
        } else {
            "admin_cuuho_dieu_phoi"
        }

        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("adminCuuHoLocalNotification", true)
            payload.forEach { (key, value) -> putExtra(key, value) }
        }

        val requestCode = notificationId.hashCode() and 0x7fffffff
        val immutableFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            requestCode,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag,
        )

        val builder: Notification.Builder =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(this, channelId)
            } else {
                Notification.Builder(this).apply {
                    setPriority(
                        if (channelId == "admin_cuuho_khan_cap") {
                            Notification.PRIORITY_HIGH
                        } else {
                            Notification.PRIORITY_DEFAULT
                        }
                    )
                    setDefaults(
                        if (channelId == "admin_cuuho_khan_cap") {
                            Notification.DEFAULT_ALL
                        } else {
                            Notification.DEFAULT_SOUND
                        }
                    )
                }
            }

        builder.setSmallIcon(R.drawable.ic_stat_admin_cuuho)
        builder.setContentTitle(title)
        builder.setContentText(body)
        builder.setStyle(Notification.BigTextStyle().bigText(body))
        builder.setContentIntent(pendingIntent)
        builder.setAutoCancel(true)
        builder.setShowWhen(true)
        builder.setWhen(System.currentTimeMillis())
        builder.setVisibility(Notification.VISIBILITY_PRIVATE)
        builder.setCategory(Notification.CATEGORY_EVENT)

        val notification = builder.build()
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(requestCode, notification)
        return true
    }

    private fun captureLocalNotificationTap(intent: Intent?, notifyDart: Boolean) {
        if (intent?.getBooleanExtra("adminCuuHoLocalNotification", false) != true) {
            return
        }

        val payload = mutableMapOf<String, String>()
        for (key in listOf("maThongBao", "maAdmin", "maYeuCau", "loai", "maSuKien")) {
            val value = intent.getStringExtra(key)
            if (!value.isNullOrBlank()) payload[key] = value
        }

        if (payload["maThongBao"].isNullOrBlank() ||
            payload["maAdmin"].isNullOrBlank() ||
            payload["maYeuCau"].isNullOrBlank()
        ) {
            return
        }

        pendingLocalNotificationTap = payload
        if (notifyDart) {
            localNotificationChannel?.invokeMethod("notificationTap", payload)
        }
    }
}
