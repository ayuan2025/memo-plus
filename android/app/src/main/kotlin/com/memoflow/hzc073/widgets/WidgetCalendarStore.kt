package com.memoflow.hzc073.widgets

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PorterDuff
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import com.memoflow.hzc073.R
import org.json.JSONArray
import org.json.JSONObject
import java.text.DateFormatSymbols
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import kotlin.math.min

private const val CALENDAR_PREFS = "memoflow_widget_calendar"
private const val KEY_MONTH_LABEL = "month_label"
private const val KEY_WEEKDAY_LABELS = "weekday_labels"
private const val KEY_DAYS = "days"
private const val KEY_MONTH_START_EPOCH_SEC = "month_start_epoch_sec"
private const val KEY_DISPLAY_MONTH_START_EPOCH_SEC = "display_month_start_epoch_sec"
private const val KEY_LOCALE_TAG = "locale_tag"
private const val KEY_MONDAY_FIRST = "monday_first"
private const val KEY_HEAT_SCORES = "heat_scores"
private const val KEY_THEME_COLOR = "theme_color"
private const val DEFAULT_THEME_COLOR = 0xFFC0564D.toInt()
private const val TAG = "WidgetCalendarStore"

data class WidgetCalendarDay(
    val label: String,
    val intensity: Int,
    val dayEpochSec: Long?,
    val isCurrentMonth: Boolean,
    val isToday: Boolean,
)

data class WidgetCalendarHeatScore(
    val dayEpochSec: Long,
    val heatScore: Int,
)

data class WidgetCalendarData(
    val monthLabel: String,
    val weekdayLabels: List<String>,
    val days: List<WidgetCalendarDay>,
    val themeColorArgb: Int,
    val canGoNext: Boolean,
)

object WidgetCalendarStore {
    private val weekdayLabelIds = intArrayOf(
        R.id.widget_weekday_0,
        R.id.widget_weekday_1,
        R.id.widget_weekday_2,
        R.id.widget_weekday_3,
        R.id.widget_weekday_4,
        R.id.widget_weekday_5,
        R.id.widget_weekday_6,
    )

    private val dayCellIds = intArrayOf(
        R.id.widget_day_cell_0, R.id.widget_day_cell_1, R.id.widget_day_cell_2, R.id.widget_day_cell_3, R.id.widget_day_cell_4, R.id.widget_day_cell_5, R.id.widget_day_cell_6,
        R.id.widget_day_cell_7, R.id.widget_day_cell_8, R.id.widget_day_cell_9, R.id.widget_day_cell_10, R.id.widget_day_cell_11, R.id.widget_day_cell_12, R.id.widget_day_cell_13,
        R.id.widget_day_cell_14, R.id.widget_day_cell_15, R.id.widget_day_cell_16, R.id.widget_day_cell_17, R.id.widget_day_cell_18, R.id.widget_day_cell_19, R.id.widget_day_cell_20,
        R.id.widget_day_cell_21, R.id.widget_day_cell_22, R.id.widget_day_cell_23, R.id.widget_day_cell_24, R.id.widget_day_cell_25, R.id.widget_day_cell_26, R.id.widget_day_cell_27,
        R.id.widget_day_cell_28, R.id.widget_day_cell_29, R.id.widget_day_cell_30, R.id.widget_day_cell_31, R.id.widget_day_cell_32, R.id.widget_day_cell_33, R.id.widget_day_cell_34,
        R.id.widget_day_cell_35, R.id.widget_day_cell_36, R.id.widget_day_cell_37, R.id.widget_day_cell_38, R.id.widget_day_cell_39, R.id.widget_day_cell_40, R.id.widget_day_cell_41,
    )

