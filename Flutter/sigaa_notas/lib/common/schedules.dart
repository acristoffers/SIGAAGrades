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

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaa_notas/common/sigaa.dart';
import 'package:sigaa_notas/common/utils.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SchedulesService {
  static Future<List<Schedule>> refresh() async {
    final sigaa = SIGAA();
    final db = await getDatabase();

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final password = prefs.getString('password');
    final link = prefs.getString('link');

    await sigaa.login(username, password);
    await sigaa.httpGet(link);

    final schedules = await sigaa.listSchedules();

    await db.delete('schedules', where: null);
    for (final schedule in schedules) {
      final cs = await db.query(
        'courses',
        where: 'cid=?',
        whereArgs: [schedule.cid],
      );

      final map = {
        'course': cs.first['id'],
        'local': schedule.local,
        'day': schedule.day,
        'shift': schedule.shift,
        'start': schedule.start,
        'end': schedule.end,
      };

      await db.insert('schedules', map);
    }

    return schedules;
  }

  static List<Schedule> todaySchedules(List<Schedule> schedules) {
    final nh = DateTime.now().hour;
    final nm = DateTime.now().minute;
    final wd = DateTime.now().weekday + 1;

    return schedules
        .where((s) => s.day == wd)
        .map((s) {
          try {
            final xs = s.end.split(':');
            final sh = int.parse(xs.first);
            final sm = int.parse(xs.last);
            if (nh < sh || (nh == sh && nm <= sm)) {
              return s;
            }
          } catch (_) {}
          return null;
        })
        .where((s) => s != null)
        .toList()
      ..sort((a, b) {
        final sa = int.tryParse(a.start.split(':').first);
        final sb = int.tryParse(b.start.split(':').first);

        if (sa == null || sb == null) {
          return 1;
        }

        return sa.compareTo(sb);
      });
  }

  static List<Schedule> sortedForDay(List<Schedule> schedules, int day) {
    final ss = schedules.where((s) => s.day == day).toList();
    ss.sort((a, b) {
      final sa = int.tryParse(a.start.split(':').first);
      final sb = int.tryParse(b.start.split(':').first);

      if (sa == null || sb == null) {
        return 1;
      }

      return sa.compareTo(sb);
    });
    return ss;
  }

  static Future<List<Calendar>> listCalendars() async {
    final dcp = DeviceCalendarPlugin();

    var permission = await dcp.hasPermissions();
    if (permission.isSuccess && !permission.data) {
      permission = await dcp.requestPermissions();
      if (!permission.isSuccess || !permission.data) {
        throw SimpleException('no-permission');
      }
    }

    final result = await dcp.retrieveCalendars();
    if (result.isSuccess) {
      return result.data;
    }

    throw SimpleException('calendar-fetch');
  }

  static Future<void> addToCalendar(
    Calendar calendar,
    List<Schedule> schedules,
  ) async {
    // Get Start and End of Semester
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final password = prefs.getString('password');
    final link = prefs.getString('link');

    final sigaa = SIGAA();
    await sigaa.login(username, password);
    await sigaa.httpGet(link);

    final seos = await sigaa.startAndEndOfSemester();
    final startOfSemester = seos.first;
    final endOfSemester = seos.last;

    // Add Calendar Events
    for (final schedule in schedules) {
      final event = Event(calendar.id);

      final startHour = schedule.start.split(':').map(int.parse).first;
      final startMinute = schedule.start.split(':').map(int.parse).last;
      final startDay = (6 + schedule.day - startOfSemester.weekday) % 7;
      final startMonth = startOfSemester.month;
      final startYear = startOfSemester.year;
      final startTime = DateTime(
        startYear,
        startMonth,
        startDay + startOfSemester.day,
        startHour,
        startMinute,
      );

      final endHour = schedule.end.split(':').map(int.parse).first;
      final endMinute = schedule.end.split(':').map(int.parse).last;
      final endDay = (6 + schedule.day - startOfSemester.weekday) % 7;
      final endMonth = startOfSemester.month;
      final endYear = startOfSemester.year;
      final endTime = DateTime(
        endYear,
        endMonth,
        endDay + startOfSemester.day,
        endHour,
        endMinute,
      );

      final recurrenceRule = RecurrenceRule(
        RecurrenceFrequency.Weekly,
        endDate: endOfSemester,
      );

      event.start = startTime;
      event.end = endTime;
      event.location = schedule.local;
      event.title = schedule.course;
      event.recurrenceRule = recurrenceRule;

      final dcp = DeviceCalendarPlugin();
      await dcp.createOrUpdateEvent(event);
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      await launchUrlString('content://com.android.calendar/time/');
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await launchUrlString('calshow://');
    }
  }
}
