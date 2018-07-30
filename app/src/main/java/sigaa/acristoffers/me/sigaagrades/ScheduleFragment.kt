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

import android.content.Context
import android.os.Bundle
import android.support.v4.app.Fragment
import android.support.v7.widget.LinearLayoutManager
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import com.google.gson.GsonBuilder
import kotlinx.android.synthetic.main.fragment_schedule.*
import java.util.*
import kotlin.concurrent.thread

class ScheduleFragment : Fragment() {
    private val todayScheduleViewAdapter = DayScheduleViewAdapter(Calendar.getInstance().get(Calendar.DAY_OF_WEEK))
    private val mondayScheduleViewAdapter = DayScheduleViewAdapter(2)
    private val tuesdayScheduleViewAdapter = DayScheduleViewAdapter(3)
    private val wednesdayScheduleViewAdapter = DayScheduleViewAdapter(4)
    private val thursdayScheduleViewAdapter = DayScheduleViewAdapter(5)
    private val fridayScheduleViewAdapter = DayScheduleViewAdapter(6)

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        return inflater.inflate(R.layout.fragment_schedule, container, false)
    }

    override fun onActivityCreated(savedInstanceState: Bundle?) {
        super.onActivityCreated(savedInstanceState)

        swipe.setOnRefreshListener {
            update()
        }

        todayRecyclerView.apply {
            adapter = todayScheduleViewAdapter
            layoutManager = LinearLayoutManager(activity)
        }

        mondayRecyclerView.apply {
            adapter = mondayScheduleViewAdapter
            layoutManager = LinearLayoutManager(activity)
        }

        tuesdayRecyclerView.apply {
            adapter = tuesdayScheduleViewAdapter
            layoutManager = LinearLayoutManager(activity)
        }

        wednesdayRecyclerView.apply {
            adapter = wednesdayScheduleViewAdapter
            layoutManager = LinearLayoutManager(activity)
        }

        thursdayRecyclerView.apply {
            adapter = thursdayScheduleViewAdapter
            layoutManager = LinearLayoutManager(activity)
        }

        fridayRecyclerView.apply {
            adapter = fridayScheduleViewAdapter
            layoutManager = LinearLayoutManager(activity)
        }

        val sharedPreferences = activity?.getSharedPreferences("sigaa.login", Context.MODE_PRIVATE)
        val schedulesJson = sharedPreferences?.getString("schedules", "[]") ?: "[]"
        val schedules = GsonBuilder()
                .create()
                .fromJson(schedulesJson, Array<SIGAA.Schedule>::class.java) ?: arrayOf()
        setSchedules(schedules.toList())

        if (schedules.isEmpty()) {
            update()
        }
    }

    private fun update() {
        swipe.isRefreshing = true

        val sharedPreferences = activity?.getSharedPreferences("sigaa.login", Context.MODE_PRIVATE)
        val username = sharedPreferences?.getString("username", "") ?: ""
        val password = sharedPreferences?.getString("password", "") ?: ""

        thread(start = true) {
            val schedules = SIGAA(username, password).listSchedules()
            if (sharedPreferences != null && schedules.isNotEmpty()) {
                val json = GsonBuilder().create().toJson(schedules) ?: "[]"
                with(sharedPreferences.edit()) {
                    putString("schedules", json)
                    apply()
                }
            }

            activity?.runOnUiThread {
                swipe.isRefreshing = false
                setSchedules(schedules)
            }
        }
    }

    private fun setSchedules(schedules: List<SIGAA.Schedule>) {
        todayScheduleViewAdapter.schedules = schedules
        mondayScheduleViewAdapter.schedules = schedules
        tuesdayScheduleViewAdapter.schedules = schedules
        wednesdayScheduleViewAdapter.schedules = schedules
        thursdayScheduleViewAdapter.schedules = schedules
        fridayScheduleViewAdapter.schedules = schedules

        todayScheduleViewAdapter.notifyDataSetChanged()
        mondayScheduleViewAdapter.notifyDataSetChanged()
        tuesdayScheduleViewAdapter.notifyDataSetChanged()
        wednesdayScheduleViewAdapter.notifyDataSetChanged()
        thursdayScheduleViewAdapter.notifyDataSetChanged()
        fridayScheduleViewAdapter.notifyDataSetChanged()
    }
}
