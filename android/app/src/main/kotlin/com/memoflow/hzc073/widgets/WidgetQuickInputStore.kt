package com.memoflow.hzc073.widgets

import android.content.Context
import com.memoflow.hzc073.R

private const val QUICK_INPUT_PREFS = "memoflow_widget_quick_input"
private const val KEY_HINT = "hint"

object WidgetQuickInputStore {
    fun save(context: Context, hint: String) {
        val resolvedHint = hint.trim().ifEmpty { context.getString(R.string.widget_quick_input_hint) }
        context.getSharedPreferences(QUICK_INPUT_PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_HINT, resolvedHint)
            .apply()
    }

    fun loadHint(context: Context): String {
        return context.getSharedPreferences(QUICK_INPUT_PREFS, Context.MODE_PRIVATE)
            .getString(KEY_HINT, null)
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?: context.getString(R.string.widget_quick_input_hint)
    }

    fun clear(context: Context) {
        context.getSharedPreferences(QUICK_INPUT_PREFS, Context.MODE_PRIVATE)
            .edit()
            .clear()
            .apply()
    }
}
