package com.memoflow.hzc073.widgets

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.Rect
import android.graphics.RectF
import android.util.Base64
import com.memoflow.hzc073.R
import org.json.JSONArray
import org.json.JSONObject

private const val DAILY_REVIEW_PREFS = "memoflow_widget_daily_review"
private const val KEY_TITLE = "title"
private const val KEY_FALLBACK_BODY = "fallback_body"
private const val KEY_ITEMS = "items"
private const val KEY_INDEX = "index"
private const val KEY_LAST_ROTATED_AT = "last_rotated_at"
private const val KEY_AVATAR_BASE64 = "avatar_base64"
private const val KEY_LOCALE_TAG = "locale_tag"

data class WidgetDailyReviewItem(
    val memoUid: String?,
    val excerpt: String,
    val dateLabel: String,
)

data class WidgetDailyReviewData(
    val title: String,
    val fallbackBody: String,
    val items: List<WidgetDailyReviewItem>,
    val currentIndex: Int,
    val lastRotatedAtMs: Long,
    val avatarBase64: String?,
    val localeTag: String,
)

object WidgetDailyReviewStore {
    private val rotationIntervalMs = 6L * 60L * 60L * 1000L
    private val minuteTickIntervalMs = 60L * 1000L

    fun save(
        context: Context,
        title: String,
        fallbackBody: String,
        items: List<WidgetDailyReviewItem>,
        avatarBytes: ByteArray? = null,
        clearAvatar: Boolean = false,
        localeTag: String = "",
    ) {
        val prefs = context.getSharedPreferences(DAILY_REVIEW_PREFS, Context.MODE_PRIVATE)
        val existing = load(context)
        val array = JSONArray()
        items.forEach { item ->
            array.put(
                JSONObject().apply {
                    put("memoUid", item.memoUid)
                    put("excerpt", item.excerpt)
                    put("dateLabel", item.dateLabel)
                },
            )
        }

        val currentItem = existing.items.getOrNull(existing.currentIndex)
        val nextIndex = when {
            items.isEmpty() -> 0
            existing.items.isEmpty() -> 0
            else -> findMatchingIndex(items, currentItem) ?: normalizeIndex(existing.currentIndex, items.size)
        }
        val now = System.currentTimeMillis()
        val nextLastRotatedAtMs = when {
            items.isEmpty() -> 0L
            existing.items.isEmpty() -> now
            existing.lastRotatedAtMs > 0L -> existing.lastRotatedAtMs
            else -> now
        }
        val nextAvatarBase64 = when {
            avatarBytes?.isNotEmpty() == true -> Base64.encodeToString(avatarBytes, Base64.NO_WRAP)
            clearAvatar -> null
            else -> existing.avatarBase64
        }
        val nextLocaleTag = localeTag.trim().ifEmpty { existing.localeTag.ifEmpty { "en" } }

        prefs.edit()
            .putString(KEY_TITLE, title)
            .putString(KEY_FALLBACK_BODY, fallbackBody)
            .putString(KEY_ITEMS, array.toString())
            .putInt(KEY_INDEX, nextIndex)
            .putLong(KEY_LAST_ROTATED_AT, nextLastRotatedAtMs)
            .putString(KEY_AVATAR_BASE64, nextAvatarBase64)
            .putString(KEY_LOCALE_TAG, nextLocaleTag)
            .apply()
    }

