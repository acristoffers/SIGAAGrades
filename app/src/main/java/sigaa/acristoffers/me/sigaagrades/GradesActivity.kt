package sigaa.acristoffers.me.sigaagrades

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.support.v7.app.AppCompatActivity
import android.support.v7.widget.LinearLayoutManager
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.widget.Toast
import kotlinx.android.synthetic.main.activity_main.*
import kotlin.concurrent.thread

class GradesActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        this.swipe.setOnRefreshListener {
            update()
        }

        val sharedPreferences = getSharedPreferences("sigaa.login", Context.MODE_PRIVATE)
        val username = sharedPreferences.getString("username", "")!!
        val password = sharedPreferences.getString("password", "")!!

        if (username.isEmpty() || password.isEmpty()) {
            val intent = Intent(this, LoginActivity::class.java)
            startActivity(intent)
            return
        }

        this.recyclerView.apply {
            adapter = CourseViewAdapter
            layoutManager = LinearLayoutManager(this@GradesActivity)
        }

        update()
    }

    private fun update() {
        this.swipe.isRefreshing = true

        setGrades(listOf())

        val sharedPreferences = getSharedPreferences("sigaa.login", Context.MODE_PRIVATE)
        val username = sharedPreferences.getString("username", "")!!
        val password = sharedPreferences.getString("password", "")!!

        thread(start = true) {
            val grades: MutableList<SIGAA.Course> = mutableListOf()
            try {
                val sigaa = SIGAA(username, password)
                sigaa.listGrades().doOnComplete {
                    runOnUiThread {
                        this.swipe.isRefreshing = false
                    }
                }.subscribe {
                    grades.add(it)

                    runOnUiThread {
                        setGrades(grades)
                    }
                }
            } catch (_: Throwable) {
                runOnUiThread {
                    this.swipe.isRefreshing = false
                    Toast.makeText(this, "Ocorreu um erro durante a atualização", Toast.LENGTH_LONG).show()
                }
            }
        }
    }

    private fun setGrades(grades: List<SIGAA.Course>) {
        CourseViewAdapter.courses = grades
        CourseViewAdapter.notifyDataSetChanged()
        emptyView.visibility = if (grades.isEmpty()) View.VISIBLE else View.GONE
    }

    override fun onCreateOptionsMenu(menu: Menu?): Boolean {
        menuInflater.inflate(R.menu.main, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem?): Boolean {
        when (item?.itemId) {
            R.id.reload -> {
                update()
                return true
            }

            R.id.logout -> {
                val sharedPreferences = getSharedPreferences("sigaa.login", Context.MODE_PRIVATE)
                with(sharedPreferences.edit()) {
                    remove("username")
                    remove("password")
                    apply()
                }

                val intent = Intent(this, LoginActivity::class.java)
                startActivity(intent)

                return true
            }

            R.id.about -> {
                val intent = Intent(this, AboutActivity::class.java)
                startActivity(intent)

                return true
            }

            else -> return super.onOptionsItemSelected(item)
        }
    }
}
