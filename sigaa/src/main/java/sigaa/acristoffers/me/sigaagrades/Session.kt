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

        referer = "$uri$path"

        extractCookies(result)
        return extractBody(result)
    }

    fun post(path: String, data: Map<String, String>): String {
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

    private fun headersToString(headers: Map<String, String>): String {
        return headers.map { "${it.key}: ${it.value}" }.joinToString("\r\n")
    }

    private fun defaultHeaders(): Map<String, String> {
        val headers = hashMapOf(
                "User-Agent" to "Mozilla/5.0",
                "Host" to uri.host,
                "Connection" to "Close",
                "Accept-Encoding" to "identity",
                "Accept" to "text/html"
        )

        if (referer != null) {
            headers["Referer"] = referer
        }

        return headers
    }

    private fun fullHeader(method: String, path: String, contentLength: Int = 0): String {
        val cookies = this.cookies.cookieStore.cookies
        val headers = HashMap(defaultHeaders())
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
