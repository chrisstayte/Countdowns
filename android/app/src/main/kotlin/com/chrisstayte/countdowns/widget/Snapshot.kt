package com.chrisstayte.countdowns.widget

import android.content.Context
import org.json.JSONObject
import java.io.File
import java.time.Duration
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import java.util.Locale

/** One countdown as the Flutter app wrote it to `widget/snapshot.json`. */
data class WidgetEvent(
    val id: Int,
    /** countdowns://event/<id>: what a tap on this countdown opens. */
    val link: String?,
    val title: String,
    /** Seconds since the epoch of the next occurrence when the app wrote it. */
    val target: Long,
    val allDay: Boolean,
    val yearly: Boolean,
    val unit: String,
    val font: String,
    val text: Int,
    val colors: List<Int>,
    val direction: String,
    val icon: String?,
    val photo: String?,
    val photoWide: String?,
    /** The full-screen crop, for the large widget's single-countdown hero. */
    val photoFull: String?,
    val darken: Double,
    val createdAt: Long,
) {
    val hasPhoto get() = photo != null
}

/** Reads the snapshot the Flutter app writes into the app's files dir. */
object SnapshotStore {
    /** The only version this code understands; newer files are ignored. */
    const val VERSION = 1

    fun folder(context: Context) = File(context.filesDir, "widget")

