package com.chrisstayte.countdowns.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.ZoneOffset
import java.time.ZonedDateTime

/**
 * The fixture is the same file test/widget_snapshot_test.dart checks the
 * Dart writer against, so the two sides agree on the format.
 */
class CounterTest {
    private val zone = ZoneOffset.UTC
    private val counter = Counter(zone)
    private val events = SnapshotStore.parse(
        javaClass.classLoader!!.getResource("snapshot.json")!!.readText(),
    )
    private val thanksgiving = events.first { it.id == 3 }
    private val birthday = events.first { it.id == 7 }
    private val flight = events.first { it.id == 9 }

    private fun at(y: Int, m: Int, d: Int, h: Int = 12, min: Int = 0) =
        ZonedDateTime.of(y, m, d, h, min, 0, 0, zone)

    @Test
    fun parsesTheSharedSnapshot() {
        assertEquals(3, events.size)
        assertEquals("Mia's birthday", birthday.title)
        assertTrue(birthday.yearly)
        assertEquals(listOf(0xFFFF5C7A.toInt(), 0xFFFFB86B.toInt()), birthday.colors)
        assertEquals("radial", birthday.direction)
        assertEquals("photos/7-wide-abc.png", birthday.photoWide)
        assertEquals(null, thanksgiving.photo)
        assertEquals(0xFF1C1633.toInt(), thanksgiving.text)
    }

    @Test
    fun ignoresNewerSnapshotVersions() {
        assertTrue(SnapshotStore.parse("""{"version": 2, "events": []}""").isEmpty())
    }

    @Test
    fun countsDaysSleepsHoursAndMinutes() {
        val now = at(2026, 11, 21)
        assertEquals(Count("4", "days"), counter.count(thanksgiving, now, CountMode.Days))
        assertEquals(Count("5", "sleeps"), counter.count(thanksgiving, now, CountMode.Sleeps))
        assertEquals(Count("74", "sleeps"), counter.count(birthday, now, CountMode.Sleeps))
        assertEquals(Count("6", "hours"), counter.count(flight, now, CountMode.Days))
        assertEquals(Count("30", "min"), counter.count(flight, at(2026, 11, 21, 17, 30), CountMode.Days))
        assertEquals(Count("1", "sleep"), counter.count(thanksgiving, at(2026, 11, 25), CountMode.Sleeps))
    }

    @Test
    fun allDayIsTodayThenDone() {
        assertEquals(Count("Today", ""), counter.count(thanksgiving, at(2026, 11, 26, 10), CountMode.Days))
        assertFalse(counter.isDone(thanksgiving, at(2026, 11, 26, 23, 59)))
        assertTrue(counter.isDone(thanksgiving, at(2026, 11, 27, 0, 1)))
        assertEquals(Count("0", "days"), counter.count(thanksgiving, at(2026, 11, 28), CountMode.Days))
    }

    @Test
    fun yearlyRollsOverWithoutTheApp() {
        val later = at(2027, 2, 4)
        assertEquals(at(2028, 2, 3, 0), counter.occurrence(birthday, later))
        assertFalse(counter.isDone(birthday, later))
        assertEquals("Thu, Feb 3", counter.shortDate(birthday, at(2028, 1, 1)))
        assertEquals("Wed, Feb 3, 2027", counter.shortDate(birthday, at(2026, 11, 21)))
    }

    @Test
    fun arrangesUpNextOrAPinnedCountdown() {
        val now = at(2026, 11, 21)
        val upNext = counter.arrange(events, now, null)
        assertEquals(listOf(9, 3, 7), upNext.events.map { it.id })
        assertFalse(upNext.pinned)
        val pinned = counter.arrange(events, now, 7)
        assertEquals(listOf(7, 9, 3), pinned.events.map { it.id })
        assertTrue(pinned.pinned)
        // A pinned countdown that is gone falls back to Up next.
        assertFalse(counter.arrange(events, now, 42).pinned)
        // Done ones drop out.
        assertEquals(listOf(7), counter.arrange(events, at(2026, 11, 28), null).events.map { it.id })
    }

    @Test
    fun followsTheAppsUnitUnlessForced() {
        assertEquals(CountMode.Sleeps, modeFor("event", birthday))
        assertEquals(CountMode.Days, modeFor("event", thanksgiving))
        assertEquals(CountMode.Days, modeFor("days", birthday))
        assertEquals(CountMode.Sleeps, modeFor("sleeps", thanksgiving))
    }

    @Test
    fun refreshesAtMidnightOrEveryQuarterHourWhenClose() {
        val now = at(2026, 11, 21, 12, 3)
        assertEquals(at(2026, 11, 21, 12, 18), counter.nextRefresh(events, now))
        assertEquals(at(2026, 11, 22, 0), counter.nextRefresh(listOf(birthday), now))
        // Never past midnight.
        assertEquals(at(2026, 11, 22, 0), counter.nextRefresh(events, at(2026, 11, 21, 23, 50)))
    }

    @Test
    fun progressRunsFromAddedToTarget() {
        assertEquals(0.0, counter.progress(thanksgiving, at(2026, 11, 21, 0)), 1e-9)
        assertEquals(0.5, counter.progress(thanksgiving, at(2026, 11, 23, 12)), 1e-9)
        assertEquals(1.0, counter.progress(thanksgiving, at(2026, 11, 26, 6)), 1e-9)
    }
}