    private val dayCircleIds = intArrayOf(
        R.id.widget_day_circle_0, R.id.widget_day_circle_1, R.id.widget_day_circle_2, R.id.widget_day_circle_3, R.id.widget_day_circle_4, R.id.widget_day_circle_5, R.id.widget_day_circle_6,
        R.id.widget_day_circle_7, R.id.widget_day_circle_8, R.id.widget_day_circle_9, R.id.widget_day_circle_10, R.id.widget_day_circle_11, R.id.widget_day_circle_12, R.id.widget_day_circle_13,
        R.id.widget_day_circle_14, R.id.widget_day_circle_15, R.id.widget_day_circle_16, R.id.widget_day_circle_17, R.id.widget_day_circle_18, R.id.widget_day_circle_19, R.id.widget_day_circle_20,
        R.id.widget_day_circle_21, R.id.widget_day_circle_22, R.id.widget_day_circle_23, R.id.widget_day_circle_24, R.id.widget_day_circle_25, R.id.widget_day_circle_26, R.id.widget_day_circle_27,
        R.id.widget_day_circle_28, R.id.widget_day_circle_29, R.id.widget_day_circle_30, R.id.widget_day_circle_31, R.id.widget_day_circle_32, R.id.widget_day_circle_33, R.id.widget_day_circle_34,
        R.id.widget_day_circle_35, R.id.widget_day_circle_36, R.id.widget_day_circle_37, R.id.widget_day_circle_38, R.id.widget_day_circle_39, R.id.widget_day_circle_40, R.id.widget_day_circle_41,
    )

    private val dayLabelIds = intArrayOf(
        R.id.widget_day_label_0, R.id.widget_day_label_1, R.id.widget_day_label_2, R.id.widget_day_label_3, R.id.widget_day_label_4, R.id.widget_day_label_5, R.id.widget_day_label_6,
        R.id.widget_day_label_7, R.id.widget_day_label_8, R.id.widget_day_label_9, R.id.widget_day_label_10, R.id.widget_day_label_11, R.id.widget_day_label_12, R.id.widget_day_label_13,
        R.id.widget_day_label_14, R.id.widget_day_label_15, R.id.widget_day_label_16, R.id.widget_day_label_17, R.id.widget_day_label_18, R.id.widget_day_label_19, R.id.widget_day_label_20,
        R.id.widget_day_label_21, R.id.widget_day_label_22, R.id.widget_day_label_23, R.id.widget_day_label_24, R.id.widget_day_label_25, R.id.widget_day_label_26, R.id.widget_day_label_27,
        R.id.widget_day_label_28, R.id.widget_day_label_29, R.id.widget_day_label_30, R.id.widget_day_label_31, R.id.widget_day_label_32, R.id.widget_day_label_33, R.id.widget_day_label_34,
        R.id.widget_day_label_35, R.id.widget_day_label_36, R.id.widget_day_label_37, R.id.widget_day_label_38, R.id.widget_day_label_39, R.id.widget_day_label_40, R.id.widget_day_label_41,
    )

