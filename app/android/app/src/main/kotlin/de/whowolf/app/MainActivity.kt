package de.whowolf.app

import android.app.NotificationManager
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    /** The "do not disturb" state before the game's quiet mode, to restore. */
    private var before: Int? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Quiet mode at the table (task 023 F1): "do not disturb" while the
        // game runs, only with the player's permission, restored afterwards.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "whowolf/quiet")
            .setMethodCallHandler { call, result ->
                val manager = getSystemService(NotificationManager::class.java)
                when (call.method) {
                    "allowed" -> result.success(manager.isNotificationPolicyAccessGranted)
                    "ask" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
                        result.success(null)
                    }
                    "set" -> {
                        if (!manager.isNotificationPolicyAccessGranted) {
                            result.success(false)
                        } else {
                            if (call.arguments == true) {
                                if (before == null) before = manager.currentInterruptionFilter
                                manager.setInterruptionFilter(
                                    NotificationManager.INTERRUPTION_FILTER_PRIORITY,
                                )
                            } else {
                                restore(manager)
                            }
                            result.success(true)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun restore(manager: NotificationManager) {
        val was = before ?: return
        if (manager.isNotificationPolicyAccessGranted) manager.setInterruptionFilter(was)
        before = null
    }

    override fun onDestroy() {
        restore(getSystemService(NotificationManager::class.java))
        super.onDestroy()
    }
}
