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

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.support.v4.app.Fragment
import android.support.v7.app.AppCompatActivity
import android.view.Gravity
import android.view.MenuItem
import kotlinx.android.synthetic.main.activity_main.*

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        val preferences = getSharedPreferences("sigaa.sync", Context.MODE_PRIVATE)
        if (preferences.getBoolean("darkTheme", false)) {
            setTheme(R.style.AppThemeDark_NoActionBar)
        } else {
            setTheme(R.style.AppTheme_NoActionBar)
        }

        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        setSupportActionBar(toolbar)

        val sharedPreferences = getSharedPreferences("sigaa.login", Context.MODE_PRIVATE)
        val username = sharedPreferences.getString("username", "") ?: ""
        val password = sharedPreferences.getString("password", "") ?: ""

        if (username.isEmpty() || password.isEmpty()) {
            val intent = Intent(this, LoginActivity::class.java)
            startActivity(intent)
            return
        }

        supportActionBar?.apply {
            setDisplayHomeAsUpEnabled(true)
            setHomeAsUpIndicator(R.drawable.ic_menu_white_24dp)
        }

        nav_view.setNavigationItemSelectedListener {
            when (it.itemId) {
                R.id.grades -> {
                    title = getString(R.string.notas)
                    setFragment(GradesFragment())
                }

                R.id.schedule -> {
                    title = getString(R.string.horarios)
                    setFragment(ScheduleFragment())
                }

                R.id.settings -> {
                    title = getString(R.string.settings)
                    setFragment(SettingsFragment())
                }

                R.id.about -> {
                    title = getString(R.string.about)
                    setFragment(AboutFragment())
                }

                R.id.logout -> {
                    with(sharedPreferences.edit()) {
                        remove("username")
                        remove("password")
                        remove("grades")
                        remove("schedules")
                        apply()
                    }

                    val preferences = getSharedPreferences("sigaa.sync", Context.MODE_PRIVATE)
                    with(preferences.edit()) {
                        remove("grades")
                        remove("schedules")
                        remove("notify")
                        apply()
                    }

                    val intent = Intent(this, LoginActivity::class.java)
                    startActivity(intent)
                }

                else -> {
                }
            }

            drawer_layout.closeDrawer(Gravity.START)
            true
        }

        when (intent?.getStringExtra("fragment")) {
            "schedules" -> setFragment(ScheduleFragment())
            "settings" -> setFragment(SettingsFragment())
            else -> setFragment(GradesFragment())
        }

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager?
        notificationManager?.cancelAll()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = getString(R.string.channel_name)
            val description = getString(R.string.channel_description)
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel("sigaa", name, importance)
            channel.description = description
            notificationManager?.createNotificationChannel(channel)
        }

        AlarmReceiver.setAlarm(this)
    }

    override fun onOptionsItemSelected(item: MenuItem?): Boolean {
        return when (item?.itemId) {
            android.R.id.home -> {
                drawer_layout.openDrawer(Gravity.START)
                true
            }

            else -> super.onOptionsItemSelected(item)
        }
    }

    private fun setFragment(fragment: Fragment) {
        val transaction = supportFragmentManager.beginTransaction()
        supportFragmentManager.fragments.forEach {
            transaction.remove(it)
        }
        transaction.add(R.id.content_frame, fragment)
        transaction.commit()
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        supportFragmentManager.fragments.forEach {
            it.onRequestPermissionsResult(requestCode, permissions, grantResults)
        }
    }
}
