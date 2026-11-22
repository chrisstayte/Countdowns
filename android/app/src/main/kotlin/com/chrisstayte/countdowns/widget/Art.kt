package com.chrisstayte.countdowns.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.SweepGradient
import android.graphics.Typeface
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.text.TextUtils
import java.time.ZonedDateTime
import kotlin.math.min

/** The app's "Highlighter" palette. */
object Palette {
    const val INK = 0xFF2E2A3A.toInt()
    const val PAPER = 0xFFFBF9F3.toInt()
    const val PENCIL = 0xFF6B6677.toInt()
    const val SCRIM = 0xFF120F22.toInt()
}

/**
 * The fonts the app bundles, read straight from the Flutter assets in the
 * APK. Glance text can only use system fonts, so the parts that carry the
 * app's look (titles in the countdown's font, the big numbers) are drawn
 * here and placed by Glance as images.
 */
object Fonts {
    private val cache = HashMap<String, Typeface>()

    private fun load(context: Context, file: String, fallback: Typeface): Typeface =
        synchronized(cache) {
            cache.getOrPut(file) {
                try {
                    Typeface.createFromAsset(context.assets, "flutter_assets/fonts/$file")
                } catch (_: Exception) {
                    fallback
                }
            }
        }

    fun numeral(context: Context, size: Float): Typeface = load(
        context,
        if (size >= 60) "BricolageDisplay-800.ttf" else "BricolageGrotesque-800.ttf",
        Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD),
    )

    fun ui(context: Context, bold: Boolean = false): Typeface = load(
        context,
        if (bold) "Inter-700.ttf" else "Inter-600.ttf",
        Typeface.create(Typeface.SANS_SERIF, if (bold) Typeface.BOLD else Typeface.NORMAL),
    )

    /** The countdown's own font, for titles. */
    fun event(context: Context, family: String): Typeface = load(
        context,
        when (family) {
            "Roboto" -> "Roboto-Bold.ttf"
            "GoodTimes" -> "GoodTimes-Regular.otf"
            "LibreBaskerville" -> "LibreBaskerville-Bold.ttf"
            "LuxuriousRoman" -> "LuxuriousRoman-Regular.ttf"
            "ComicNeue" -> "ComicNeue-Bold.ttf"
            "DiarioDeAndy" -> "DiarioDeAndy.otf"
            "Sunnyspells" -> "Sunnyspells.otf"
            "CarnivaleeFreakshow" -> "CarnivaleeFreakshow-Regular.ttf"
            "Starjedi" -> "Starjedi.ttf"
            "NewWaltDisney" -> "NewWaltDisney.ttf"
            else -> "BricolageGrotesque-700.ttf"
        },
        Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD),
    )
}

/**
 * Draws widget pieces in dp, at the screen's density. Everything is laid
 * out like the iOS widget (Views.swift) so the two read the same.
 */
