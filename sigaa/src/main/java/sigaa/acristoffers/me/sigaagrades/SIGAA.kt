/*
 * Copyright (c) 2018 Álan Crístoffer
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
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

import android.os.Build
import android.text.Html
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import org.jsoup.Jsoup
import org.jsoup.nodes.Document
import org.jsoup.nodes.Element
import org.jsoup.select.Elements
import java.util.*

class SIGAA(private val username: String, private val password: String) {
    private var session = Session("https://sig.cefetmg.br")
    private var jsessionid: String = ""
    private var inst: String = ""

    private suspend fun setup() {
        session = Session("https://sig.cefetmg.br")
        val response = session.get("/sigaa/verTelaLogin.do") ?: throw Exception("Server Error")
        val regex = "/sigaa/logar\\.do;jsessionid=([0-9A-Z]+)\\.inst([0-9]+)\\?dispatch=logOn".toRegex()
        val match = regex.find(response)
        jsessionid = match?.groupValues?.get(1) ?: ""
        inst = match?.groupValues?.get(2) ?: ""
    }

    suspend fun listGrades(): List<Course> {
        val courses = listCourses()
        return coroutineScope {
            courses.map {
                async {
                    val sigaa = SIGAA(username, password)
                    val courseId = it["id"]!!["Value"]!!
                    val courseGrades = sigaa.listGradesForCourse(courseId)
                    Course.fromMap(it["CourseName"]!!["Value"]!!, courseGrades)
                }
            }
        }.map { it.await() }
    }

    suspend fun listFrequency(): List<Frequency> {
        val courses = listCourses()
        return coroutineScope {
            courses.map {
                async {
                    val sigaa = SIGAA(username, password)
                    val courseId = it["id"]!!["Value"]!!
                    val course = it["CourseName"]!!["Value"]!!
                    val frequency = sigaa.listFrequencyForCourse(courseId)
                    frequency?.course = course
                    frequency
                }
            }.mapNotNull { it.await() }
        }
    }

    suspend fun listSchedules(): List<Schedule> {
        val html = html2AST(goHome())
        return find(html, "td.descricao").map { description ->
            val tr = description.parent()
            val course = find(tr, "td.descricao").last()?.text() ?: ""
            val local = find(tr, "td.info").first()?.text() ?: ""
            find(tr, "td.info").last()?.text()?.split(" ")?.map { info ->
                val d = "([0-9]+)[A-Z]".toRegex().find(info)?.groupValues?.get(1) ?: ""
                val m = ".*M([0-9]+)[^A-Z]?".toRegex().find(info)?.groupValues?.get(1) ?: ""
                val t = ".*T([0-9]+)[^A-Z]?".toRegex().find(info)?.groupValues?.get(1) ?: ""
                val n = ".*N([0-9]+)[^A-Z]?".toRegex().find(info)?.groupValues?.get(1) ?: ""
                d.map { dayChar ->
                    try {
                        val day = dayChar.toString()

                        val ms = stringToRanges(m).map {
                            mapOf(
                                    "course" to course,
                                    "local" to local,
                                    "day" to day,
                                    "shift" to "1",
                                    "start" to it[0].toString(),
                                    "end" to it[1].toString()
                            )
                        }

                        val ts = stringToRanges(t).map {
                            mapOf(
                                    "course" to course,
                                    "local" to local,
                                    "day" to day,
                                    "shift" to "2",
                                    "start" to it[0].toString(),
                                    "end" to it[1].toString()
                            )
                        }

                        val ns = stringToRanges(n).map {
                            mapOf(
                                    "course" to course,
                                    "local" to local,
                                    "day" to day,
                                    "shift" to "3",
                                    "start" to it[0].toString(),
                                    "end" to it[1].toString()
                            )
                        }

                        ms + ts + ns
                    } catch (_: Throwable) {
                        listOf<Map<String, String>>()
                    }
                }.flatten()
            }?.flatten() ?: listOf()
        }.flatten().map { Schedule.fromMap(it) }
    }

    suspend fun startAndEndOfSemester(): List<Calendar> {
        val html = goHome()
        val root = html2AST(html)
        val jID = find(root, "input[name='javax.faces.ViewState']").first()?.`val`() ?: ""
        val id = find(root, "input[name='id']").first()?.`val`() ?: ""
        val menu = "menu_form_menu_discente_j_id_jsp_[0-9_]+_menu".toRegex().find(html)?.groupValues?.get(0)
        val data = mapOf(
                "id" to id,
                "javax.faces.ViewState" to jID,
                "jscook_action" to "$menu:A]#{calendario.iniciarBusca}",
                "menu:form_menu_discente" to "menu:form_menu_discente"
        )
        val html2 = session.post("/sigaa/portais/discente/discente.jsf", data)
                ?: throw Exception("Server Error")
        val root2 = html2AST(html2)
        val semester = find(root2, ".periodo-atual strong").first()?.text() ?: ""
        val index = find(root2, "thead").indexOfFirst { it.text().contains(semester) }
        val a = find(root2, ".listagem tbody a")[index]?.attr("onclick") ?: ""
        val id2 = "'id':'([0-9]+)'".toRegex().find(a)?.groupValues?.get(1) ?: ""
        val jID2 = find(root2, "input[name='javax.faces.ViewState']").first()?.`val`() ?: ""
        val data2 = mapOf(
                "form" to "form",
                "form:visualizar" to "form:visualizar",
                "id" to id2,
                "javax.faces.ViewState" to jID2
        )
        val url3 = "/sigaa/administracao/calendario_academico/consulta.jsf"
        val html3 = session.post(url3, data2) ?: throw Exception("Server Error")
        val root3 = html2AST(html3)
        val tr = find(root3, "th:contains(Período Letivo:)").first()?.parent()
        val duration = tr?.children()?.last()?.text()?.removePrefix("De ") ?: ""
        return duration.split("até").mapNotNull {
            try {
                val dp = it.trim().split("/").map { i -> i.trim().toInt() }
                val cal = Calendar.getInstance()
                cal.set(dp[2], dp[1] - 1, dp[0], 0, 0, 0)
                cal
            } catch (_: Throwable) {
                null
            }
        }
    }

    private fun stringToRanges(str: String): List<List<Int>> {
        val ns = str.map { it.toString().trim().toInt() }.sorted()
        val rs = mutableListOf<List<Int>>()

        for (i in ns) {
            val x = rs.lastOrNull()?.get(1) ?: i
            if ((i - 1) == x) {
                rs[rs.size - 1] = listOf(rs.last()[0], i)
            } else {
                rs.add(listOf(i, i))
            }
        }

        return rs
    }

    private suspend fun listGradesForCourse(course_id: String): List<Map<String, String>> {
        val courses = listCourses()
        val course = courses.first { it["id"]!!["Value"] == course_id }
        val html = session.post("/sigaa/portais/discente/discente.jsf", course["Data"]!!)
                ?: throw Exception("Server Error")
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

        val response = session.post("/sigaa/ava/index.jsf", data2)
                ?: throw Exception("Server Error")
        val root2 = html2AST(response)
        val table = find(root2, "table.tabelaRelatorio").first() ?: return listOf()

        val tr = find(table, "tbody tr").first()
        val vn = find(tr, "td").map { it.text().trim() }
        val v = vn.subList(2, vn.size - 5)

        val tr2 = find(table, "tr#trAval").first()
        val ids = find(tr2, "th[id]")
                .map { it.attr("id") }
                .filter { it.startsWith("aval_") }
                .map { it.removePrefix("aval_") }

        val a = ids.mapNotNull { find(tr2, "input#denAval_$it").map { it2 -> it2.`val`() }.firstOrNull() }
        val n = ids.mapNotNull { find(tr2, "input#notaAval_$it").map { it2 -> it2.`val`() }.firstOrNull() }

        return a.zip(n).zip(v).map {
            mapOf(
                    "Avaliação" to unescapeHTML(it.first.first),
                    "Nota Máxima" to unescapeHTML(it.first.second),
                    "Nota" to unescapeHTML(it.second)
            )
        }
    }

    private suspend fun listFrequencyForCourse(course_id: String): Frequency? {
        val courses = listCourses()
        val course = courses.first { it["id"]!!["Value"] == course_id }
        val html = session.post("/sigaa/portais/discente/discente.jsf", course["Data"]!!)
                ?: throw Exception("Server Error")
        val root = html2AST(html)

        val viewState = find(root, "input[name='javax.faces.ViewState']").first().`val`()
        val data2 = hashMapOf("javax.faces.ViewState" to viewState)

        try {
            val link = find(root, "div:contains(Frequência)").last().parent().attr("onclick")
            val regex = "formMenu:j_id_jsp_([0-9_]+)".toRegex()
            val m = regex.find(link)?.groupValues?.get(1) ?: ""
            val regex2 = "PanelBar\\('formMenu:j_id_jsp_([0-9_]+)".toRegex()
            val m2 = regex2.find(html)?.groupValues?.get(1) ?: ""
            data2["formMenu"] = "formMenu"
            data2["formMenu:j_id_jsp_$m2"] = "formMenu:j_id_jsp_$m2"
            data2["formMenu:j_id_jsp_$m"] = "formMenu:j_id_jsp_$m"
        } catch (_: Throwable) {
            data2["formMenuDrop"] = "formMenuDrop"
            data2["formMenuDrop:menuFrequencia:hidden"] = "formMenuDrop:menuFrequencia"
        }

        val response = session.post("/sigaa/ava/index.jsf", data2)
                ?: throw Exception("Server Error")
        val root2 = html2AST(response)
        val div = find(root2, "#scroll-wrapper").first()
        val text = div.text() ?: ""

        if (text.contains("A frequência ainda não foi lançada.")) {
            return null
        }

        val match = "Frequência:[ ]+([0-9]+)".toRegex().find(text)
        val frequency = match?.groupValues?.get(1) ?: ""

        val div2 = find(root2, "#barraDireita").first()
        val text2 = div2.text() ?: ""
        val match2 = "Aulas[ ]+\\(Ministradas/Total\\):[ ]+([0-9]+)[ ]+/[ ]+([0-9]+)".toRegex().find(text2)
        val givenClasses = match2?.groupValues?.get(1) ?: ""
        val totalClasses = match2?.groupValues?.get(2) ?: ""

        return Frequency("", frequency.toInt(), givenClasses.toInt(), totalClasses.toInt())
    }

    private suspend fun listCourses(): List<HashMap<String, HashMap<String, String>>> {
        val html = html2AST(goHome())
        return find(html, "td.descricao").map {
            val onclick = find(it, "a").first().attr("onclick")
            val fName = find(it, "form").first().attr("name")

            val r = "'($fName:[a-zA-Z0-9_]+)'".toRegex()
            val m = r.find(onclick)
            val name = m?.groupValues?.get(1)
                    ?: throw Exception("Invalid onclick contents - SIGAA.kt:298")

            val r2 = "'frontEndIdTurma':'([A-Z0-9]+)'".toRegex()
            val m2 = r2.find(onclick)
            val idTurma = m2?.groupValues?.get(1)
                    ?: throw Exception("Invalid onclick contents - SIGAA.kt:302")

            hashMapOf(
                    "CourseName" to hashMapOf("Value" to unescapeHTML(find(it, "a").first().text())),
                    "id" to hashMapOf("Value" to idTurma),
                    "Data" to hashMapOf(
                            "frontEndIdTurma" to idTurma,
                            "javax.faces.ViewState" to find(it, "input[name='javax.faces.ViewState']").first().`val`(),
                            name to name,
                            fName to fName
                    )
            )
        }
    }

    private suspend fun login() {
        setup()

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

    private suspend fun goHome(): String {
        session.get("/sigaa/verPortalDiscente.do") ?: throw Exception("Server Error")
        val url = "/sigaa/portais/discente/discente.jsf"
        val html = session.get(url) ?: throw Exception("Server Error")
        return if (html.startsWith("<script>")) {
            login()
            goHome()
        } else {
            html
        }
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

    data class Frequency(var course: String, val frequency: Int, val givenClasses: Int, val totalClasses: Int)

    data class Course(val name: String, val grades: List<Grade>) {
        companion object {
            fun fromMap(course: String, grades: List<Map<String, String>>): Course {
                val gradesList = grades.map { Grade.fromMap(it) }
                return Course(course.trim(), gradesList)
            }
        }
    }

    data class Grade(val testName: String, val score: String, val worth: String) {
        companion object {
            fun fromMap(grade: Map<String, String>): Grade {
                val testName = grade["Avaliação"]?.trim() ?: ""
                val score = grade["Nota"]?.trim() ?: ""
                val worth = grade["Nota Máxima"]?.trim() ?: ""
                return Grade(testName, score, worth)
            }
        }
    }

    data class Schedule(val course: String,
                        val local: String,
                        val day: Int,
                        val shift: Int,
                        val start: String,
                        val end: String) {
        companion object {
            fun fromMap(schedule: Map<String, String>): Schedule {
                val course = schedule["course"]?.trim() ?: ""
                val local = schedule["local"]?.trim() ?: ""
                val day = schedule["day"]?.trim() ?: ""
                val shift = schedule["shift"]?.trim() ?: ""
                val start = schedule["start"]?.trim() ?: ""
                val end = schedule["end"]?.trim() ?: ""

                val startTimes = listOf(
                        mapOf(
                                "1" to "7:00",
                                "2" to "7:50",
                                "3" to "8:55",
                                "4" to "9:45",
                                "5" to "10:50",
                                "6" to "11:40"
                        ),
                        mapOf(
                                "1" to "13:50",
                                "2" to "14:40",
                                "3" to "15:50",
                                "4" to "16:40",
                                "5" to "17:40"
                        ),
                        mapOf(
                                "1" to "19:00",
                                "2" to "19:50",
                                "3" to "20:50",
                                "4" to "21:40"
                        )
                )

                val endTimes = listOf(
                        mapOf(
                                "1" to "7:50",
                                "2" to "8:40",
                                "3" to "9:45",
                                "4" to "10:35",
                                "5" to "11:40",
                                "6" to "12:30"
                        ),
                        mapOf(
                                "1" to "14:40",
                                "2" to "15:30",
                                "3" to "16:40",
                                "4" to "17:30",
                                "5" to "18:30"
                        ),
                        mapOf(
                                "1" to "19:50",
                                "2" to "20:40",
                                "3" to "21:40",
                                "4" to "22:30"
                        )
                )

                val startTime = startTimes[shift.toInt() - 1][start] ?: ""
                val endTime = endTimes[shift.toInt() - 1][end] ?: ""

                return Schedule(course, local, day.toInt(), shift.toInt(), startTime, endTime)
            }
        }
    }
}
