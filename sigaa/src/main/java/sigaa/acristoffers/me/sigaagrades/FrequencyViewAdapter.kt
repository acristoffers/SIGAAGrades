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

object FrequencyViewAdapter : RecyclerView.Adapter<FrequencyViewAdapter.FrequencyViewHolder>() {
    var frequencies: List<SIGAA.Frequency> = listOf()

    override fun onCreateViewHolder(viewGroup: ViewGroup, p1: Int): FrequencyViewHolder {
        val view = LayoutInflater.from(viewGroup.context).inflate(R.layout.frequency, viewGroup, false)
        return FrequencyViewHolder(view)
    }

    override fun getItemCount(): Int = frequencies.size

    override fun onBindViewHolder(holder: FrequencyViewHolder, pos: Int) {
        val f = frequencies[pos]
        val absences = 100 * (f.givenClasses - f.frequency).toDouble()

        holder.apply {
            courseName.text = f.course
            frequency.text = f.frequency.toString()
            given.text = f.givenClasses.toString()
            total.text = f.totalClasses.toString()
            frequencyPC.text = "%.0f%%".format(Math.ceil(absences / f.givenClasses))
            frequencyPCTotal.text = "%.0f%%".format(Math.ceil(absences / f.totalClasses))
        }
    }

    class FrequencyViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val courseName: TextView = itemView.findViewById(R.id.course)
        val frequency: TextView = itemView.findViewById(R.id.frequency)
        val given: TextView = itemView.findViewById(R.id.givenClasses)
        val total: TextView = itemView.findViewById(R.id.totalClasses)
        val frequencyPC: TextView = itemView.findViewById(R.id.frequencyPC)
        val frequencyPCTotal: TextView = itemView.findViewById(R.id.frequencyPCTotal)
    }
}
