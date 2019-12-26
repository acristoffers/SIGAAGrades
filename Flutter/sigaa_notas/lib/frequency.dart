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

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaa_notas/app_scaffold.dart';
import 'package:sigaa_notas/empty_list_view.dart';
import 'package:sigaa_notas/sigaa.dart';
import 'package:sigaa_notas/utils.dart';
import 'package:sprintf/sprintf.dart';

class FrequencyPage extends StatefulWidget {
  @override
  _FrequencyState createState() => _FrequencyState();
}

class _FrequencyState extends State<FrequencyPage> {
  final _sigaa = SIGAA();
  final _refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();
  final _courses = <Course>[];

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _refreshIndicatorKey.currentState.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Text('Frequência')),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          await _refresh().catchError((_) {
            showToast(context, "Erro de conexão");
          });
        },
        child: _courses.length == 0
            ? ListView(children: <Widget>[EmptyListPage()])
            : ListView.builder(
                itemBuilder: (BuildContext context, int index) {
                  var course = _courses[index];
                  return Card(
                    child: ListTile(
                      title: Text(course.name),
                      subtitle: Text(
                        sprintf(
                            'Faltas: %d (%3.2f%% do total, %3.2f%% das ministradas)',
                            [
                              course.frequency.absences,
                              100 *
                                  course.frequency.absences /
                                  course.frequency.totalClasses,
                              100 *
                                  course.frequency.absences /
                                  course.frequency.givenClasses,
                            ]),
                      ),
                    ),
                  );
                },
                itemCount: _courses.length,
              ),
      ),
    );
  }

  Future<void> _refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final password = prefs.getString('password');
    final link = prefs.getString('link');

    await _sigaa.login(username, password);
    await _sigaa.httpGet(link);

    final courses = await _sigaa.listCourses();
    await Future.wait(courses.map((c) async {
      c.frequency = await _sigaa.listFrequency(c);
    }));

    setState(() {
      _courses.clear();
      _courses.addAll(courses);
    });
  }
}
