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

fun <T, U> Collection<T>.zipBy(B: Collection<T>, filter: (E: T) -> U): Collection<Pair<T, T>> {
    return this.mapNotNull { a ->
        val second = B.firstOrNull { b -> filter(b) == filter(a) }
        if (second != null) {
            Pair(a, second)
        } else {
            null
        }
    }
}

fun <T, R> Collection<Pair<T, T>>.comparePairWith(comparator: (a: T, b: T) -> R): Collection<R> {
    return this.map { comparator(it.first, it.second) }
}
