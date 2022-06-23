/*
 * Copyright (c) 2019 Álan Crístoffer
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the 'Software'), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import 'package:flutter/material.dart';

class Table extends StatelessWidget {
  final course;
  final Widget body;
  final String title;

  const Table(this.title, this.course, this.body);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(5, 15, 5, 0),
          title: Text(
            title,
            textAlign: TextAlign.center,
          ),
          subtitle: _bodyOrMessage()),
    );
  }

  Widget _bodyOrMessage() {
    if (course == null) {
      return body;
    }
    if (course.grades.length > 0) {
      return body;
    } else {
      return Column(
        children: const <Widget>[
          Padding(padding: EdgeInsets.all(10)),
          Text('A matéria não possui notas cadastradas'),
          Padding(padding: EdgeInsets.all(10)),
        ],
      );
    }
  }
}
