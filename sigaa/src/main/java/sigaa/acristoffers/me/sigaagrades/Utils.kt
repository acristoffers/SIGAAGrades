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

fun <T> tryOrDefault(defaultValue: T, f: () -> T): T {
    return try {
        f()
    } catch (_: Throwable) {
        defaultValue
    }
}

fun <T> areListsDifferent(A: Collection<T>, B: Collection<T>, itemComparator: (A: T, B: T) -> Boolean): Boolean {
    // Will consider them equal if A.size < B.size. This is by design.
    return A.size > B.size || (A.size == B.size && !A.map { a -> B.map { b -> itemComparator(a, b) }.any { it } }.all { it })
}

fun parseChunk(request: String): String {
    var i = request.indexOf("\r\n\r\n")
    while (i < request.length && (request[i] == '\r' || request[i] == '\n')) {
        i++
    }

    val r = "[0-9a-fA-F]".toRegex()
    if (i == request.length) {
        return ""
    } else if (!r.matches(request[i].toString())) {
        return request.substring(i)
    }

    var body = ""
    while (i < request.length) {
        var j = ""
        while (r.matches(request[i].toString())) {
            j += request[i]
            i++
        }

        if (j.isEmpty()) {
            break
        }

        val bytes = j.toInt(16)
        body += request.substring(i + 2, i + 2 + bytes)
        i += 4 + bytes
    }

    return body
}
