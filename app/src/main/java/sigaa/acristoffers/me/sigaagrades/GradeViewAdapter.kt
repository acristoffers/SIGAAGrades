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
import android.widget.TableRow
import android.widget.TextView

class GradeViewAdapter : RecyclerView.Adapter<GradeViewAdapter.GradeViewHolder>() {
    var grades: List<SIGAA.Grade> = listOf()

    override fun onCreateViewHolder(viewGroup: ViewGroup, p1: Int): GradeViewHolder {
        val v = LayoutInflater.from(viewGroup.context).inflate(R.layout.grade, viewGroup, false)
        return GradeViewHolder(v)
    }

    override fun getItemCount(): Int {
        return grades.size
    }

    override fun onBindViewHolder(holder: GradeViewHolder, pos: Int) {
        holder.apply {
            name.text = grades[pos].testName
            total.text = grades[pos].worth
            score.text = grades[pos].score
            header.visibility = if (pos == 0) View.VISIBLE else View.GONE
        }
    }

    class GradeViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val name: TextView = itemView.findViewById(R.id.name)
        val total: TextView = itemView.findViewById(R.id.total)
        val score: TextView = itemView.findViewById(R.id.score)
        val header: TableRow = itemView.findViewById(R.id.header)
    }
}
