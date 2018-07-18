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
