/*
 * Copyright (c) 2018 Álan Crístoffer
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package sigaa.acristoffers.me.sigaagrades

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.support.v4.app.JobIntentService
import android.support.v4.app.NotificationCompat
import com.google.gson.GsonBuilder
import kotlinx.coroutines.experimental.runBlocking

class AlarmService : JobIntentService() {
    override fun onHandleWork(intent: Intent) {
        val context = applicationContext
        val preferences = context.getSharedPreferences("sigaa.sync", Context.MODE_PRIVATE)
        val syncGrades = preferences?.getBoolean("grades", true) ?: true
        val syncSchedules = preferences?.getBoolean("schedules", true) ?: true
        val notify = preferences?.getBoolean("notify", true) ?: true

        if (syncGrades) {
            syncGrades(context, notify)
        }

        if (syncSchedules) {
            syncSchedules(context, notify)
        }
    }

    private fun syncGrades(context: Context, notify: Boolean) {
        try {
            runBlocking {
                val preferences = context.getSharedPreferences("sigaa.login", Context.MODE_PRIVATE)
                val username = preferences.getString("username", "") ?: ""
                val password = preferences.getString("password", "") ?: ""

                val oldJson = preferences.getString("grades", "[]") ?: "[]"
                val oldGrades = GsonBuilder().create().fromJson(oldJson, Array<SIGAA.Course>::class.java)

                val grades = SIGAA(username, password).listGrades()

                val orderedOldGrades = oldGrades.sortedBy { it.name }
                val orderedNewGrade = grades.sortedBy { it.name }

                if (orderedNewGrade != orderedOldGrades) {
                    val json = GsonBuilder().create().toJson(grades) ?: "[]"
                    with(preferences.edit()) {
                        putString("grades", json)
                        apply()
                    }

                    if (notify) {
                        val title = context.getString(R.string.notification_grades_title)
                        val text = context.getString(R.string.notification_grades_text)
                        showNotification(context, "grades", title, text)
                    }
                }
            }
        } catch (t: Throwable) {
            t.printStackTrace()
        }
    }

    private fun syncSchedules(context: Context, notify: Boolean) {
        try {
            val preferences = context.getSharedPreferences("sigaa.login", Context.MODE_PRIVATE)
            val username = preferences.getString("username", "") ?: ""
            val password = preferences.getString("password", "") ?: ""

            val oldJson = preferences.getString("schedules", "[]") ?: "[]"
            val oldSchedules = GsonBuilder().create().fromJson(oldJson, Array<SIGAA.Schedule>::class.java)

            val schedules = SIGAA(username, password).listSchedules()

            val orderedOldSchedules = oldSchedules.sortedWith(compareBy(SIGAA.Schedule::day, { it.start.split(":").first().toInt() }))
            val orderedNewSchedules = schedules.sortedWith(compareBy(SIGAA.Schedule::day, { it.start.split(":").first().toInt() }))

            if (orderedNewSchedules != orderedOldSchedules) {
                val json = GsonBuilder().create().toJson(schedules) ?: "[]"
                with(preferences.edit()) {
                    putString("schedules", json)
                    apply()
                }

                if (notify) {
                    val title = context.getString(R.string.notification_schedules_title)
                    val text = context.getString(R.string.notification_schedules_text)
                    showNotification(context, "schedules", title, text)
                }
            }
        } catch (t: Throwable) {
            t.printStackTrace()
        }
    }

    private fun showNotification(context: Context, extra: String, title: String, text: String) {
        val intent = Intent(context, MainActivity::class.java)
        intent.putExtra("fragment", extra)
        val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT)

        val icon = BitmapFactory.decodeResource(context.resources, R.mipmap.ic_launcher)

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager?
        val notification = NotificationCompat.Builder(context, "sigaa")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(text)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setDefaults(Notification.DEFAULT_LIGHTS or Notification.DEFAULT_SOUND or Notification.DEFAULT_VIBRATE)
                .setContentIntent(pendingIntent)
                .setLargeIcon(icon)
                .setWhen(System.currentTimeMillis())
                .setAutoCancel(true)
                .build()
        notificationManager?.notify(0, notification)
    }

    companion object {
        fun enqueueWork(context: Context) {
            enqueueWork(context, AlarmService::class.java, 0, Intent())
        }
    }
}
