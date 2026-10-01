package com.example.destination_alarm

import android.content.Intent
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "destination_alarm/alarm"
        private const val RING_ACTION =
            "com.gdelataillade.alarm.action.RING"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Allow the alarm screen to appear over the lock screen.
        setShowWhenLocked(true)
        setTurnScreenOn(true)
    }

    override fun configureFlutterEngine(
        @NonNull flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "getAlarmIntent" -> {
                    result.success(getAlarmData(intent))
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)

        setIntent(intent)

        // Flutter will check the current intent again.
    }

    private fun getAlarmData(intent: Intent?): Map<String, Any?>? {

        if (intent == null) {
            return null
        }

        if (intent.action != RING_ACTION) {
            return null
        }

        val alarmId =
            intent.getIntExtra("alarmId", -1)

        if (alarmId == -1) {
            return null
        }

        return mapOf(
            "alarmId" to alarmId,
            "title" to (
                intent.getStringExtra("alarmTitle")
                    ?: "Destination Reached!"
            ),
            "body" to (
                intent.getStringExtra("alarmBody")
                    ?: "You are inside your destination radius."
            ),
            "stopLabel" to (
                intent.getStringExtra("alarmStopLabel")
                    ?: "STOP ALARM"
            )
        )
    }
}