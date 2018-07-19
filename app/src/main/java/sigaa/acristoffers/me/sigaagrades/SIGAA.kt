package sigaa.acristoffers.me.sigaagrades

import android.os.Build
import android.text.Html
import io.reactivex.Observable
import org.jsoup.Jsoup
import org.jsoup.helper.W3CDom
import org.w3c.dom.Document
import org.w3c.dom.Node
import org.w3c.dom.NodeList
import java.util.*
import javax.xml.parsers.DocumentBuilderFactory
import javax.xml.xpath.XPathConstants
import javax.xml.xpath.XPathFactory
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
        val courses = listCourses()
        val course = courses.first { it["Data"]!!["idTurma"] == course_id }
        val html = session.post("/sigaa/portais/discente/discente.jsf", course["Data"]!!)
        val root = html2AST(html)

        val viewState = xpath(root, "//input[@name=\"javax.faces.ViewState\"]/@value").first().nodeValue.toString()
        val data2 = hashMapOf("javax.faces.ViewState" to viewState)

        try {
            val link = xpath(root, "//a[contains(.//div, \"Ver Notas\")]/@onclick").first().nodeValue.toString()
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
        val table = xpath(root2, "//table[@class=\"tabelaRelatorio\"]").first()
        val tr2 = xpath(table, ".//tr[@class=\"linhaPar\"]").first()
        val vn = xpath(tr2, ".//td/text()").map { it.nodeValue.toString().trim() }
        val v = vn.subList(2, vn.size - 4)
        val a = xpath(root2, "//input[contains(@id,\"denAval\")]/@value").map { it.nodeValue.toString() }
        val n = xpath(root2, "//input[contains(@id,\"notaAval\")]/@value").map { it.nodeValue.toString() }

        return a.zip(n).zip(v).map {
            mapOf(
                    "Avaliação" to unescapeHTML(it.first.first),
                    "Nota Máxima" to unescapeHTML(it.first.second),
                    "Nota" to unescapeHTML(it.second)
            )
        }
    }

    private fun listCourses(): List<HashMap<String, HashMap<String, String>>> {
        val html = html2AST(goHome())
        return xpath(html, "//td[@class=\"descricao\"]").map {
            val name = xpath(it, ".//form/@name").first().nodeValue.toString()
            hashMapOf(
                    "CourseName" to hashMapOf("Value" to unescapeHTML(xpath(it, ".//a/text()").first().nodeValue.toString())),
                    "Data" to hashMapOf(
                            "idTurma" to xpath(it, ".//input[@name=\"idTurma\"]/@value").first().nodeValue.toString(),
                            "javax.faces.ViewState" to xpath(it, ".//input[@name=\"javax.faces.ViewState\"]/@value").first().nodeValue.toString(),
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
        val dom = Jsoup.parse(html)
        return W3CDom().fromJsoup(dom)
                ?: DocumentBuilderFactory.newInstance().newDocumentBuilder().newDocument()
    }

    private fun xpath(node: Node, xPathExpression: String): List<Node> {
        val xpath = XPathFactory.newInstance().newXPath().compile(xPathExpression)
        val nodeList = xpath.evaluate(node, XPathConstants.NODESET) as NodeList?
        return if (nodeList != null && nodeList.length > 0)
            (0..(nodeList.length - 1)).mapNotNull { nodeList.item(it) }
        else
            listOf()
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