    fun load(context: Context): List<WidgetEvent> {
        val file = File(folder(context), "snapshot.json")
        if (!file.exists()) return emptyList()
        return try {
            parse(file.readText())
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun file(context: Context, relative: String?): File? =
        relative?.let { File(folder(context), it) }?.takeIf { it.exists() }

    fun parse(json: String): List<WidgetEvent> {
        val root = JSONObject(json)
        if (root.optInt("version") != VERSION) return emptyList()
        val list = root.getJSONArray("events")
        return (0 until list.length()).map { i ->
            val e = list.getJSONObject(i)
            val colors = e.getJSONArray("colors")
            WidgetEvent(
                id = e.getInt("id"),
                link = e.optStringOrNull("link"),
                title = e.getString("title"),
                target = e.getLong("target"),
                allDay = e.optBoolean("allDay"),
                yearly = e.optBoolean("yearly"),
                unit = e.optString("unit", "days"),
                font = e.optString("font", "Default"),
                text = parseHex(e.optString("text", "#2E2A3A")),
                colors = (0 until colors.length()).map { parseHex(colors.getString(it)) },
                direction = e.optString("direction", "diagonalDown"),
                icon = e.optStringOrNull("icon"),
                photo = e.optStringOrNull("photo"),
                photoWide = e.optStringOrNull("photoWide"),
                photoFull = e.optStringOrNull("photoFull"),
                darken = e.optDouble("darken", 0.35),
                createdAt = e.optLong("createdAt", e.getLong("target")),
            )
        }
    }

    private fun JSONObject.optStringOrNull(key: String): String? =
        if (isNull(key)) null else optString(key).ifEmpty { null }
}

fun parseHex(hex: String): Int =
    (0xFF000000 or hex.trimStart('#').toLong(16)).toInt()

// MARK: Counting (mirrors lib/utilities/count_format.dart and the iOS widget)

enum class CountMode { Days, Sleeps }

data class Count(val big: String, val unit: String)

class Counter(private val zone: ZoneId = ZoneId.systemDefault()) {

    private fun at(seconds: Long) = Instant.ofEpochSecond(seconds).atZone(zone)

    /** The next time it happens on or after [now] (yearly events roll over). */
    fun occurrence(e: WidgetEvent, now: ZonedDateTime): ZonedDateTime {
        var date = at(e.target)
        if (!e.yearly) return date
        var guard = 0
        while (passed(e, date, now) && guard++ < 400) date = date.plusYears(1)
        return date
    }

    private fun passed(e: WidgetEvent, date: ZonedDateTime, now: ZonedDateTime): Boolean =
        if (e.allDay) now.toLocalDate() > date.withZoneSameInstant(zone).toLocalDate()
        else !date.isAfter(now)

    fun isToday(e: WidgetEvent, now: ZonedDateTime): Boolean =
        e.allDay && occurrence(e, now).toLocalDate() == now.toLocalDate()

    fun isDone(e: WidgetEvent, now: ZonedDateTime): Boolean =
        !e.yearly && passed(e, occurrence(e, now), now)

    fun sleeps(e: WidgetEvent, now: ZonedDateTime): Int {
        val from: LocalDate = now.toLocalDate()
        val to: LocalDate = occurrence(e, now).toLocalDate()
        return maxOf(0, ChronoUnit.DAYS.between(from, to).toInt())
    }

    fun count(e: WidgetEvent, now: ZonedDateTime, mode: CountMode): Count {
        if (isDone(e, now)) return Count("0", "days")
        if (isToday(e, now)) return Count("Today", "")
        if (mode == CountMode.Sleeps) {
            val s = sleeps(e, now)
            return Count("$s", if (s == 1) "sleep" else "sleeps")
        }
        val left = Duration.between(now, occurrence(e, now)).seconds
        if (left < 86_400) {
            if (left >= 3_600) {
                val h = left / 3_600
                return Count("$h", if (h == 1L) "hour" else "hours")
            }
            return Count("${maxOf(0, left / 60)}", "min")
        }
        val d = left / 86_400
        return Count("$d", if (d == 1L) "day" else "days")
    }

    /** Share of the wait already behind you, 0 to 1. */
    fun progress(e: WidgetEvent, now: ZonedDateTime): Double {
        val start = e.createdAt
        val end = occurrence(e, now).toEpochSecond()
        val total = (end - start).toDouble()
        if (total <= 0) return 1.0
        return ((now.toEpochSecond() - start) / total).coerceIn(0.0, 1.0)
    }

    fun shortDate(e: WidgetEvent, now: ZonedDateTime): String {
        val date = occurrence(e, now)
        val pattern = if (date.year == now.year) "EEE, MMM d" else "EEE, MMM d, yyyy"
        return date.format(DateTimeFormatter.ofPattern(pattern, Locale.US))
    }

    /** Upcoming events, soonest first, with the pinned one (if any) leading. */
    fun arrange(events: List<WidgetEvent>, now: ZonedDateTime, pinnedId: Int?): Arranged {
        val upcoming = events.filter { !isDone(it, now) }.sortedBy { occurrence(it, now) }
        val chosen = pinnedId?.let { id -> upcoming.firstOrNull { it.id == id } }
            ?: return Arranged(upcoming, pinned = false)
        return Arranged(listOf(chosen) + upcoming.filter { it.id != chosen.id }, pinned = true)
    }

    /** When the numbers next need redrawing: the next local midnight, or
     *  sooner while something shown is counting hours or minutes. */
    fun nextRefresh(events: List<WidgetEvent>, now: ZonedDateTime): ZonedDateTime {
        val midnight = now.toLocalDate().plusDays(1).atStartOfDay(zone)
        val soon = events.any { e ->
            !isDone(e, now) &&
                Duration.between(now, occurrence(e, now)).seconds < 86_400
        }
        if (!soon) return midnight
        val quarter = now.plusMinutes(15).truncatedTo(ChronoUnit.MINUTES)
        return if (quarter.isBefore(midnight)) quarter else midnight
    }
}

data class Arranged(val events: List<WidgetEvent>, val pinned: Boolean) {
    val lead get() = events.firstOrNull()
}

/** "event" follows the countdown's own unit; "days"/"sleeps" force one. */
fun modeFor(countIn: String, e: WidgetEvent): CountMode = when (countIn) {
    "days" -> CountMode.Days
    "sleeps" -> CountMode.Sleeps
    else -> if (e.unit == "sleeps") CountMode.Sleeps else CountMode.Days
}

// MARK: Large widget layout

enum class LargeLayout { Empty, Hero, List }

/** The large widget's "Layout" setting. */
object LayoutChoice {
    /** Up next as a list; a hero on its own when only one is active. */
    const val LIST = "list"

    /** Always one big countdown: the pinned one, else the next. */
    const val SINGLE = "single"
}

/** No countdowns: the empty state. "One countdown", or only one active:
 *  it fills the widget as a hero. Otherwise a lead card with the rest
 *  listed under it. Only the large size reads [choice]. */
fun largeLayout(active: Int, choice: String = LayoutChoice.LIST): LargeLayout = when {
    active <= 0 -> LargeLayout.Empty
    choice == LayoutChoice.SINGLE || active == 1 -> LargeLayout.Hero
    else -> LargeLayout.List
}

/** The list layout inside an [height]-dp widget (18dp padding): up to four
 *  38dp rows 10dp apart, and the lead card takes every dp that is left, so
 *  there is never an empty band of Paper at the bottom. */
data class ListPlan(val rows: Int, val leadHeight: Float)

const val LIST_PADDING = 18f
const val ROW_HEIGHT = 38f
const val ROW_GAP = 10f
const val MIN_LEAD = 78f

fun planList(active: Int, height: Float): ListPlan {
    val inner = height - LIST_PADDING * 2
    var rows = (active - 1).coerceIn(0, 4)
    while (rows > 0 && inner - rows * (ROW_HEIGHT + ROW_GAP) < MIN_LEAD) rows--
    return ListPlan(rows, inner - rows * (ROW_HEIGHT + ROW_GAP))
}