    fun save(
        context: Context,
        monthLabel: String,
        weekdayLabels: List<String>,
        days: List<WidgetCalendarDay>,
        monthStartEpochSec: Long?,
        localeTag: String,
        mondayFirst: Boolean,
        heatScores: List<WidgetCalendarHeatScore>,
        themeColorArgb: Int,
    ) {
        val nonZeroHeatScores = heatScores.count { it.heatScore > 0 }
        val maxHeatScore = heatScores.maxOfOrNull { it.heatScore } ?: 0
        Log.d(
            TAG,
            "save monthLabel=$monthLabel days=${days.size} heatScores=${heatScores.size} nonZeroHeatScores=$nonZeroHeatScores maxHeatScore=$maxHeatScore monthStartEpochSec=$monthStartEpochSec localeTag=$localeTag mondayFirst=$mondayFirst themeColorArgb=$themeColorArgb",
        )
        val weekdayArray = JSONArray()
        weekdayLabels.take(7).forEach { weekdayArray.put(it) }
        val daysArray = JSONArray()
        days.take(42).forEach { day ->
            daysArray.put(
                JSONObject().apply {
                    put("label", day.label)
                    put("intensity", day.intensity)
                    put("dayEpochSec", day.dayEpochSec)
                    put("isCurrentMonth", day.isCurrentMonth)
                    put("isToday", day.isToday)
                },
            )
        }
        val heatScoresArray = JSONArray()
        heatScores.forEach { entry ->
            heatScoresArray.put(
                JSONObject().apply {
                    put("dayEpochSec", entry.dayEpochSec)
                    put("heatScore", entry.heatScore)
                },
            )
        }
        val prefs = context.getSharedPreferences(CALENDAR_PREFS, Context.MODE_PRIVATE)
        val existingStoredMonthStartEpochSec = prefs.getLong(KEY_MONTH_START_EPOCH_SEC, 0L)
            .takeIf { it > 0L }
        val existingDisplayMonthStartEpochSec = prefs.getLong(
            KEY_DISPLAY_MONTH_START_EPOCH_SEC,
            0L,
        ).takeIf { it > 0L }
        val resolvedMonthStartEpochSec = monthStartEpochSec?.takeIf { it > 0L }
        val nextDisplayMonthStartEpochSec = when {
            resolvedMonthStartEpochSec == null -> existingDisplayMonthStartEpochSec ?: 0L
            existingStoredMonthStartEpochSec != null &&
                existingDisplayMonthStartEpochSec != null &&
                existingDisplayMonthStartEpochSec == existingStoredMonthStartEpochSec -> {
                resolvedMonthStartEpochSec
            }
            existingDisplayMonthStartEpochSec != null -> existingDisplayMonthStartEpochSec
            else -> resolvedMonthStartEpochSec
        }
        prefs.edit()
            .putString(KEY_MONTH_LABEL, monthLabel)
            .putString(KEY_WEEKDAY_LABELS, weekdayArray.toString())
            .putString(KEY_DAYS, daysArray.toString())
            .putLong(KEY_MONTH_START_EPOCH_SEC, resolvedMonthStartEpochSec ?: 0L)
            .putLong(KEY_DISPLAY_MONTH_START_EPOCH_SEC, nextDisplayMonthStartEpochSec)
            .putString(KEY_LOCALE_TAG, localeTag)
            .putBoolean(KEY_MONDAY_FIRST, mondayFirst)
            .putString(KEY_HEAT_SCORES, heatScoresArray.toString())
            .putInt(KEY_THEME_COLOR, themeColorArgb)
            .apply()
    }

    fun clear(context: Context) {
        context.getSharedPreferences(CALENDAR_PREFS, Context.MODE_PRIVATE)
            .edit()
            .clear()
            .apply()
    }

    fun load(context: Context): WidgetCalendarData {
        val prefs = context.getSharedPreferences(CALENDAR_PREFS, Context.MODE_PRIVATE)
        val themeColorArgb = prefs.getInt(KEY_THEME_COLOR, DEFAULT_THEME_COLOR)
        val storedMonthStartEpochSec = prefs.getLong(KEY_MONTH_START_EPOCH_SEC, 0L)
            .takeIf { it > 0L }
        val localeTag = prefs.getString(KEY_LOCALE_TAG, null)?.trim().orEmpty()
        val mondayFirst = prefs.getBoolean(KEY_MONDAY_FIRST, false)
        val heatScores = parseHeatScores(prefs.getString(KEY_HEAT_SCORES, null))
        val storedDisplayMonthStartEpochSec = prefs.getLong(
            KEY_DISPLAY_MONTH_START_EPOCH_SEC,
            0L,
        ).takeIf { it > 0L }
        Log.d(
            TAG,
            "load storedMonthStartEpochSec=$storedMonthStartEpochSec storedDisplayMonthStartEpochSec=$storedDisplayMonthStartEpochSec localeTag=$localeTag mondayFirst=$mondayFirst heatScores=${heatScores.size} themeColorArgb=$themeColorArgb",
        )
        if (
            storedMonthStartEpochSec != null ||
            storedDisplayMonthStartEpochSec != null ||
            heatScores.isNotEmpty() ||
            localeTag.isNotBlank()
        ) {
            return buildCalendarData(
                themeColorArgb = themeColorArgb,
                displayMonthStart = resolveDisplayMonthStart(
                    prefs = prefs,
                    localeTag = localeTag,
                    fallbackMonthStartEpochSec = storedMonthStartEpochSec,
                ),
                localeTag = localeTag,
                mondayFirst = mondayFirst,
                heatScores = heatScores,
            )
        }
        val fallback = buildFallbackData(themeColorArgb)
        val rawMonthLabel = prefs.getString(KEY_MONTH_LABEL, null)?.trim().orEmpty()
        val weekdayLabels = parseWeekdayLabels(
            prefs.getString(KEY_WEEKDAY_LABELS, null),
            fallback.weekdayLabels,
        )
        val days = mergeDays(
            parseDays(prefs.getString(KEY_DAYS, null)),
            fallback.days,
        )
        val monthLabel = rawMonthLabel.takeIf {
            it.isNotEmpty() && !it.equals("Calendar", ignoreCase = true)
        } ?: fallback.monthLabel
        return WidgetCalendarData(
            monthLabel = monthLabel,
            weekdayLabels = weekdayLabels,
            days = days,
            themeColorArgb = themeColorArgb,
            canGoNext = false,
        )
    }

