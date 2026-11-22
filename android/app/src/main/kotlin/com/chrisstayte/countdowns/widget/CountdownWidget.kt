package com.chrisstayte.countdowns.widget

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.SizeMode
import androidx.glance.action.Action
import androidx.glance.action.actionStartActivity
import androidx.glance.appwidget.action.actionStartActivity as startActivityWith
import androidx.glance.appwidget.appWidgetBackground
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import androidx.work.CoroutineWorker
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.chrisstayte.countdowns.MainActivity
import java.time.Duration
import java.time.ZonedDateTime
import java.util.concurrent.TimeUnit

/** Per-widget settings, kept in Glance's own preferences state. */
object WidgetKeys {
    /** A pinned countdown's id; missing means "Up next". */
    val countdown = intPreferencesKey("countdown")

    /** "event" (as set in the app), "days" or "sleeps". */
    val countIn = stringPreferencesKey("countIn")

    /** Bumped on every refresh so Glance recomposes with fresh numbers. */
    val stamp = longPreferencesKey("stamp")
}

/**
 * The home screen widget. One widget that lays itself out for its size,
 * like the iOS one: 2×2 one countdown, 4×2 one countdown with progress,
 * 4×4 the Up next list on Paper.
 */
class CountdownWidget : GlanceAppWidget() {
    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { Content() }
    }

    @Composable
    private fun Content() {
        val context = LocalContext.current
        val prefs = currentState<Preferences>()
        prefs[WidgetKeys.stamp] // Read so a refresh recomposes.
        val countIn = prefs[WidgetKeys.countIn] ?: "event"
        val size = LocalSize.current
        val now = ZonedDateTime.now()
        val counter = Counter()
        val arranged = counter.arrange(SnapshotStore.load(context), now, prefs[WidgetKeys.countdown])
        val art = Art(context, counter, now, countIn)
        val radius = widgetRadius(context)
        val w = size.width.value
        val h = size.height.value
        val lead = arranged.lead

        val frame = GlanceModifier
            .fillMaxSize()
            .appWidgetBackground()
            .cornerRadius(radius.dp)

        when {
            lead == null -> Box(
                frame.background(Color(Palette.PAPER)).padding(12.dp)
                    .clickable(openCountdown(context, null)),
                contentAlignment = Alignment.Center,
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        "No countdowns yet",
                        style = TextStyle(
                            color = ColorProvider(Color(Palette.INK)),
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold,
                            textAlign = TextAlign.Center,
                        ),
                    )
                    Text(
                        "Add one in the app.",
                        style = TextStyle(
                            color = ColorProvider(Color(Palette.PENCIL)),
                            fontSize = 12.sp,
                            textAlign = TextAlign.Center,
                        ),
                    )
                }
            }

            // Android cells run taller than iOS ones: a 4×2 is about 210dp, so
            // the large layouts start at three rows, like the iOS large widget.
            w >= 200 && h >= 280 && largeLayout(arranged.events.size) == LargeLayout.Hero -> Image(
                ImageProvider(art.hero(lead, arranged.pinned, w, h, radius)),
                contentDescription = art.describe(lead),
                modifier = frame.clickable(openCountdown(context, lead)),
                contentScale = ContentScale.FillBounds,
            )

            w >= 200 && h >= 280 -> Column(
                frame.background(Color(Palette.PAPER)).padding(LIST_PADDING.dp)
                    .clickable(openCountdown(context, null)),
            ) {
                val inner = w - LIST_PADDING * 2
                val plan = planList(arranged.events.size, h)
                // The lead card takes the room the rows leave, so short
                // lists grow the card instead of leaving empty Paper.
                val leadArt = if (plan.leadHeight >= 130f) {
                    art.medium(lead, arranged.pinned, inner, plan.leadHeight, 18f)
                } else {
                    art.lead(lead, arranged.pinned, inner, plan.leadHeight)
                }
                Image(
                    ImageProvider(leadArt),
                    contentDescription = art.describe(lead),
                    modifier = GlanceModifier.fillMaxWidth().height(plan.leadHeight.dp)
                        .clickable(openCountdown(context, lead)),
                    contentScale = ContentScale.FillBounds,
                )
                for (e in arranged.events.drop(1).take(plan.rows)) {
                    Spacer(GlanceModifier.height(ROW_GAP.dp))
                    Image(
                        ImageProvider(art.row(e, inner)),
                        contentDescription = art.describe(e),
                        modifier = GlanceModifier.fillMaxWidth().height(ROW_HEIGHT.dp)
                            .clickable(openCountdown(context, e)),
                        contentScale = ContentScale.FillBounds,
                    )
                }
            }

            w >= 200 -> Image(
                ImageProvider(art.medium(lead, arranged.pinned, w, h, radius)),
                contentDescription = art.describe(lead),
                modifier = frame.clickable(openCountdown(context, lead)),
                contentScale = ContentScale.FillBounds,
            )

            else -> Image(
                ImageProvider(art.small(lead, w, h, radius)),
                contentDescription = art.describe(lead),
                modifier = frame.clickable(openCountdown(context, lead)),
                contentScale = ContentScale.FillBounds,
            )
        }
    }
}

