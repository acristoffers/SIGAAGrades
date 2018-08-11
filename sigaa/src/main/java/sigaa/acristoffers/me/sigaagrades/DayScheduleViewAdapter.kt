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

import android.support.v7.widget.RecyclerView
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import java.util.*

class DayScheduleViewAdapter(val day: Int) : RecyclerView.Adapter<DayScheduleViewAdapter.TodayViewHolder>() {
    var schedules: List<SIGAA.Schedule> = listOf()
    var today = false

    override fun onCreateViewHolder(viewGroup: ViewGroup, p1: Int): TodayViewHolder {
        val v = LayoutInflater.from(viewGroup.context).inflate(R.layout.schedule_day, viewGroup, false)
        return TodayViewHolder(v)
    }

    override fun getItemCount(): Int {
        return filteredSchedules().size
    }

    override fun onBindViewHolder(holder: TodayViewHolder, pos: Int) {
        val todaySchedules = filteredSchedules()
                .sortedWith(compareBy(SIGAA.Schedule::shift, { tryOrDefault(0) { it.start.split(":").first().toInt() } }))

        holder.apply {
            course.text = todaySchedules[pos].course
            interval.text = holder.itemView.context.getString(R.string.day_schedule_date_local,
                    todaySchedules[pos].start,
                    todaySchedules[pos].end,
                    todaySchedules[pos].local)
        }
    }

    private fun filteredSchedules(): List<SIGAA.Schedule> {
        return if (today) {
            val now = Calendar.getInstance()
            val l = { it: SIGAA.Schedule, i: Int -> tryOrDefault(0) { it.end.split(":")[i].toInt() } }
            schedules.filter {
                val cal = Calendar.getInstance()
                cal.set(Calendar.AM_PM, 0)
                cal.set(Calendar.HOUR_OF_DAY, l(it, 0))
                cal.set(Calendar.MINUTE, l(it, 1))
                it.day == day && now <= cal
            }
        } else {
            schedules.filter { it.day == day }
        }
    }

    class TodayViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val course: TextView = itemView.findViewById(R.id.course)
        val interval: TextView = itemView.findViewById(R.id.interval)
    }
}