    fun applyToViews(context: Context, views: RemoteViews) {
        val data = load(context)
        val filledDays = data.days.count { it.isCurrentMonth && it.intensity > 0 }
        val maxIntensity = data.days.maxOfOrNull { it.intensity } ?: 0
        Log.d(
            TAG,
            "applyToViews monthLabel=${data.monthLabel} filledDays=$filledDays maxIntensity=$maxIntensity canGoNext=${data.canGoNext}",
        )
        views.setTextViewText(R.id.widget_month_label, data.monthLabel)
        views.setTextColor(R.id.widget_month_label, resolveMonthLabelColor(data.themeColorArgb))
        views.setTextColor(
            R.id.widget_prev_month_button,
            resolveWeekdayTextColor(data.themeColorArgb),
        )
        views.setTextColor(
            R.id.widget_next_month_button,
            if (data.canGoNext) resolveWeekdayTextColor(data.themeColorArgb) else 0xFFBCC5D2.toInt(),
        )
        weekdayLabelIds.forEachIndexed { index, viewId ->
            views.setTextViewText(viewId, data.weekdayLabels.getOrNull(index).orEmpty())
            views.setTextColor(viewId, resolveWeekdayTextColor(data.themeColorArgb))
        }
        dayCellIds.forEachIndexed { index, cellId ->
            val circleId = dayCircleIds[index]
            val labelId = dayLabelIds[index]
            val day = data.days.getOrNull(index) ?: WidgetCalendarDay("", 0, null, false, false)
            views.setTextViewText(labelId, day.label)
            views.setTextColor(labelId, resolveDayTextColor(day, data.themeColorArgb))
            val bitmap = buildCircleBitmap(day, data.themeColorArgb)
            if (bitmap != null) {
                views.setImageViewBitmap(circleId, bitmap)
                views.setViewVisibility(circleId, View.VISIBLE)
            } else if (day.isToday && day.isCurrentMonth) {
                views.setImageViewBitmap(circleId, buildTodayOutlineBitmap(data.themeColorArgb))
                views.setViewVisibility(circleId, View.VISIBLE)
            } else {
                views.setImageViewBitmap(circleId, transparentBitmap())
                views.setViewVisibility(circleId, View.INVISIBLE)
            }
            views.setBoolean(cellId, "setEnabled", day.dayEpochSec != null)
        }
        views.setOnClickPendingIntent(
            R.id.widget_month_label,
            WidgetIntents.launchApp(context, action = WidgetIntents.ACTION_CALENDAR, requestCode = 9000),
        )
        views.setOnClickPendingIntent(
            R.id.widget_prev_month_button,
            StatsWidgetProvider.changeMonthPendingIntent(context, deltaMonths = -1),
        )
        views.setOnClickPendingIntent(
            R.id.widget_next_month_button,
            StatsWidgetProvider.changeMonthPendingIntent(context, deltaMonths = 1),
        )
        dayCellIds.forEachIndexed { index, cellId ->
            val day = data.days.getOrNull(index)
            views.setOnClickPendingIntent(
                cellId,
                if (day?.dayEpochSec != null) {
                    WidgetIntents.launchApp(
                        context,
                        action = WidgetIntents.ACTION_CALENDAR,
                        dayEpochSec = day.dayEpochSec,
                        requestCode = 9100 + index,
                    )
                } else {
                    WidgetIntents.launchApp(
                        context,
                        action = WidgetIntents.ACTION_CALENDAR,
                        requestCode = 9300 + index,
                    )
                },
            )
        }
    }