    fun load(context: Context): WidgetDailyReviewData {
        val prefs = context.getSharedPreferences(DAILY_REVIEW_PREFS, Context.MODE_PRIVATE)
        val title =
            prefs.getString(KEY_TITLE, context.getString(R.string.widget_daily_review_placeholder_title))
                ?: context.getString(R.string.widget_daily_review_placeholder_title)
        val fallbackBody =
            prefs.getString(
                KEY_FALLBACK_BODY,
                context.getString(R.string.widget_daily_review_placeholder_body),
            ) ?: context.getString(R.string.widget_daily_review_placeholder_body)
        val items = parseItems(prefs.getString(KEY_ITEMS, null))
        val rawIndex = prefs.getInt(KEY_INDEX, 0)
        val currentIndex = normalizeIndex(rawIndex, items.size)
        val lastRotatedAtMs = prefs.getLong(KEY_LAST_ROTATED_AT, 0L)
        val avatarBase64 = prefs.getString(KEY_AVATAR_BASE64, null)?.trim()?.ifEmpty { null }
        val localeTag = prefs.getString(KEY_LOCALE_TAG, "en")?.trim()?.ifEmpty { "en" } ?: "en"
        return WidgetDailyReviewData(
            title = title,
            fallbackBody = fallbackBody,
            items = items,
            currentIndex = currentIndex,
            lastRotatedAtMs = lastRotatedAtMs,
            avatarBase64 = avatarBase64,
            localeTag = localeTag,
        )
    }

    fun clear(context: Context) {
        context.getSharedPreferences(DAILY_REVIEW_PREFS, Context.MODE_PRIVATE)
            .edit()
            .clear()
            .apply()
    }

    fun currentItem(context: Context): WidgetDailyReviewItem? {
        val data = load(context)
        if (data.items.isEmpty()) return null
        return data.items.getOrNull(data.currentIndex)
    }

    fun advance(context: Context, updateTimestamp: Boolean = true) {
        val data = load(context)
        if (data.items.isEmpty()) return
        val nextIndex = normalizeIndex(data.currentIndex + 1, data.items.size)
        val prefs = context.getSharedPreferences(DAILY_REVIEW_PREFS, Context.MODE_PRIVATE)
        val editor = prefs.edit().putInt(KEY_INDEX, nextIndex)
        if (updateTimestamp) {
            editor.putLong(KEY_LAST_ROTATED_AT, System.currentTimeMillis())
        }
        editor.apply()
    }

    fun rotateIfDue(context: Context, force: Boolean = false): Boolean {
        val data = load(context)
        if (data.items.size <= 1) return false
        val due = force || computeRemainingUntilNextRotationMs(data) <= 0L
        if (!due) return false
        advance(context, updateTimestamp = true)
        return true
    }

    fun intervalMs(): Long = rotationIntervalMs

    fun tickIntervalMs(): Long = minuteTickIntervalMs

    fun remainingUntilNextRotationMs(context: Context): Long {
        return computeRemainingUntilNextRotationMs(load(context))
    }

    fun countdownLabel(context: Context): String {
        val data = load(context)
        if (data.items.isEmpty()) return data.title
        return formatCountdownLabel(data.localeTag, computeRemainingUntilNextRotationMs(data))
    }

    fun avatarBitmap(context: Context, sizePx: Int): Bitmap? {
        val encoded = load(context).avatarBase64 ?: return null
        val bytes = runCatching { Base64.decode(encoded, Base64.DEFAULT) }.getOrNull() ?: return null
        val decoded = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return null
        return circularCrop(decoded, sizePx)
    }

    private fun computeRemainingUntilNextRotationMs(
        data: WidgetDailyReviewData,
        nowMs: Long = System.currentTimeMillis(),
    ): Long {
        if (data.lastRotatedAtMs <= 0L) return rotationIntervalMs
        val elapsed = (nowMs - data.lastRotatedAtMs).coerceAtLeast(0L)
        return (rotationIntervalMs - elapsed).coerceIn(0L, rotationIntervalMs)
    }

