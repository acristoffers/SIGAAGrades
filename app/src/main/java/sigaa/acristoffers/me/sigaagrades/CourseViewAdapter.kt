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

import android.support.v7.widget.LinearLayoutManager
import android.support.v7.widget.RecyclerView
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView

object CourseViewAdapter : RecyclerView.Adapter<CourseViewAdapter.CourseViewHolder>() {
    var courses: List<SIGAA.Course> = listOf()

    override fun onCreateViewHolder(viewGroup: ViewGroup, p1: Int): CourseViewHolder {
        val v = LayoutInflater.from(viewGroup.context).inflate(R.layout.card, viewGroup, false)
        val holder = CourseViewHolder(v)

        holder.gradesList.apply {
            adapter = GradeViewAdapter()
            layoutManager = LinearLayoutManager(viewGroup.context)
        }

        return holder
    }

    override fun getItemCount(): Int {
        return courses.size
    }

    override fun onBindViewHolder(holder: CourseViewHolder, pos: Int) {
        holder.apply {
            val course = courses[pos]
            courseName.text = course.name
            val gradeAdapter = gradesList.adapter as GradeViewAdapter
            gradeAdapter.grades = course.grades
            gradeAdapter.notifyDataSetChanged()
            if (course.grades.isEmpty()) {
                total.text = "0"
            } else {
                total.text = course.grades
                        .map { it.score.replace(",", ".").trim().toFloat() }
                        .reduce { a, b -> a + b }
                        .toString()

            }
        }
    }

    class CourseViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val courseName: TextView = itemView.findViewById(R.id.courseName)
        val gradesList: RecyclerView = itemView.findViewById(R.id.grades)
        val total: TextView = itemView.findViewById(R.id.total)
        val totalRow: LinearLayout = itemView.findViewById(R.id.totalRow)
    }
}
