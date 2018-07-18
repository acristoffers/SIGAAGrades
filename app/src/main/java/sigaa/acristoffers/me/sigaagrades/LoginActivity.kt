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

            val intent = Intent(this, MainActivity::class.java)
            startActivity(intent)
        }
    }
}