    private fun formatCountdownLabel(localeTag: String, remainingMs: Long): String {
        val normalizedLocale = localeTag.trim().lowercase()
        val zh = normalizedLocale.startsWith("zh")
        val ja = normalizedLocale.startsWith("ja")
        val de = normalizedLocale.startsWith("de")
        if (remainingMs <= 45_000L) {
            return when {
                zh -> "\u5373\u5C06\u5237\u65B0"
                ja -> "\u307E\u3082\u306A\u304F\u66F4\u65B0"
                de -> "Wird bald aktualisiert"
                else -> "Refreshing soon"
            }
        }

        val totalMinutes = ((remainingMs + 59_999L) / 60_000L).coerceAtLeast(1L)
        if (totalMinutes < 60L) {
            return when {
                zh -> "\u518D\u8FC7 ${totalMinutes} \u5206\u949F"
                ja -> "${totalMinutes}\u5206\u5F8C"
                de -> "In ${totalMinutes} Min"
                else -> "In ${totalMinutes} min"
            }
        }

        val hours = totalMinutes / 60L
        val minutes = totalMinutes % 60L
        return when {
            zh -> when {
                minutes == 0L -> "\u518D\u8FC7 ${hours} \u5C0F\u65F6"
                hours <= 1L -> "\u518D\u8FC7 ${hours} \u5C0F\u65F6 ${minutes} \u5206\u949F"
                else -> "\u518D\u8FC7 ${hours} \u5C0F\u65F6"
            }
            ja -> when {
                minutes == 0L -> "${hours}\u6642\u9593\u5F8C"
                hours <= 1L -> "${hours}\u6642\u9593${minutes}\u5206\u5F8C"
                else -> "${hours}\u6642\u9593\u5F8C"
            }
            de -> when {
                minutes == 0L -> "In ${hours} Std"
                hours <= 1L -> "In ${hours} Std ${minutes} Min"
                else -> "In ${hours} Std"
            }
            else -> when {
                minutes == 0L -> "In ${hours} hr"
                hours <= 1L -> "In ${hours} hr ${minutes} min"
                else -> "In ${hours} hr"
            }
        }
    }

    private fun circularCrop(source: Bitmap, sizePx: Int): Bitmap {
        val safeSize = sizePx.coerceAtLeast(1)
        val scaled = if (source.width != safeSize || source.height != safeSize) {
            Bitmap.createScaledBitmap(source, safeSize, safeSize, true)
        } else {
            source
        }
        val output = Bitmap.createBitmap(safeSize, safeSize, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val rect = Rect(0, 0, safeSize, safeSize)
        val rectF = RectF(rect)
        canvas.drawARGB(0, 0, 0, 0)
        paint.color = 0xFFFFFFFF.toInt()
        canvas.drawOval(rectF, paint)
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        canvas.drawBitmap(scaled, null, rect, paint)
        paint.xfermode = null
        return output
    }

    private fun findMatchingIndex(
        items: List<WidgetDailyReviewItem>,
        currentItem: WidgetDailyReviewItem?,
    ): Int? {
        if (currentItem == null) return null
        currentItem.memoUid?.let { memoUid ->
            val matchByUid = items.indexOfFirst { it.memoUid == memoUid }
            if (matchByUid >= 0) return matchByUid
        }
        val matchByContent = items.indexOfFirst {
            it.excerpt == currentItem.excerpt && it.dateLabel == currentItem.dateLabel
        }
        return matchByContent.takeIf { it >= 0 }
    }

    private fun parseItems(raw: String?): List<WidgetDailyReviewItem> {
        if (raw.isNullOrBlank()) return emptyList()
        return runCatching {
            val array = JSONArray(raw)
            buildList {
                for (index in 0 until array.length()) {
                    val item = array.optJSONObject(index) ?: continue
                    val excerpt = item.optString("excerpt").trim()
                    if (excerpt.isEmpty()) continue
                    val memoUid = item.optString("memoUid").trim().ifEmpty { null }
                    val dateLabel = item.optString("dateLabel").trim()
                    add(
                        WidgetDailyReviewItem(
                            memoUid = memoUid,
                            excerpt = excerpt,
                            dateLabel = dateLabel,
                        ),
                    )
                }
            }
        }.getOrDefault(emptyList())
    }

    private fun normalizeIndex(rawIndex: Int, size: Int): Int {
        if (size <= 0) return 0
        val mod = rawIndex % size
        return if (mod < 0) mod + size else mod
    }
}
