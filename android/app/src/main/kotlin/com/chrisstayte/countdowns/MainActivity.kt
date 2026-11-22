package com.chrisstayte.countdowns

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import com.chrisstayte.countdowns.widget.WidgetBridge
import com.chrisstayte.countdowns.widget.WidgetLinks
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        restoreWidgetLink(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        restoreWidgetLink(intent)
        super.onNewIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        WidgetBridge.register(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }

    /**
     * Glance replaces a widget intent's data with its own glance-action URI,
     * so widgets also carry the countdowns://event/<id> link in an extra.
     * Put it back as the data before Flutter reads it as the route (initial
     * route on a cold start, pushed route when already running).
     */
    private fun restoreWidgetLink(intent: Intent?) {
        val link = intent?.getStringExtra(WidgetLinks.EXTRA) ?: return
        intent.action = Intent.ACTION_VIEW
        intent.data = Uri.parse(link)
    }
}
