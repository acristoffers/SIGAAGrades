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
import android.content.Intent
import android.os.Bundle
import android.support.v7.app.AppCompatActivity
import kotlinx.android.synthetic.main.activity_login.*

class LoginActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_login)

        val sharedPreferences = getSharedPreferences("sigaa.login", Context.MODE_PRIVATE)
        val username = sharedPreferences.getString("username", "")!!
        val password = sharedPreferences.getString("password", "")!!

        this.username.setText(username)
        this.password.setText(password)

        this.sign_in.setOnClickListener {
            val newUsername = this.username.text.toString()
            val newPassword = this.password.text.toString()

            with(sharedPreferences.edit()) {
                putString("username", newUsername)
                putString("password", newPassword)
                apply()
            }

            val preferences = getSharedPreferences("sigaa.sync", Context.MODE_PRIVATE)
            with(preferences.edit()) {
                putBoolean("grades",true)
                putBoolean("schedules",true)
                putBoolean("notify",true)
                apply()
            }

            val intent = Intent(this, MainActivity::class.java)
            startActivity(intent)
        }
    }
}