    private fun parseWeekdayLabels(raw: String?, fallback: List<String>): List<String> {
        if (raw.isNullOrBlank()) return fallback
        return runCatching {
            val array = JSONArray(raw)
            buildList {
                for (index in 0 until array.length()) {
                    add(array.optString(index))
                }
            }.takeIf { it.size == 7 && it.any { label -> label.isNotBlank() } } ?: fallback
        }.getOrDefault(fallback)
    }

    private fun parseDays(raw: String?): List<WidgetCalendarDay> {
        if (raw.isNullOrBlank()) return emptyList()
        return runCatching {
            val array = JSONArray(raw)
            buildList {
                for (index in 0 until array.length()) {
                    val item = array.optJSONObject(index) ?: continue
                    add(
                        WidgetCalendarDay(
                            label = item.optString("label"),
                            intensity = item.optInt("intensity", 0).coerceIn(0, 6),
                            dayEpochSec = item.optLong("dayEpochSec").takeIf { it > 0L },
                            isCurrentMonth = item.optBoolean("isCurrentMonth", false),
                            isToday = item.optBoolean("isToday", false),
                        ),
                    )
                }
            }.take(42)
        }.getOrDefault(emptyList())
    }

    private fun parseHeatScores(raw: String?): List<WidgetCalendarHeatScore> {
        if (raw.isNullOrBlank()) return emptyList()
        return runCatching {
            val array = JSONArray(raw)
            buildList {
                for (index in 0 until array.length()) {
                    val item = array.optJSONObject(index) ?: continue
                    val dayEpochSec = item.optLong("dayEpochSec").takeIf { it > 0L } ?: continue
                    add(
                        WidgetCalendarHeatScore(
                            dayEpochSec = dayEpochSec,
                            heatScore = item.optInt("heatScore", 0).coerceAtLeast(0),
                        ),
                    )
                }
            }
        }.getOrDefault(emptyList())
    }

    private fun mergeDays(
        storedDays: List<WidgetCalendarDay>,
        fallbackDays: List<WidgetCalendarDay>,
    ): List<WidgetCalendarDay> {
        if (storedDays.isEmpty()) return fallbackDays
        return List(fallbackDays.size) { index ->
            val fallback = fallbackDays[index]
            val stored = storedDays.getOrNull(index)
            if (stored == null || isEmptyStoredDay(stored)) {
                fallback
            } else {
                WidgetCalendarDay(
                    label = stored.label.ifBlank { fallback.label },
                    intensity = if (stored.isCurrentMonth) stored.intensity.coerceIn(0, 6) else 0,
                    dayEpochSec = if (stored.isCurrentMonth) {
                        stored.dayEpochSec ?: fallback.dayEpochSec
                    } else {
                        null
                    },
                    isCurrentMonth = stored.isCurrentMonth,
                    isToday = stored.isToday || fallback.isToday,
                )
            }
        }
    }

    private fun isEmptyStoredDay(day: WidgetCalendarDay): Boolean {
        return day.label.isBlank() &&
            day.intensity <= 0 &&
            day.dayEpochSec == null &&
            !day.isCurrentMonth &&
            !day.isToday
    }

