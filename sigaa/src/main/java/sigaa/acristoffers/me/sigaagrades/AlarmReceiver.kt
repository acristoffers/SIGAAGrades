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

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context != null) {
            if (intent?.action == "android.intent.action.BOOT_COMPLETED") {
                AlarmReceiver.setAlarm(context)
            }

            AlarmService.enqueueWork(context)
        }
    }

    companion object {
        fun setAlarm(context: Context) {
            val preferences = context.getSharedPreferences("sigaa.sync", Context.MODE_PRIVATE)
            val syncGrades = preferences?.getBoolean("grades", false) ?: false
            val syncSchedules = preferences?.getBoolean("schedules", false) ?: false
            val interval = tryOrDefault(60L) {
                preferences?.getString("interval", "60")?.toLong() ?: 60L
            } * 60 * 1000

            val alarmIntent = Intent(context, AlarmReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(context, 0, alarmIntent, PendingIntent.FLAG_UPDATE_CURRENT)
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager?

            if (syncGrades || syncSchedules) {
                alarmManager?.setRepeating(AlarmManager.ELAPSED_REALTIME_WAKEUP, 0, interval, pendingIntent)
            } else {
                alarmManager?.cancel(pendingIntent)
            }
        }
    }
}
