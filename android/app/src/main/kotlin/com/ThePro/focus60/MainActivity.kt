package com.ThePro.focus60 // garde le package de TON MainActivity existant

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var previousFilter: Int? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "focus60/dnd").setMethodCallHandler { call, result ->
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            when (call.method) {
                "hasAccess" -> result.success(nm.isNotificationPolicyAccessGranted)
                "openSettings" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
                    result.success(true)
                }
                "enable" -> {
                    if (!nm.isNotificationPolicyAccessGranted) {
                        result.success(false)
                    } else {
                        // On mémorise le réglage de l'utilisateur pour le restaurer ensuite.
                        if (previousFilter == null) previousFilter = nm.currentInterruptionFilter
                        nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALARMS)
                        result.success(true)
                    }
                }
                "disable" -> {
                    if (!nm.isNotificationPolicyAccessGranted) {
                        result.success(false)
                    } else {
                        nm.setInterruptionFilter(
                            previousFilter ?: NotificationManager.INTERRUPTION_FILTER_ALL
                        )
                        previousFilter = null
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "focus60/lock").setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> result.success(runCatching { startLockTask() }.isSuccess)
                "stop" -> result.success(runCatching { stopLockTask() }.isSuccess)
                else -> result.notImplemented()
            }
        }
    }
}