    private fun buildFallbackData(themeColorArgb: Int): WidgetCalendarData {
        return buildCalendarData(
            themeColorArgb = themeColorArgb,
            displayMonthStart = currentMonthStart(Locale.getDefault()),
            localeTag = Locale.getDefault().toLanguageTag(),
            mondayFirst = false,
            heatScores = emptyList(),
        )
    }

    fun shiftDisplayedMonth(context: Context, deltaMonths: Int) {
        if (deltaMonths == 0) return
        val prefs = context.getSharedPreferences(CALENDAR_PREFS, Context.MODE_PRIVATE)
        val localeTag = prefs.getString(KEY_LOCALE_TAG, null)?.trim().orEmpty()
        val before = prefs.getLong(KEY_DISPLAY_MONTH_START_EPOCH_SEC, 0L).takeIf { it > 0L }
        val shifted = resolveDisplayMonthStart(
            prefs = prefs,
            localeTag = localeTag,
            fallbackMonthStartEpochSec = prefs.getLong(KEY_MONTH_START_EPOCH_SEC, 0L).takeIf { it > 0L },
        ).apply {
            add(Calendar.MONTH, deltaMonths)
            val currentMonthStart = currentMonthStart(resolveLocale(localeTag))
            if (timeInMillis > currentMonthStart.timeInMillis) {
                timeInMillis = currentMonthStart.timeInMillis
            }
        }
        prefs.edit()
            .putLong(KEY_DISPLAY_MONTH_START_EPOCH_SEC, shifted.timeInMillis / 1000)
            .apply()
        Log.d(
            TAG,
            "shiftDisplayedMonth deltaMonths=$deltaMonths before=$before after=${shifted.timeInMillis / 1000} label=${SimpleDateFormat("yyyy-MM", resolveLocale(localeTag)).format(shifted.time)}",
        )
    }

