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

import android.Manifest
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.provider.CalendarContract
import android.support.v4.app.ActivityCompat
import android.support.v4.app.Fragment
import android.support.v4.content.ContextCompat
import android.support.v7.app.AlertDialog
import android.support.v7.widget.DividerItemDecoration
import android.support.v7.widget.LinearLayoutManager
import android.view.*
import android.widget.Toast
import com.google.gson.GsonBuilder
import kotlinx.android.synthetic.main.fragment_schedule.*
import kotlinx.coroutines.runBlocking
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
        setHasOptionsMenu(true)

        val context = activity ?: return

        val drawable = ContextCompat.getDrawable(context, R.drawable.divider)
        val itemDecor = DividerItemDecoration(context, DividerItemDecoration.VERTICAL)
        if (drawable != null) {
            itemDecor.setDrawable(drawable)
        }

        swipe.setOnRefreshListener {
            update()
        }

        todayScheduleViewAdapter.today = true

        todayRecyclerView.apply {
            adapter = todayScheduleViewAdapter
            layoutManager = LinearLayoutManager(activity)
            addItemDecoration(itemDecor)
        }

        mondayRecyclerView.apply {
            adapter = mondayScheduleViewAdapter
            layoutManager = LinearLayoutManager(activity)
            addItemDecoration(itemDecor)
        }

        tuesdayRecyclerView.apply {
            adapter = tuesdayScheduleViewAdapter
            layoutManager = LinearLayoutManager(activity)
            addItemDecoration(itemDecor)
        }

        wednesdayRecyclerView.apply {
            adapter = wednesdayScheduleViewAdapter
            layoutManager = LinearLayoutManager(activity)
            addItemDecoration(itemDecor)
        }

        thursdayRecyclerView.apply {
            adapter = thursdayScheduleViewAdapter
            layoutManager = LinearLayoutManager(activity)
            addItemDecoration(itemDecor)
        }

        fridayRecyclerView.apply {
            adapter = fridayScheduleViewAdapter
            layoutManager = LinearLayoutManager(activity)
            addItemDecoration(itemDecor)
        }

        val loginPreferences = activity?.getSharedPreferences("sigaa.login", Context.MODE_PRIVATE)
        val schedulesJson = loginPreferences?.getString("schedules", "[]") ?: "[]"
        val schedules = tryOrDefault(arrayOf()) {
            GsonBuilder().create().fromJson(schedulesJson, Array<Schedule>::class.java)
        }?.toList() ?: listOf()

        setSchedules(schedules)

        if (schedules.isEmpty()) {
            update()
        }
    }

    private fun update() {
        activity?.runOnUiThread {
            swipe.isRefreshing = true
        }

        thread(start = true) {
            try {
                runBlocking {
                    val loginPreferences = activity?.getSharedPreferences("sigaa.login", Context.MODE_PRIVATE)
                    val username = loginPreferences?.getString("username", "") ?: ""
                    val password = loginPreferences?.getString("password", "") ?: ""
                    val schedules = SIGAA(username, password).schedules()

                    activity?.runOnUiThread {
                        swipe.isRefreshing = false
                    }

                    if (loginPreferences != null && schedules.isNotEmpty()) {
                        val json = GsonBuilder().create().toJson(schedules) ?: "[]"
                        with(loginPreferences.edit()) {
                            putString("schedules", json)
                            apply()
                        }

                        setSchedules(schedules)
                    }
                }
            } catch (_: Throwable) {
                activity?.runOnUiThread {
                    swipe.isRefreshing = false
                    Toast.makeText(activity, "Ocorreu um erro durante a atualização", Toast.LENGTH_LONG).show()
                }
            }
        }
    }

    private fun setSchedules(schedules: List<Schedule>) {
        activity?.runOnUiThread {
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

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        if ((grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)) {
            addToCalendar()
        }
    }

    override fun onCreateOptionsMenu(menu: Menu?, inflater: MenuInflater?) {
        inflater?.inflate(R.menu.schedule, menu)
        super.onCreateOptionsMenu(menu, inflater)
    }

    override fun onOptionsItemSelected(item: MenuItem?): Boolean {
        return when (item?.itemId) {
            R.id.addToCalendar -> {
                addToCalendar()
                true
            }

            else -> super.onOptionsItemSelected(item)
        }
    }

    private fun addToCalendar() {
        val context = activity ?: return

        try {
            val wp = ContextCompat.checkSelfPermission(context, Manifest.permission.WRITE_CALENDAR)
            val rp = ContextCompat.checkSelfPermission(context, Manifest.permission.READ_CALENDAR)
            if (wp != PackageManager.PERMISSION_GRANTED || rp != PackageManager.PERMISSION_GRANTED) {
                val permissions = arrayOf(
                        Manifest.permission.WRITE_CALENDAR,
                        Manifest.permission.READ_CALENDAR
                )
                ActivityCompat.requestPermissions(context, permissions, 0)
                return
            }
        } catch (_: Throwable) {
            Toast.makeText(context, "Não possui permissão de acesso ao calendário", Toast.LENGTH_LONG).show()
            return
        }

        val cr = context.contentResolver
        val projection = arrayOf("_id", "calendar_displayName")
        val calendars = Uri.parse("content://com.android.calendar/calendars")
        val cs = mutableListOf<List<String>>()

        try {
            cr?.query(calendars, projection, null, null, null)?.use {
                if (it.moveToFirst()) {
                    while (it.moveToNext()) {
                        val calID = it.getString(it.getColumnIndex(projection[0]))
                        val calName = it.getString(it.getColumnIndex(projection[1]))
                        cs.add(listOf(calID, calName))
                    }
                }
            }
        } catch (_: Throwable) {
            Toast.makeText(context, "Ocorreu um erro ao listar os calendários", Toast.LENGTH_LONG).show()
            return
        }

        AlertDialog.Builder(context)
                .setTitle("Selecione um calendário: ")
                .setNegativeButton(R.string.cancel) { dialog, _ -> dialog.dismiss() }
                .setItems(cs.map { it.last() }.toTypedArray()) { _, i ->
                    swipe.isRefreshing = true
                    Toast.makeText(context, "Adicionando eventos...", Toast.LENGTH_LONG).show()

                    val calId = cs[i].first().toInt()

                    val loginPreferences = context.getSharedPreferences("sigaa.login", Context.MODE_PRIVATE)
                    val username = loginPreferences?.getString("username", "") ?: ""
                    val password = loginPreferences?.getString("password", "") ?: ""
                    val schedulesJson = loginPreferences?.getString("schedules", "[]") ?: "[]"
                    val schedules = tryOrDefault(arrayOf()) {
                        GsonBuilder().create().fromJson(schedulesJson, Array<Schedule>::class.java)
                    }?.toList() ?: listOf()

                    thread(start = true) {
                        try {
                            runBlocking {
                                val startAndEnd = SIGAA(username, password).startAndEndOfSemester()
                                val startSemester = startAndEnd.first()
                                val endSemester = startAndEnd.last()

                                for (schedule in schedules) {
                                    val startTime = startSemester.clone() as Calendar
                                    val endTime = startSemester.clone() as Calendar

                                    startTime.set(Calendar.HOUR, schedule.start.split(":").first().toInt())
                                    startTime.set(Calendar.MINUTE, schedule.start.split(":").last().toInt())
                                    startTime.set(Calendar.AM_PM, 0)
                                    startTime.add(Calendar.DAY_OF_MONTH, (7 + schedule.day - startSemester.get(Calendar.DAY_OF_WEEK)) % 7)

                                    endTime.set(Calendar.HOUR, schedule.end.split(":").first().toInt())
                                    endTime.set(Calendar.MINUTE, schedule.end.split(":").last().toInt())
                                    endTime.set(Calendar.AM_PM, 0)
                                    endTime.add(Calendar.DAY_OF_MONTH, (7 + schedule.day - startSemester.get(Calendar.DAY_OF_WEEK)) % 7)

                                    val repetition = endSemester.get(Calendar.WEEK_OF_YEAR) - startSemester.get(Calendar.WEEK_OF_YEAR)

                                    val values = ContentValues()
                                    values.put(CalendarContract.Events.ALL_DAY, false)
                                    values.put(CalendarContract.Events.DTSTART, startTime.timeInMillis)
                                    values.put(CalendarContract.Events.DTEND, endTime.timeInMillis)
                                    values.put(CalendarContract.Events.TITLE, schedule.course)
                                    values.put(CalendarContract.Events.DESCRIPTION, "Aula")
                                    values.put(CalendarContract.Events.EVENT_LOCATION, schedule.local)
                                    values.put(CalendarContract.Events.CALENDAR_ID, calId)
                                    values.put(CalendarContract.Events.EVENT_TIMEZONE, startTime.timeZone.displayName)
                                    values.put(CalendarContract.Events.RRULE, "FREQ=WEEKLY;COUNT=$repetition")

                                    cr.insert(CalendarContract.Events.CONTENT_URI, values)
                                }

                                val builder = CalendarContract.CONTENT_URI.buildUpon()
                                builder.appendPath("time")
                                ContentUris.appendId(builder, Calendar.getInstance().timeInMillis)
                                val intent = Intent(Intent.ACTION_VIEW).setData(builder.build())

                                context.runOnUiThread {
                                    swipe.isRefreshing = false
                                    startActivity(intent)
                                }
                            }
                        } catch (_: Throwable) {
                            context.runOnUiThread {
                                swipe.isRefreshing = false
                                Toast.makeText(context, "Ocorreu um erro durante a atualização", Toast.LENGTH_LONG).show()
                            }
                        }
                    }
                }
                .create()
                .show()
    }
}
