package com.lingufranca.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PracticeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.practice_widget)
            val title = widgetData.getString("practice_title", "Gunluk Pratik")
            val subtitle = widgetData.getString("practice_subtitle", "Serini koru")
            val streak = widgetData.getInt("practice_streak", 0)
            val xp = widgetData.getInt("practice_xp", 0)
            val hearts = widgetData.getInt("practice_hearts", 5)

            views.setTextViewText(R.id.practice_widget_title, title)
            views.setTextViewText(R.id.practice_widget_subtitle, subtitle)
            views.setTextViewText(R.id.practice_widget_streak, "$streak")
            views.setTextViewText(R.id.practice_widget_xp, "$xp XP")
            views.setTextViewText(R.id.practice_widget_hearts, "$hearts")

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