    private fun buildCalendarData(
        themeColorArgb: Int,
        displayMonthStart: Calendar,
        localeTag: String,
        mondayFirst: Boolean,
        heatScores: List<WidgetCalendarHeatScore>,
    ): WidgetCalendarData {
        val locale = resolveLocale(localeTag)
        val today = Calendar.getInstance(locale).apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val monthStart = (displayMonthStart.clone() as Calendar).apply {
            set(Calendar.DAY_OF_MONTH, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startOfWeek = if (mondayFirst) Calendar.MONDAY else Calendar.SUNDAY
        val offset = (monthStart.get(Calendar.DAY_OF_WEEK) - startOfWeek + 7) % 7
        val gridStart = (monthStart.clone() as Calendar).apply {
            add(Calendar.DAY_OF_MONTH, -offset)
        }
        val monthLabel = SimpleDateFormat("yyyy-MM", locale).format(monthStart.time)
        val weekdayLabels = buildFallbackWeekdayLabels(locale, startOfWeek)
        val heatScoreByDay = heatScores.associate { it.dayEpochSec to it.heatScore }

        var maxHeatScore = 0
        val monthHeatScores = mutableMapOf<Long, Int>()
        val monthCursor = monthStart.clone() as Calendar
        while (
            monthCursor.get(Calendar.MONTH) == monthStart.get(Calendar.MONTH) &&
                monthCursor.get(Calendar.YEAR) == monthStart.get(Calendar.YEAR)
        ) {
            val dayEpochSec = monthCursor.timeInMillis / 1000
            val score = heatScoreByDay[dayEpochSec] ?: 0
            monthHeatScores[dayEpochSec] = score
            if (score > maxHeatScore) {
                maxHeatScore = score
            }
            monthCursor.add(Calendar.DAY_OF_MONTH, 1)
        }
        Log.d(
            TAG,
            "buildCalendarData displayMonth=${SimpleDateFormat("yyyy-MM", locale).format(monthStart.time)} heatScores=${heatScores.size} monthHeatDays=${monthHeatScores.count { it.value > 0 }} maxHeatScore=$maxHeatScore canGoNext=${monthStart.timeInMillis < currentMonthStart(locale).timeInMillis}",
        )

        val days = List(42) { index ->
            val cellDate = (gridStart.clone() as Calendar).apply {
                add(Calendar.DAY_OF_MONTH, index)
            }
            val isCurrentMonth = cellDate.get(Calendar.MONTH) == monthStart.get(Calendar.MONTH) &&
                cellDate.get(Calendar.YEAR) == monthStart.get(Calendar.YEAR)
            val isToday = cellDate.get(Calendar.YEAR) == today.get(Calendar.YEAR) &&
                cellDate.get(Calendar.DAY_OF_YEAR) == today.get(Calendar.DAY_OF_YEAR)
            val dayEpochSec = if (isCurrentMonth) cellDate.timeInMillis / 1000 else null
            val heatScore = if (isCurrentMonth && dayEpochSec != null) {
                monthHeatScores[dayEpochSec] ?: 0
            } else {
                0
            }
            WidgetCalendarDay(
                label = cellDate.get(Calendar.DAY_OF_MONTH).toString(),
                intensity = resolveHeatIntensity(heatScore, maxHeatScore),
                dayEpochSec = dayEpochSec,
                isCurrentMonth = isCurrentMonth,
                isToday = isToday,
            )
        }

        return WidgetCalendarData(
            monthLabel = monthLabel,
            weekdayLabels = weekdayLabels,
            days = days,
            themeColorArgb = themeColorArgb,
            canGoNext = monthStart.timeInMillis < currentMonthStart(locale).timeInMillis,
        )
    }

    private fun resolveDisplayMonthStart(
        prefs: android.content.SharedPreferences,
        localeTag: String,
        fallbackMonthStartEpochSec: Long?,
    ): Calendar {
        val locale = resolveLocale(localeTag)
        val displayEpochSec = prefs.getLong(KEY_DISPLAY_MONTH_START_EPOCH_SEC, 0L)
            .takeIf { it > 0L }
            ?: fallbackMonthStartEpochSec
        return if (displayEpochSec != null) {
            monthStartFromEpochSec(displayEpochSec, locale)
        } else {
            currentMonthStart(locale)
        }
    }

    private fun resolveLocale(localeTag: String): Locale {
        if (localeTag.isBlank()) return Locale.getDefault()
        return Locale.forLanguageTag(localeTag).takeIf { it.language.isNotBlank() } ?: Locale.getDefault()
    }

    private fun monthStartFromEpochSec(epochSec: Long, locale: Locale): Calendar {
        return Calendar.getInstance(locale).apply {
            timeInMillis = epochSec * 1000
            set(Calendar.DAY_OF_MONTH, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
    }

    private fun currentMonthStart(locale: Locale): Calendar {
        return Calendar.getInstance(locale).apply {
            set(Calendar.DAY_OF_MONTH, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
    }

    private fun resolveHeatIntensity(heatScore: Int, maxHeatScore: Int): Int {
        if (heatScore <= 0 || maxHeatScore <= 0) return 0
        if (heatScore >= maxHeatScore) return 6
        val ratio = heatScore.toDouble() / maxHeatScore.toDouble()
        return kotlin.math.ceil(ratio * 6.0).toInt().coerceIn(1, 6)
    }

    private fun buildFallbackWeekdayLabels(locale: Locale, firstDayOfWeek: Int): List<String> {
        val symbols = DateFormatSymbols.getInstance(locale).shortWeekdays
        return List(7) { index ->
            val dayOfWeek = ((firstDayOfWeek - Calendar.SUNDAY + index + 7) % 7) + Calendar.SUNDAY
            symbols.getOrNull(dayOfWeek)
                ?.takeIf { it.isNotBlank() }
                ?.replace(".", "")
                ?: defaultWeekdayLabel(dayOfWeek)
        }
    }

    private fun defaultWeekdayLabel(dayOfWeek: Int): String {
        return when (dayOfWeek) {
            Calendar.MONDAY -> "Mon"
            Calendar.TUESDAY -> "Tue"
            Calendar.WEDNESDAY -> "Wed"
            Calendar.THURSDAY -> "Thu"
            Calendar.FRIDAY -> "Fri"
            Calendar.SATURDAY -> "Sat"
            else -> "Sun"
        }
    }

    private fun resolveMonthLabelColor(themeColorArgb: Int): Int {
        return blendColors(0xFF182230.toInt(), themeColorArgb, 0.18f)
    }

    private fun resolveWeekdayTextColor(themeColorArgb: Int): Int {
        return blendColors(0xFF667085.toInt(), themeColorArgb, 0.08f)
    }

    private fun resolveDayTextColor(day: WidgetCalendarDay, themeColorArgb: Int): Int {
        if (!day.isCurrentMonth) return 0xFF98A2B3.toInt()
        if (day.intensity > 0) {
            val fillColor = resolveHeatFillColor(themeColorArgb, day.intensity)
            return if (isDarkEnoughForLightText(fillColor)) {
                Color.WHITE
            } else {
                0xFF243041.toInt()
            }
        }
        if (day.isToday) return blendColors(0xFF243041.toInt(), themeColorArgb, 0.36f)
        return 0xFF344054.toInt()
    }

    private fun buildCircleBitmap(day: WidgetCalendarDay, themeColorArgb: Int): Bitmap? {
        if (!day.isCurrentMonth || day.intensity <= 0) return null
        val sizePx = 52
        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = resolveHeatFillColor(themeColorArgb, day.intensity)
            style = Paint.Style.FILL
        }
        val radius = min(sizePx, sizePx) / 2f - 2f
        canvas.drawCircle(sizePx / 2f, sizePx / 2f, radius, paint)
        return bitmap
    }

    private fun buildTodayOutlineBitmap(themeColorArgb: Int): Bitmap {
        val sizePx = 52
        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = withAlpha(themeColorArgb, 0.64f)
            style = Paint.Style.STROKE
            strokeWidth = 2.4f
        }
        val radius = min(sizePx, sizePx) / 2f - 3.5f
        canvas.drawCircle(sizePx / 2f, sizePx / 2f, radius, paint)
        return bitmap
    }

    private var transparentBitmapCache: Bitmap? = null

    private fun transparentBitmap(): Bitmap {
        transparentBitmapCache?.let { return it }
        return Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888).also {
            transparentBitmapCache = it
        }
    }

    private fun withAlpha(color: Int, alphaFraction: Float): Int {
        val alpha = (alphaFraction.coerceIn(0f, 1f) * 255).toInt()
        return Color.argb(alpha, Color.red(color), Color.green(color), Color.blue(color))
    }

    private fun resolveHeatFillColor(themeColorArgb: Int, intensity: Int): Int {
        val mixFraction = when (intensity.coerceIn(1, 6)) {
            6 -> 0.94f
            5 -> 0.84f
            4 -> 0.72f
            3 -> 0.58f
            2 -> 0.42f
            else -> 0.26f
        }
        return blendColors(Color.WHITE, themeColorArgb, mixFraction)
    }

    private fun isDarkEnoughForLightText(color: Int): Boolean {
        val brightness =
            Color.red(color) * 0.299 +
                Color.green(color) * 0.587 +
                Color.blue(color) * 0.114
        return brightness < 165
    }

    private fun blendColors(baseColor: Int, overlayColor: Int, overlayFraction: Float): Int {
        val fraction = overlayFraction.coerceIn(0f, 1f)
        val inverse = 1f - fraction
        return Color.argb(
            255,
            (Color.red(baseColor) * inverse + Color.red(overlayColor) * fraction).toInt(),
            (Color.green(baseColor) * inverse + Color.green(overlayColor) * fraction).toInt(),
            (Color.blue(baseColor) * inverse + Color.blue(overlayColor) * fraction).toInt(),
        )
    }
}
