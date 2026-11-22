package com.chrisstayte.countdowns.widget

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.style.ForegroundColorSpan
import android.text.style.RelativeSizeSpan
import android.view.View
import android.view.WindowInsetsController
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.ScrollView
import android.widget.TextView
import androidx.datastore.preferences.core.Preferences
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.state.getAppWidgetState
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.state.PreferencesGlanceStateDefinition
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import java.time.ZonedDateTime

/**
 * Widget settings, like the iOS widget's: follow Up next or pin one
 * countdown, and count in days or sleeps (or as set in the app). Shown
 * when the widget is placed (optional) and from "Reconfigure" later.
 */
class ConfigureActivity : Activity() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var widgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    private companion object {
        const val HIGHLIGHTER = 0xFFFFE36E.toInt()
        const val RULE = 0xFFE6E1D3.toInt()
        const val UP_NEXT = -1
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)
        widgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }
        scope.launch {
            val glanceId = GlanceAppWidgetManager(this@ConfigureActivity).getGlanceIdBy(widgetId)
            val prefs: Preferences =
                getAppWidgetState(this@ConfigureActivity, PreferencesGlanceStateDefinition, glanceId)
            build(
                prefs[WidgetKeys.countdown] ?: UP_NEXT,
                prefs[WidgetKeys.countIn] ?: "event",
                prefs[WidgetKeys.layout] ?: LayoutChoice.LIST,
            )
        }
    }

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }

    private fun dp(v: Float) =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v, resources.displayMetrics).toInt()

    private fun build(pinned: Int, countIn: String, layoutChoice: String) {
        val now = ZonedDateTime.now()
        val counter = Counter()
        val events = counter.arrange(SnapshotStore.load(this), now, null).events

        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(20f), dp(20f), dp(20f), dp(28f))
        }
        column.addView(text("Countdown widget", 26f, Palette.INK, Fonts.numeral(this, 26f)))
        column.addView(
            text("Follow Up next or pin one countdown.", 15f, Palette.PENCIL, Fonts.ui(this)),
        )

        column.addView(label("SHOW"))
        // RadioGroup ids must be real view ids, so map them to values.
        val showValues = HashMap<Int, Int>()
        val show = RadioGroup(this)
        fun showOption(value: Int, title: String, detail: String?) {
            val id = View.generateViewId()
            showValues[id] = value
            show.addView(option(id, title, detail))
            if (value == pinned) show.check(id)
        }
        showOption(UP_NEXT, "Up next", "The soonest countdown, always")
        for (e in events) showOption(e.id, e.title, counter.shortDate(e, now))
        if (show.checkedRadioButtonId == View.NO_ID) show.check(show.getChildAt(0).id)
        column.addView(show)
        if (events.isEmpty()) {
            column.addView(text("Add countdowns in the app to pin one.", 13f, Palette.PENCIL, Fonts.ui(this)))
        }

        column.addView(label("COUNT IN"))
        val countValues = HashMap<Int, String>()
        val count = RadioGroup(this)
        for ((value, name) in listOf("event" to "As set in the app", "days" to "Days", "sleeps" to "Sleeps")) {
            val id = View.generateViewId()
            countValues[id] = value
            count.addView(option(id, name, null))
            if (value == countIn) count.check(id)
        }
        if (count.checkedRadioButtonId == View.NO_ID) count.check(count.getChildAt(0).id)
        column.addView(count)

        // Only the 4×4 size reads this; smaller sizes ignore it.
        column.addView(label("LAYOUT · LARGE SIZE"))
        val layoutValues = HashMap<Int, String>()
        val layouts = RadioGroup(this)
        for ((value, name, detail) in listOf(
            Triple(LayoutChoice.LIST, "List", "Up next, or one big countdown when only one is coming up"),
            Triple(LayoutChoice.SINGLE, "One countdown", "Always one big countdown: the pinned one, or the next"),
        )) {
            val id = View.generateViewId()
            layoutValues[id] = value
            layouts.addView(option(id, name, detail))
            if (value == layoutChoice) layouts.check(id)
        }
        if (layouts.checkedRadioButtonId == View.NO_ID) layouts.check(layouts.getChildAt(0).id)
        column.addView(layouts)

        column.addView(save {
            val choice = showValues[show.checkedRadioButtonId] ?: UP_NEXT
            val unit = countValues[count.checkedRadioButtonId] ?: "event"
            val layout = layoutValues[layouts.checkedRadioButtonId] ?: LayoutChoice.LIST
            scope.launch { apply(if (choice == UP_NEXT) null else choice, unit, layout) }
        })

        val scroll = ScrollView(this).apply {
            setBackgroundColor(Palette.PAPER)
            addView(column)
            // Stay clear of the status and navigation bars (edge to edge).
            setOnApplyWindowInsetsListener { v, insets ->
                @Suppress("DEPRECATION")
                v.setPadding(0, insets.systemWindowInsetTop, 0, insets.systemWindowInsetBottom)
                insets
            }
        }
        setContentView(scroll)
        // Dark status and navigation bar icons on Paper.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val light = WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS or
                WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS
            window.decorView.windowInsetsController?.setSystemBarsAppearance(light, light)
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
        }
    }

    private suspend fun apply(pinned: Int?, countIn: String, layout: String) {
        val glanceId = GlanceAppWidgetManager(this).getGlanceIdBy(widgetId)
        updateAppWidgetState(this, glanceId) { prefs ->
            if (pinned == null) prefs.remove(WidgetKeys.countdown)
            else prefs[WidgetKeys.countdown] = pinned
            prefs[WidgetKeys.countIn] = countIn
            prefs[WidgetKeys.layout] = layout
            prefs[WidgetKeys.stamp] = System.currentTimeMillis()
        }
        CountdownWidget().update(this, glanceId)
        Widgets.refreshSoon(this)
        setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId))
        finish()
    }

    // MARK: Pieces

    private fun text(value: String, size: Float, color: Int, face: android.graphics.Typeface) =
        TextView(this).apply {
            text = value
            textSize = size
            setTextColor(color)
            typeface = face
            setPadding(0, 0, 0, dp(4f))
        }

    private fun label(value: String) =
        text(value, 12f, Palette.PENCIL, Fonts.ui(this, bold = true)).apply {
            letterSpacing = 0.08f
            setPadding(dp(4f), dp(22f), 0, dp(8f))
        }

    private fun pill(fill: Int, stroke: Int) = GradientDrawable().apply {
        cornerRadius = dp(16f).toFloat()
        setColor(fill)
        setStroke(dp(1.5f), stroke)
    }

    /** A choice row: white with a Rule outline, Highlighter when picked. */
    private fun option(id: Int, title: String, detail: String?) = RadioButton(this).apply {
        this.id = id
        buttonDrawable = null
        textSize = 16f
        typeface = Fonts.ui(this@ConfigureActivity)
        setTextColor(Palette.INK)
        minHeight = dp(52f)
        gravity = Gravity.CENTER_VERTICAL
        setPadding(dp(16f), dp(10f), dp(16f), dp(10f))
        layoutParams = RadioGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        ).apply { bottomMargin = dp(8f) }
        val update = { checked: Boolean ->
            background = if (checked) pill(HIGHLIGHTER, Palette.INK) else pill(Color.WHITE, RULE)
            // A tick too, so the choice never rests on colour alone.
            text = rowText((if (checked) "✓  " else "") + title, detail, checked)
        }
        update(false)
        setOnCheckedChangeListener { _, checked -> update(checked) }
    }

    /** Title in Ink, then the date smaller in Pencil (Ink on Highlighter,
     *  where Pencil would fall under AA contrast). */
    private fun rowText(title: String, detail: String?, checked: Boolean): CharSequence {
        if (detail == null) return title
        return SpannableStringBuilder(title).append('\n').apply {
            val start = length
            append(detail)
            setSpan(ForegroundColorSpan(if (checked) Palette.INK else Palette.PENCIL), start, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            setSpan(RelativeSizeSpan(0.85f), start, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }
    }

    /** Save: Highlighter fill, Ink text, 1.5dp Ink outline. */
    private fun save(onTap: () -> Unit) = Button(this).apply {
        text = "Save"
        isAllCaps = false
        textSize = 17f
        typeface = Fonts.ui(this@ConfigureActivity, bold = true)
        setTextColor(Palette.INK)
        background = GradientDrawable().apply {
            cornerRadius = dp(26f).toFloat()
            setColor(HIGHLIGHTER)
            setStroke(dp(1.5f), Palette.INK)
        }
        backgroundTintList = null as ColorStateList?
        stateListAnimator = null
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            dp(52f),
        ).apply { topMargin = dp(24f) }
        setOnClickListener { onTap() }
        importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_YES
    }
}
