package de.whowolf.app

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    /** The "do not disturb" state before the game's quiet mode, to restore. */
    private var before: Int? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        watchPowerSaver(flutterEngine)
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

    /** Tells Flutter whether the battery saver is on, now and on every change. */
    private var powerReceiver: BroadcastReceiver? = null

    private fun watchPowerSaver(engine: FlutterEngine) {
        EventChannel(engine.dartExecutor.binaryMessenger, "whowolf/power")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    val power = getSystemService(PowerManager::class.java)
                    events.success(power.isPowerSaveMode)
                    val receiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context, intent: Intent) {
                            events.success(power.isPowerSaveMode)
                        }
                    }
                    registerReceiver(
                        receiver,
                        IntentFilter(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED),
                    )
                    powerReceiver = receiver
                }

                override fun onCancel(arguments: Any?) {
                    powerReceiver?.let { unregisterReceiver(it) }
                    powerReceiver = null
                }
            })
    }

    private fun restore(manager: NotificationManager) {
        val was = before ?: return
        if (manager.isNotificationPolicyAccessGranted) manager.setInterruptionFilter(was)
        before = null
    }

    override fun onDestroy() {
        powerReceiver?.let { unregisterReceiver(it) }
        powerReceiver = null
        restore(getSystemService(NotificationManager::class.java))
        super.onDestroy()
    }
}
