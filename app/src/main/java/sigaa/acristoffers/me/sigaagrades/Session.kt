package sigaa.acristoffers.me.sigaagrades

import android.net.Uri
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.*
import javax.net.SocketFactory
import javax.net.ssl.SSLSocketFactory

class Session(url: String) {
    private var socket: Socket? = null
    private var input: InputStreamReader? = null
    private var output: OutputStreamWriter? = null

    private var cookies: CookieManager = CookieManager()
    private var headers: HashMap<String, String>? = null
    private var referer: String? = null
    private val uri: Uri = Uri.parse(url)

    init {
        reconnect()
    }

    private fun reconnect() {
        socket?.close()

        socket = if (uri.scheme == "https") {
            val factory = SSLSocketFactory.getDefault()
            factory.createSocket(uri.host, 443)
        } else {
            val factory = SocketFactory.getDefault()
            factory.createSocket(uri.host, 80)
        }

        input = socket?.getInputStream()?.reader()
        output = socket?.getOutputStream()?.writer()
    }

    fun get(path: String): String {
        reconnect()

        val headers = fullHeader("GET", path)
        output?.write(headers)
        output?.flush()

        val bufferedReader = BufferedReader(input)
        val result = bufferedReader.readText()

        referer = uri.toString() + path

        extractCookies(result)
        return extractBody(result)
    }

    fun post(path: String, data: HashMap<String, String>): String {
        reconnect()

        val body = data.map { "${it.key}=${URLEncoder.encode(it.value, "UTF8")}" }.joinToString("&")

        val headers = fullHeader("POST", path, body.toByteArray().size)
        output?.write(headers + body)
        output?.flush()

        val bufferedReader = BufferedReader(input)
        val result = bufferedReader.readText()

        referer = uri.toString() + path

        extractCookies(result)
        return extractBody(result)
    }

    private fun cookiesToString(cookies: List<HttpCookie>): String {
        return cookies.joinToString("; ") { "${it.name}=${it.value}" }
    }

    private fun headersToString(headers: HashMap<String, String>): String {
        return headers.map { "${it.key}: ${it.value}" }.joinToString("\r\n")
    }

    private fun defaultHeaders(): HashMap<String, String> {
        val headers = hashMapOf(
                "User-Agent" to "Mozilla/5.0",
                "Host" to uri.host,
                "Connection" to "Close",
                "Accept-Encoding" to "identity",
                "Accept" to "text/html"
        )

        if (referer != null) {
            headers["Referer"] = referer!!
        }

        return headers
    }

    private fun fullHeader(method: String, path: String, contentLength: Int = 0): String {
        val cookies = this.cookies.cookieStore.cookies
        val headers = defaultHeaders()
        headers.putAll(this.headers ?: hashMapOf())

        if (cookies.isNotEmpty()) {
            headers["Cookie"] = cookiesToString(cookies)
        }

        if (contentLength != 0) {
            headers["Content-Length"] = contentLength.toString()
            headers["Content-Type"] = "application/x-www-form-urlencoded"
        }

        return "$method $path HTTP/1.1\r\n${headersToString(headers)}\r\n\r\n"
    }

    private fun extractCookies(response: String) {
        val regex = "Set-Cookie: (.*)\r\n".toRegex()
        val match = regex.find(response)
        if (match != null) {
            val setCookie = match.groupValues[1]
            for (cookie in HttpCookie.parse(setCookie)) {
                this.cookies.cookieStore.add(URI(this.uri.toString()), cookie)
            }
        }
    }

    private fun extractBody(response: String): String {
        val list = response.split("\r\n\r\n")
        val sublist = list.subList(1, list.size)
        return sublist.filter { it.trim().isNotEmpty() }.joinToString("").replace("^[^<]+".toRegex(), "")
    }
}
