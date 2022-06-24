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

import 'package:oktoast/oktoast.dart' as oktoast;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaa_notas/common/sigaa.dart';
import 'package:sqflite/sqflite.dart';

class SimpleException implements Exception {
  SimpleException(this.reason) : super();
  var reason = '';
}

Future<Database> getDatabase() async {
  final path = await getDatabasesPath();
  return openDatabase(
    join(path, 'sigaa.db'),
    onUpgrade: (db, version, _) async {
      if (version < 1) {
        await db.execute(
          'CREATE TABLE courses(id INTEGER PRIMARY KEY, name TEXT, cid TEXT, link INT, FOREIGN KEY (link) REFERENCES links (id) ON DELETE CASCADE)',
        );
        await db.execute(
          'CREATE TABLE grades(id INTEGER PRIMARY KEY, activityName TEXT, scoreValue TEXT, totalValue TEXT, course INT, FOREIGN KEY (course) REFERENCES courses (id) ON DELETE CASCADE)',
        );
        await db.execute(
          'CREATE TABLE links(id INTEGER PRIMARY KEY, name TEXT, url TEXT)',
        );
      }

      if (version < 2) {
        await db.execute(
          'CREATE TABLE schedules(id INTEGER PRIMARY KEY, course INT, local TEXT, day INT, shift INT, start TEXT, end TEXT, FOREIGN KEY (course) REFERENCES courses (id) ON DELETE CASCADE)',
        );
      }
    },
    version: 2,
  );
}

Future<List<Course>> getCourses() async {
  final db = await getDatabase();

  final prefs = await SharedPreferences.getInstance();
  final url = prefs.getString('link');

  final links = await db.query('links', where: 'url=?', whereArgs: [url]);
  final linkID = links.first['id'];

  final cs = await db.query(
    'courses',
    where: 'link=?',
    whereArgs: [linkID],
  );

  final courses = <Course>[];

  for (final c in cs) {
    final gs = await db.query(
      'grades',
      where: 'course=?',
      whereArgs: [c['id']],
    );

    final grades = gs.map((g) => Grade(
        id: g['id'] as int,
        activityName: g['activityName'] as String,
        scoreValue: g['scoreValue'] as String,
        totalValue: g['totalValue'] as String));

    final course = Course(
        id: c['id'] as int,
        cid: c['cid'] as String,
        name: c['name'] as String,
        data: {},
        grades: grades.toList());

    courses.add(course);
  }

  return courses;
}

Future<List<Schedule>> getSchedules() async {
  final db = await getDatabase();

  final prefs = await SharedPreferences.getInstance();
  final url = prefs.getString('link');

  final links = await db.query('links', where: 'url=?', whereArgs: [url]);
  final linkID = links.first['id'];

  final cs = await db.query(
    'courses',
    where: 'link=?',
    whereArgs: [linkID],
  );

  final schedules = <Schedule>[];

  for (final c in cs) {
    final cid = c['id'];
    final course = c['name'];

    final ms = await db.query('schedules', where: 'course=?', whereArgs: [cid]);
    final ss = ms.map((s) => Schedule(
          course: course as String,
          local: s['local'] as String,
          day: s['day'] as int,
          shift: s['shift'] as int,
          start: s['start'] as String,
          end: s['end'] as String,
          cid: c['cid'] as String,
        ));

    schedules.addAll(ss);
  }

  return schedules;
}

T? firstOrNull<T>(Iterable<T> xs) {
  try {
    return xs.first;
  } catch (_) {
    return null;
  }
}

void showToast(String message) {
  oktoast.showToast(message);
}
