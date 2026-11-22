package com.chrisstayte.countdowns.widget

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * The same channel the iOS app uses. Flutter writes `widget/snapshot.json`
 * (plus icon and photo PNGs) under the folder we hand back, then asks us
 * to redraw. Our own code, no plugin.
 */
object WidgetBridge {
    fun register(context: Context, messenger: BinaryMessenger) {
        MethodChannel(messenger, "countdowns/widgets").setMethodCallHandler { call, result ->
            when (call.method) {
                "containerPath" -> result.success(context.filesDir.absolutePath)
                "reload" -> {
                    Widgets.refreshSoon(context)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
