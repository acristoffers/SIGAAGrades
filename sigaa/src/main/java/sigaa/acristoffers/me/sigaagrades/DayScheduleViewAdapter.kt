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

class DayScheduleViewAdapter(val day: Int) : RecyclerView.Adapter<DayScheduleViewAdapter.TodayViewHolder>() {
    var schedules: List<SIGAA.Schedule> = listOf()

    override fun onCreateViewHolder(viewGroup: ViewGroup, p1: Int): TodayViewHolder {
        val v = LayoutInflater.from(viewGroup.context).inflate(R.layout.schedule_day, viewGroup, false)
        return TodayViewHolder(v)
    }

    override fun getItemCount(): Int {
        return schedules.filter { it.day == day }.size
    }

    override fun onBindViewHolder(holder: TodayViewHolder, pos: Int) {
        val todaySchedules = schedules
                .filter { it.day == day }
                .sortedWith(compareBy(SIGAA.Schedule::shift, SIGAA.Schedule::start))

        holder.apply {
            course.text = todaySchedules[pos].course
            interval.text = "De ${todaySchedules[pos].start} até ${todaySchedules[pos].end}. Local: ${todaySchedules[pos].local}"
        }
    }

    class TodayViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val course: TextView = itemView.findViewById(R.id.course)
        val interval: TextView = itemView.findViewById(R.id.interval)
    }
}