class Art(
    private val context: Context,
    private val counter: Counter,
    private val now: ZonedDateTime,
    private val countIn: String,
) {
    private val density = context.resources.displayMetrics.density.coerceAtMost(3f)

    private fun canvasFor(w: Float, h: Float): Pair<Bitmap, Canvas> {
        val bitmap = Bitmap.createBitmap(
            (w * density).toInt().coerceAtLeast(1),
            (h * density).toInt().coerceAtLeast(1),
            Bitmap.Config.ARGB_8888,
        )
        val canvas = Canvas(bitmap)
        canvas.scale(density, density)
        return bitmap to canvas
    }

    // MARK: Backgrounds

    /** Colour, gradient (direction honoured), darkened photo or drawn art, clipped. */
    fun background(canvas: Canvas, e: WidgetEvent, rect: RectF, radius: Float, photoPath: String?) {
        canvas.save()
        val clip = Path().apply { addRoundRect(rect, radius, radius, Path.Direction.CW) }
        canvas.clipPath(clip)
        val photo = SnapshotStore.file(context, photoPath)
            ?.let { BitmapFactory.decodeFile(it.path) }
        if (photo != null) {
            // Cover, like scaledToFill.
            val scale = maxOf(rect.width() / photo.width, rect.height() / photo.height)
            val m = Matrix().apply {
                setScale(scale, scale)
                postTranslate(
                    rect.left + (rect.width() - photo.width * scale) / 2,
                    rect.top + (rect.height() - photo.height * scale) / 2,
                )
            }
            canvas.drawBitmap(photo, m, Paint(Paint.FILTER_BITMAP_FLAG))
            photo.recycle()
            // Drawn art comes as an image too, but with no scrim.
            if (e.scrim) {
                val top = alpha(Palette.SCRIM, e.darken)
                val bottom = alpha(Palette.SCRIM, min(1.0, e.darken + 0.15))
                canvas.drawRect(rect, Paint().apply {
                    shader = LinearGradient(
                        0f, rect.top, 0f, rect.bottom, top, bottom, Shader.TileMode.CLAMP,
                    )
                })
            }
        } else {
            canvas.drawRect(rect, Paint(Paint.ANTI_ALIAS_FLAG).apply { fill(e, rect) })
        }
        canvas.restore()
    }

    private fun Paint.fill(e: WidgetEvent, r: RectF) {
        val colors = e.colors.ifEmpty { listOf(Palette.INK) }
        if (colors.size < 2) {
            color = colors[0]
            return
        }
        val c = colors.toIntArray()
        shader = when (e.direction) {
            "radial" -> RadialGradient(
                r.centerX(), r.centerY(), 0.9f * min(r.width(), r.height()),
                c, null, Shader.TileMode.CLAMP,
            )
            "sweep" -> SweepGradient(r.centerX(), r.centerY(), c + c[0], null)
            else -> {
                val (x0, y0, x1, y1) = when (e.direction) {
                    "down" -> listOf(r.left, r.top, r.left, r.bottom)
                    "up" -> listOf(r.left, r.bottom, r.left, r.top)
                    "right" -> listOf(r.left, r.top, r.right, r.top)
                    "left" -> listOf(r.right, r.top, r.left, r.top)
                    "diagonalUp" -> listOf(r.left, r.bottom, r.right, r.top)
                    else -> listOf(r.left, r.top, r.right, r.bottom)
                }
                LinearGradient(x0, y0, x1, y1, c, null, Shader.TileMode.CLAMP)
            }
        }
    }

    private fun alpha(color: Int, a: Double) =
        Color.argb((a.coerceIn(0.0, 1.0) * 255).toInt(), Color.red(color), Color.green(color), Color.blue(color))

    // MARK: Text

    private fun paint(typeface: Typeface, size: Float, color: Int, shadow: Boolean) =
        TextPaint(Paint.ANTI_ALIAS_FLAG or Paint.SUBPIXEL_TEXT_FLAG).apply {
            this.typeface = typeface
            textSize = size
            this.color = color
            if (shadow) setShadowLayer(4f, 0f, 1f, alpha(Color.BLACK, 0.35))
        }

    private fun layout(text: String, p: TextPaint, width: Float, maxLines: Int): StaticLayout =
        StaticLayout.Builder.obtain(text, 0, text.length, p, width.toInt().coerceAtLeast(1))
            .setMaxLines(maxLines)
            .setEllipsize(TextUtils.TruncateAt.END)
            .setIncludePad(false)
            .setAlignment(Layout.Alignment.ALIGN_NORMAL)
            .build()

    /** Shrinks [p] until [text] fits [width] on one line, down to [minScale]. */
    private fun fit(text: String, p: TextPaint, width: Float, minScale: Float = 0.5f) {
        val start = p.textSize
        while (p.measureText(text) > width && p.textSize > start * minScale) p.textSize -= 1f
    }

    private fun drawIcon(canvas: Canvas, e: WidgetEvent, x: Float, y: Float, size: Float) {
        val file = SnapshotStore.file(context, e.icon) ?: return
        val icon = BitmapFactory.decodeFile(file.path) ?: return
        canvas.drawBitmap(icon, null, RectF(x, y, x + size, y + size), Paint(Paint.FILTER_BITMAP_FLAG))
        icon.recycle()
    }

    /** Big number with its unit beside it on the same baseline. Returns width. */
    private fun drawCount(
        canvas: Canvas, count: Count, x: Float, baseline: Float, maxWidth: Float,
        bigSize: Float, unitSize: Float, gap: Float, ink: Int, shadow: Boolean,
    ): Float {
        val big = paint(Fonts.numeral(context, bigSize), bigSize, ink, shadow)
        val unit = paint(Fonts.ui(context, bold = true), unitSize, ink, shadow)
        val unitWidth = if (count.unit.isEmpty()) 0f else unit.measureText(count.unit) + gap
        fit(count.big, big, maxWidth - unitWidth)
        canvas.drawText(count.big, x, baseline, big)
        val w = big.measureText(count.big)
        if (count.unit.isNotEmpty()) canvas.drawText(count.unit, x + w + gap, baseline, unit)
        return w + unitWidth
    }

    private fun eyebrow(pinned: Boolean) = if (pinned) "COUNTDOWN" else "UP NEXT"

    // MARK: Faces

    /** 2×2: title and icon on top, the count and date at the bottom. */
    fun small(e: WidgetEvent, w: Float, h: Float, radius: Float): Bitmap {
        val (bitmap, canvas) = canvasFor(w, h)
        background(canvas, e, RectF(0f, 0f, w, h), radius, e.photo)
        val pad = 16f
        val shadow = e.shadowed
        val count = counter.count(e, now, modeFor(countIn, e))

        drawIcon(canvas, e, w - pad - 20f, pad, 20f)
        val title = paint(Fonts.event(context, e.font), 17f, e.text, shadow)
        canvas.save()
        canvas.translate(pad, pad)
        layout(e.title, title, w - pad * 2 - 26f, 2).draw(canvas)
        canvas.restore()

        val date = paint(Fonts.ui(context), 12f, alpha(e.text, 0.85), shadow)
        val dateBaseline = h - pad - date.descent()
        canvas.drawText(counter.shortDate(e, now), pad, dateBaseline, date)
        drawCount(
            canvas, count, pad, dateBaseline - 18f, w - pad * 2,
            bigSize = 50f, unitSize = 14f, gap = 4f, ink = e.text, shadow = shadow,
        )
        return bitmap
    }

    /** 4×2: eyebrow and title, the count bottom left, date and progress right. */
    fun medium(e: WidgetEvent, pinned: Boolean, w: Float, h: Float, radius: Float): Bitmap {
        val (bitmap, canvas) = canvasFor(w, h)
        background(canvas, e, RectF(0f, 0f, w, h), radius, e.photoWide)
        val padX = 18f
        val padY = 16f
        val shadow = e.shadowed
        val count = counter.count(e, now, modeFor(countIn, e))

        drawIcon(canvas, e, w - padX - 22f, padY, 22f)
        val label = paint(Fonts.ui(context, bold = true), 11f, e.text, shadow)
            .apply { letterSpacing = 0.08f }
        canvas.drawText(eyebrow(pinned), padX, padY + 11f, label)
        val title = paint(Fonts.event(context, e.font), 22f, e.text, shadow)
        fit(e.title, title, w - padX * 2 - 30f, 0.7f)
        canvas.save()
        canvas.translate(padX, padY + 15f)
        layout(e.title, title, w - padX * 2 - 30f, 1).draw(canvas)
        canvas.restore()

        // Right column: date over a 130-wide progress bar.
        val barW = min(130f, w * 0.38f)
        val barRect = RectF(w - padX - barW, h - padY - 8f, w - padX, h - padY)
        val track = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = alpha(e.text, 0.18) }
        canvas.drawRoundRect(barRect, 4f, 4f, track)
        val value = counter.progress(e, now).toFloat()
        val filled = RectF(barRect.left, barRect.top, barRect.left + maxOf(8f, barW * value), barRect.bottom)
        canvas.drawRoundRect(filled, 4f, 4f, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = e.text })
        val date = paint(Fonts.ui(context), 12f, e.text, shadow)
        val dateText = counter.shortDate(e, now)
        canvas.drawText(dateText, w - padX - date.measureText(dateText), barRect.top - 6f - date.descent(), date)

        drawCount(
            canvas, count, padX, h - padY - 4f, w - padX * 2 - barW - 8f,
            bigSize = 60f, unitSize = 16f, gap = 6f, ink = e.text, shadow = shadow,
        )
        return bitmap
    }

    /** The lead card at the top of the 4×4 widget. */
    fun lead(e: WidgetEvent, pinned: Boolean, w: Float, h: Float): Bitmap {
        val (bitmap, canvas) = canvasFor(w, h)
        background(canvas, e, RectF(0f, 0f, w, h), 18f, e.photoWide)
        val pad = 16f
        val shadow = e.shadowed
        val count = counter.count(e, now, modeFor(countIn, e))

        // Measure the count first so the title knows how much room it has.
        val big = paint(Fonts.numeral(context, 48f), 48f, e.text, shadow)
        val unit = paint(Fonts.ui(context, bold = true), 14f, e.text, shadow)
        val countW = minOf(
            big.measureText(count.big) + if (count.unit.isEmpty()) 0f else unit.measureText(count.unit) + 3f,
            w * 0.5f,
        )
        val baseline = h - 14f - 4f
        drawCount(
            canvas, count, w - pad - countW, baseline, countW,
            bigSize = 48f, unitSize = 14f, gap = 3f, ink = e.text, shadow = shadow,
        )
        val label = paint(Fonts.ui(context, bold = true), 11f, e.text, shadow)
            .apply { letterSpacing = 0.08f }
        val title = paint(Fonts.event(context, e.font), 20f, e.text, shadow)
        val titleW = w - pad * 2 - countW - 8f
        canvas.save()
        canvas.translate(pad, baseline - 24f)
        layout(e.title, title, titleW, 1).draw(canvas)
        canvas.restore()
        canvas.drawText(eyebrow(pinned), pad, baseline - 28f, label)
        return bitmap
    }

    /**
     * The large widget when only one countdown is active: the countdown
     * fills the widget edge to edge, with its full-screen photo crop.
     */
    fun hero(e: WidgetEvent, pinned: Boolean, w: Float, h: Float, radius: Float): Bitmap {
        val (bitmap, canvas) = canvasFor(w, h)
        background(canvas, e, RectF(0f, 0f, w, h), radius, e.photoFull ?: e.photo)
        val pad = 20f
        val shadow = e.shadowed
        val count = counter.count(e, now, modeFor(countIn, e))

        drawIcon(canvas, e, w - pad - 26f, pad, 26f)
        val label = paint(Fonts.ui(context, bold = true), 12f, e.text, shadow)
            .apply { letterSpacing = 0.08f }
        canvas.drawText(eyebrow(pinned), pad, pad + 12f, label)
        val title = paint(Fonts.event(context, e.font), 28f, e.text, shadow)
        canvas.save()
        canvas.translate(pad, pad + 18f)
        layout(e.title, title, w - pad * 2 - 34f, 2).draw(canvas)
        canvas.restore()

        // Bottom up: progress bar, date, then the big count.
        var bottom = h - pad
        if (h >= 220f) {
            val bar = RectF(pad, bottom - 8f, w - pad, bottom)
            canvas.drawRoundRect(bar, 4f, 4f, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = alpha(e.text, 0.18) })
            val value = counter.progress(e, now).toFloat()
            canvas.drawRoundRect(
                RectF(bar.left, bar.top, bar.left + maxOf(8f, bar.width() * value), bar.bottom),
                4f, 4f, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = e.text },
            )
            bottom = bar.top - 12f
        }
        val date = paint(Fonts.ui(context), 15f, e.text, shadow)
        canvas.drawText(counter.shortDate(e, now), pad, bottom - date.descent(), date)
        val bigSize = (h * 0.34f).coerceIn(64f, 132f)
        drawCount(
            canvas, count, pad, bottom - 26f, w - pad * 2,
            bigSize = bigSize, unitSize = 20f, gap = 8f, ink = e.text, shadow = shadow,
        )
        return bitmap
    }

    /** One row of the Up next list: tile, title and date, count. */
    fun row(e: WidgetEvent, w: Float): Bitmap {
        val h = 38f
        val (bitmap, canvas) = canvasFor(w, h)
        val tile = RectF(0f, 2f, 34f, 36f)
        background(canvas, e, tile, 11f, e.photo)
        drawIcon(canvas, e, tile.centerX() - 9f, tile.centerY() - 9f, 18f)

        val mode = modeFor(countIn, e)
        val count = counter.count(e, now, mode)
        val big = paint(Fonts.numeral(context, 22f), 22f, Palette.INK, false)
        val unit = paint(Fonts.ui(context, bold = true), 12f, Palette.PENCIL, false)
        val suffix = if (count.unit.isEmpty()) "" else if (mode == CountMode.Sleeps) " sl" else " d"
        val suffixW = unit.measureText(suffix)
        val bigW = big.measureText(count.big)
        val baseline = 27f
        canvas.drawText(count.big, w - suffixW - bigW, baseline, big)
        canvas.drawText(suffix, w - suffixW, baseline, unit)

        val textX = 44f
        val textW = w - textX - bigW - suffixW - 6f
        val title = paint(Fonts.event(context, e.font), 15f, Palette.INK, false)
        canvas.save()
        canvas.translate(textX, 2f)
        layout(e.title, title, textW, 1).draw(canvas)
        canvas.restore()
        val date = paint(Fonts.ui(context), 11f, Palette.PENCIL, false)
        canvas.drawText(counter.shortDate(e, now), textX, 34f, date)
        return bitmap
    }

    fun describe(e: WidgetEvent): String {
        val c = counter.count(e, now, modeFor(countIn, e))
        val count = if (c.unit.isEmpty()) "${e.title} is today" else "${e.title}, ${c.big} ${c.unit}"
        return "$count, ${counter.shortDate(e, now)}"
    }
}
