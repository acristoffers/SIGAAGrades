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

import 'dart:io';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaa_notas/drawer.dart';
import 'package:sigaa_notas/sigaa.dart';
import 'package:sigaa_notas/utils.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';

class SchedulesPage extends StatefulWidget {
  @override
  _SchedulesState createState() => _SchedulesState();
}

class _SchedulesState extends State<SchedulesPage> {
  final _sigaa = SIGAA();
  final _refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();
  final _schedules = <Schedule>[];
  final _wd = DateTime.now().weekday + 1;
  Database _db;

  @override
  void initState() {
    super.initState();

    getDatabase().then((db) => _db = db);
    getSchedules().then((schedules) {
      if (schedules.length == 0) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _refreshIndicatorKey.currentState.show();
        });
      }

      setState(() {
        _schedules.clear();
        _schedules.addAll(schedules);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Horários'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Adicionar ao calendário',
            onPressed: () async => _addToCalendar().catchError((_) {
              showToast(context, 'Erro ao adicionar ao calendário.');
            }),
          ),
        ],
      ),
      drawer: Drawer(
        child: DrawerPage(),
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          await _refresh().catchError((_) {
            showToast(context, "Erro de conexão");
          });
        },
        child: ListView(
          children: <Widget>[
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.fromLTRB(10, 15, 10, 0),
                    title: Text(
                      'Hoje',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20),
                    ),
                    subtitle: ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemBuilder: (BuildContext context, int index) {
                          final schedule = _todaySchedules()[index];
                          return ListTile(
                            title: Text(
                              schedule.course,
                              style: TextStyle(fontSize: 13),
                            ),
                            subtitle: Text(
                              'De ${schedule.start} até ${schedule.end}. Local: ${schedule.local}',
                            ),
                          );
                        },
                        itemCount: _todaySchedules().length),
                  ),
                )
              ] +
              [
                [2, 'Segunda'],
                [3, 'Terça'],
                [4, 'Quarta'],
                [5, 'Quinta'],
                [6, 'Sexta'],
              ].map(
                (e) {
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.fromLTRB(10, 15, 10, 0),
                      title: Text(
                        e[1],
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20),
                      ),
                      subtitle: ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemBuilder: (BuildContext context, int index) {
                            final schedule = _sortedForDay(e[0])[index];
                            return ListTile(
                              title: Text(
                                schedule.course,
                                style: TextStyle(fontSize: 13),
                              ),
                              subtitle: Text(
                                'De ${schedule.start} até ${schedule.end}. Local: ${schedule.local}',
                              ),
                            );
                          },
                          itemCount:
                              _schedules.where((s) => s.day == e[0]).length),
                    ),
                  );
                },
              ).toList(),
        ),
      ),
    );
  }

  List<Schedule> _todaySchedules() {
    final nh = DateTime.now().hour;
    final nm = DateTime.now().minute;

    final schedules = <Schedule>[];
    for (final s in _schedules.where((s) => s.day == _wd)) {
      try {
        final xs = s.end.split(':');
        final sh = int.parse(xs.first);
        final sm = int.parse(xs.last);
        if (nh < sh || (nh == sh && nm <= sm)) {
          schedules.add(s);
        }
      } catch (e, s) {
        debugPrint(e);
        debugPrint(s.toString());
      }
    }

    return schedules;
  }

  List<Schedule> _sortedForDay(int day) {
    final ss = _schedules.where((s) => s.day == day).toList();
    ss.sort((a, b) {
      final sa = int.parse(a.start.split(':').first);
      final sb = int.parse(b.start.split(':').first);
      return sa.compareTo(sb);
    });
    return ss;
  }

  Future<Calendar> _showDialog(List<Calendar> calendars) async {
    return await showDialog<Calendar>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('Selecione o calendário'),
            children: calendars
                .map((c) => Padding(
                      padding: EdgeInsets.all(10),
                      child: SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, c),
                        child: Text(c.name),
                      ),
                    ))
                .toList(),
          );
        });
  }

  Future<void> _refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final password = prefs.getString('password');
    final link = prefs.getString('link');

    await _sigaa.login(username, password);
    await _sigaa.httpGet(link);

    final schedules = await _sigaa.listSchedules();

    setState(() {
      _schedules.clear();
      _schedules.addAll(schedules);
    });

    await _db.delete('schedules', where: null);
    for (final schedule in schedules) {
      final cs = await _db.query(
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

      await _db.insert('schedules', map);
    }
  }

  Future<void> _addToCalendar() async {
    final dcp = DeviceCalendarPlugin();

    // Calendar Permission
    var permissionsGranted = await dcp.hasPermissions();
    if (permissionsGranted.isSuccess && !permissionsGranted.data) {
      permissionsGranted = await dcp.requestPermissions();
      if (!permissionsGranted.isSuccess || !permissionsGranted.data) {
        return;
      }
    }

    // Select Calendar
    final result = await dcp.retrieveCalendars();
    final calendars = result.isSuccess ? result.data : <Calendar>[];
    if (calendars.length == 0) return;
    final calendar = await _showDialog(calendars);
    if (calendar == null) return;

    showToast(context, 'Buscando datas de início e fim do semestre...');

    // Get Start and End of Semester
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final password = prefs.getString('password');
    final link = prefs.getString('link');

    await _sigaa.login(username, password);
    await _sigaa.httpGet(link);

    final seos = await _sigaa.startAndEndOfSemester();
    final startOfSemester = seos.first;
    final endOfSemester = seos.last;

    // Add Calendar Events
    for (final schedule in _schedules) {
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
        setPositions: [], // bug in library
      );

      event.start = startTime;
      event.end = endTime;
      event.location = schedule.local;
      event.title = schedule.course;
      event.recurrenceRule = recurrenceRule;

      await dcp.createOrUpdateEvent(event);
    }

    if (Platform.isAndroid) {
      await launch('content://com.android.calendar/time/');
    } else if (Platform.isIOS) {
      await launch('calshow://');
    }
  }
}
