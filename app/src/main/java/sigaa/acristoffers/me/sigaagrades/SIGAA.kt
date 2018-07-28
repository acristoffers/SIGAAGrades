package sigaa.acristoffers.me.sigaagrades

import android.os.Build
import android.text.Html
import io.reactivex.Observable
import org.jsoup.Jsoup
import org.jsoup.nodes.Document
import org.jsoup.nodes.Element
import org.jsoup.select.Elements
import java.util.*
import kotlin.concurrent.thread

class SIGAA(private val username: String, private val password: String) {
    private val session = Session("https://sig.cefetmg.br")
    private val jsessionid: String
    private val inst: String

    init {
        val response = session.get("/sigaa/verTelaLogin.do")
        val regex = "/sigaa/logar\\.do;jsessionid=([0-9A-Z]+)\\.inst([0-9]+)\\?dispatch=logOn".toRegex()
        val match = regex.find(response)
        jsessionid = match?.groupValues?.get(1) ?: ""
        inst = match?.groupValues?.get(2) ?: ""
        login()
    }

    fun listGrades(): Observable<Course> {
        return Observable.create { emitter ->
            val courses = listCourses()
            courses.map {
                thread(start = true, priority = 1) {
                    try {
                        val sigaa = SIGAA(username, password)
                        val courseId = it["Data"]!!["idTurma"]!!
                        val courseGrades = sigaa.listGradesForCourse(courseId)
                        val course = Course.fromHashMap(it["CourseName"]!!["Value"]!!, courseGrades)
                        emitter.onNext(course)
                    } catch (_: Throwable) {
                    }
                }
            }.map { it.join() }
            emitter.onComplete()
        }
    }

    private fun listGradesForCourse(course_id: String): List<Map<String, String>> {
        try {
            val courses = listCourses()
            val course = courses.first { it["Data"]!!["idTurma"] == course_id }
            val html = session.post("/sigaa/portais/discente/discente.jsf", course["Data"]!!)
            val root = html2AST(html)

            val viewState = find(root, "input[name='javax.faces.ViewState']").first().`val`()
            val data2 = hashMapOf("javax.faces.ViewState" to viewState)

            try {
                val link = find(root, "div:contains(Ver Notas)").last().parent().attr("onclick")
                val regex = "formMenu:j_id_jsp_([0-9_]+)".toRegex()
                val m = regex.find(link)?.groupValues?.get(1) ?: ""
                val regex2 = "PanelBar\\('formMenu:j_id_jsp_([0-9_]+)".toRegex()
                val m2 = regex2.find(html)?.groupValues?.get(1) ?: ""
                data2["formMenu"] = "formMenu"
                data2["formMenu:j_id_jsp_$m2"] = "formMenu:j_id_jsp_$m2"
                data2["formMenu:j_id_jsp_$m"] = "formMenu:j_id_jsp_$m"
            } catch (_: Throwable) {
                data2["formMenuDrop"] = "formMenuDrop"
                data2["formMenuDrop:menuVerNotas:hidden"] = "formMenuDrop:menuVerNotas"
            }

            val root2 = html2AST(session.post("/sigaa/ava/index.jsf", data2))
            val table = find(root2, "table.tabelaRelatorio").first()
            val tr2 = find(table, "tr.linhaPar").first()
            val vn = find(tr2, "td").map { it.text().trim() }
            val v = vn.subList(2, vn.size - 4)
            val a = find(root2, "input#denAval").map { it.`val`() }
            val n = find(root2, "input#notaAval").map { it.`val`() }

            return a.zip(n).zip(v).map {
                mapOf(
                        "Avaliação" to unescapeHTML(it.first.first),
                        "Nota Máxima" to unescapeHTML(it.first.second),
                        "Nota" to unescapeHTML(it.second)
                )
            }
        } catch (_: Throwable) {
            return listOf()
        }
    }

    private fun listCourses(): List<HashMap<String, HashMap<String, String>>> {
        val html = html2AST(goHome())
        return find(html, "td.descricao").map {
            val name = find(it, "form").first().attr("name")
            hashMapOf(
                    "CourseName" to hashMapOf("Value" to unescapeHTML(find(it, "a").first().text())),
                    "Data" to hashMapOf(
                            "idTurma" to find(it, "input[name='idTurma']").first().`val`(),
                            "javax.faces.ViewState" to find(it, "input[name='javax.faces.ViewState']").first().`val`(),
                            name to name,
                            "$name:turmaVirtual" to "$name:turmaVirtual"
                    )
            )
        }
    }

    private fun login() {
        val data = hashMapOf(
                "width" to "800",
                "height" to "600",
                "urlRedirect" to "",
                "subsistemaRedirect" to "",
                "acao" to "",
                "acessibilidade" to "",
                "user.login" to username,
                "user.senha" to password
        )
        session.post("/sigaa/logar.do;jsessionid=$jsessionid.inst$inst?dispatch=logOn", data)
    }

    private fun goHome(): String {
        session.get("/sigaa/verPortalDiscente.do")
        return session.get("/sigaa/portais/discente/discente.jsf")
    }

    private fun html2AST(html: String): Document {
        return Jsoup.parse(html)
    }

    private fun find(node: Element, query: String): Elements {
        return node.select(query)
    }

    private fun unescapeHTML(text: String): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            Html.fromHtml(text, Html.FROM_HTML_MODE_LEGACY)?.toString() ?: ""
        } else {
            @Suppress("DEPRECATION")
            Html.fromHtml(text)?.toString() ?: ""
        }
    }

    class Course(val name: String, val grades: List<Grade>) {
        companion object {
            fun fromHashMap(course: String, grades: List<Map<String, String>>): Course {
                val gradesList = grades.map { Grade.fromHashMap(it) }
                return Course(course.trim(), gradesList)
            }
        }
    }

    class Grade(val testName: String, val score: String, val worth: String) {
        companion object {
            fun fromHashMap(grade: Map<String, String>): Grade {
                val testName = grade["Avaliação"]?.trim() ?: ""
                val score = grade["Nota"]?.trim() ?: ""
                val worth = grade["Nota Máxima"]?.trim() ?: ""
                return Grade(testName, score, worth)
            }
        }
    }
}
