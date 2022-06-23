/*
 * Copyright (c) 2019 Álan Crístoffer
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

import 'package:quiver/iterables.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaa_notas/common/sigaa.dart';
import 'package:sigaa_notas/common/utils.dart';

class GradesService {
  static Future<List<Course>> refresh() async {
    final sigaa = SIGAA();
    final db = await getDatabase();

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final password = prefs.getString('password');
    final link = prefs.getString('link');

    await sigaa.login(username, password);
    await sigaa.httpGet(link);

    final courses = await sigaa.listCourses();
    final fs = await Future.wait(courses.map((c) => sigaa.listGrades(c)));

    zip([fs, courses]).forEach((e) => (e[1] as Course).grades = e[0]);

    final links = await db.query('links', where: 'url=?', whereArgs: [link]);
    final linkID = links.first['id'];

    await db.delete('courses', where: null);
    await db.delete('grades', where: null);
    for (final course in courses) {
      final courseDict = {
        'name': course.name,
        'cid': course.cid,
        'link': linkID,
      };

      final id = await db.insert('courses', courseDict);

      for (final grade in course.grades) {
        final gradeDict = {
          'activityName': grade.activityName,
          'scoreValue': grade.scoreValue,
          'totalValue': grade.totalValue,
          'course': id,
        };

        await db.insert('grades', gradeDict);
      }
    }

    return courses;
  }
}
