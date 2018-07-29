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
import android.widget.Toast
import com.google.gson.GsonBuilder
import kotlinx.android.synthetic.main.fragment_grades.*
import kotlin.concurrent.thread

class GradesFragment : Fragment() {
    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        return inflater.inflate(R.layout.fragment_grades, container, false)
    }

    override fun onActivityCreated(savedInstanceState: Bundle?) {
        super.onActivityCreated(savedInstanceState)

        swipe.setOnRefreshListener {
            update()
        }

        val sharedPreferences = activity?.getSharedPreferences("sigaa.login", Context.MODE_PRIVATE)
        val coursesJson = sharedPreferences?.getString("grades", "[]") ?: "[]"
        val courses = GsonBuilder().create().fromJson(coursesJson, Array<SIGAA.Course>::class.java)
        setGrades(courses.toList())

        recyclerView.apply {
            adapter = CourseViewAdapter
            layoutManager = LinearLayoutManager(activity)
        }

        if (courses.isEmpty()) {
            update()
        }
    }

    private fun update() {
        swipe.isRefreshing = true

        val sharedPreferences = activity?.getSharedPreferences("sigaa.login", Context.MODE_PRIVATE)
        val username = sharedPreferences?.getString("username", "") ?: ""
        val password = sharedPreferences?.getString("password", "") ?: ""

        thread(start = true) {
            val grades: MutableList<SIGAA.Course> = mutableListOf()
            try {
                SIGAA(username, password).listGrades().doOnComplete {
                    activity?.runOnUiThread {
                        this.swipe.isRefreshing = false

                        if (sharedPreferences != null) {
                            val json = GsonBuilder().create().toJson(grades) ?: "[]"
                            with(sharedPreferences.edit()) {
                                putString("grades", json)
                                apply()
                            }
                        }
                    }
                }.subscribe {
                    grades.add(it)

                    activity?.runOnUiThread {
                        setGrades(grades)
                    }
                }
            } catch (_: Throwable) {
                activity?.runOnUiThread {
                    this.swipe.isRefreshing = false
                    Toast.makeText(activity, "Ocorreu um erro durante a atualização", Toast.LENGTH_LONG).show()
                }
            }
        }
    }

    private fun setGrades(grades: List<SIGAA.Course>) {
        CourseViewAdapter.courses = grades.sortedBy { it.name }
        CourseViewAdapter.notifyDataSetChanged()
        emptyView.visibility = if (grades.isEmpty()) View.VISIBLE else View.GONE
    }
}