/**
 * Opens the app on a countdown's detail (countdowns://event/<id>, routed
 * by GoRouter; a deleted one lands on Home), or just opens the app.
 * Each link is its own data URI, so every row gets its own PendingIntent.
 */
fun openCountdown(context: Context, e: WidgetEvent?): Action {
    val link = e?.link ?: return actionStartActivity<MainActivity>()
    return startActivityWith(
        Intent(Intent.ACTION_VIEW, Uri.parse(link), context, MainActivity::class.java)
            .putExtra(WidgetLinks.EXTRA, link),
    )
}

object WidgetLinks {
    /** Glance overwrites the intent's data, so the link rides along here
     *  too; MainActivity restores it (see restoreWidgetLink). */
    const val EXTRA = "com.chrisstayte.countdowns.WIDGET_LINK"
}

/** The launcher's widget corner radius in dp (Android 12+), else 20. */
fun widgetRadius(context: Context): Float {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        val res = context.resources
        return res.getDimension(android.R.dimen.system_app_widget_background_radius) /
            res.displayMetrics.density
    }
    return 20f
}

class CountdownWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = CountdownWidget()

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        Widgets.refreshSoon(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        Widgets.cancel(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            // The day may have changed under us: redraw and reschedule.
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_LOCALE_CHANGED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            -> Widgets.refreshSoon(context)
        }
    }
}

/** Redraws every widget and books the next redraw. */
class RefreshWorker(context: Context, params: WorkerParameters) :
    CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        Widgets.refresh(applicationContext)
        return Result.success()
    }
}

object Widgets {
    private const val NOW = "countdowns-widget-now"
    private const val NEXT = "countdowns-widget-next"

    /** Asks for a redraw as soon as WorkManager can run it. */
    fun refreshSoon(context: Context) {
        WorkManager.getInstance(context).enqueueUniqueWork(
            NOW,
            ExistingWorkPolicy.REPLACE,
            OneTimeWorkRequestBuilder<RefreshWorker>().build(),
        )
    }

    suspend fun refresh(context: Context) {
        val ids = GlanceAppWidgetManager(context).getGlanceIds(CountdownWidget::class.java)
        for (id in ids) {
            updateAppWidgetState(context, id) { it[WidgetKeys.stamp] = System.currentTimeMillis() }
            CountdownWidget().update(context, id)
        }
        if (ids.isEmpty()) cancel(context) else scheduleNext(context)
    }

    /** Next local midnight, or every 15 minutes while a count is in hours. */
    private fun scheduleNext(context: Context) {
        val now = ZonedDateTime.now()
        val next = Counter().nextRefresh(SnapshotStore.load(context), now)
        val delay = Duration.between(now, next).toMillis().coerceAtLeast(0) + 2_000
        WorkManager.getInstance(context).enqueueUniqueWork(
            NEXT,
            ExistingWorkPolicy.REPLACE,
            OneTimeWorkRequestBuilder<RefreshWorker>()
                .setInitialDelay(delay, TimeUnit.MILLISECONDS)
                .build(),
        )
    }

    fun cancel(context: Context) {
        WorkManager.getInstance(context).cancelUniqueWork(NEXT)
    }
}
