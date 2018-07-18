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
        return if (courses.isNotEmpty()) {
            courses.size
        } else {
            1
        }
    }

    override fun onBindViewHolder(holder: CourseViewHolder, pos: Int) {
        if (courses.isNotEmpty()) {
            holder.apply {
                courseName.text = courses[pos].name
                val gradeAdapter = gradesList.adapter as GradeViewAdapter
                gradeAdapter.grades = courses[pos].grades
                gradeAdapter.notifyDataSetChanged()
                total.text = courses[pos].grades
                        .map { it.score.replace(",", ".").trim().toFloat() }
                        .reduce({ a, b -> a + b }).toString()
                totalRow.visibility = View.VISIBLE
            }
        } else {
            holder.apply {
                courseName.text = courseName.context.getString(R.string.loading)
                val gradeAdapter = gradesList.adapter as GradeViewAdapter
                gradeAdapter.grades = listOf()
                gradeAdapter.notifyDataSetChanged()
                totalRow.visibility = View.GONE
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
