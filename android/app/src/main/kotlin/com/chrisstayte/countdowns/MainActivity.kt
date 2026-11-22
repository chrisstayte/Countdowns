package com.chrisstayte.countdowns

import com.chrisstayte.countdowns.widget.WidgetBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        WidgetBridge.register(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }
}
