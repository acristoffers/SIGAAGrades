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

import 'dart:async' show Timer;

import 'package:flutter/material.dart';
import 'package:sigaa_notas/common/grades.dart';
import 'package:sigaa_notas/common/sigaa.dart';
import 'package:sigaa_notas/common/utils.dart';
import 'package:sigaa_notas/material/app.dart';
import 'package:sigaa_notas/material/empty_list_view.dart';
import 'package:sigaa_notas/material/grades_table.dart' as table;
import 'package:sigaa_notas/material/layout.dart';
import 'package:sprintf/sprintf.dart';

class Grades extends StatefulWidget {
  @override
  _GradesState createState() => _GradesState();
}

class _GradesState extends State<Grades> {
  final _refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();
  final _courses = <Course>[];
  bool _showGrades = true;

  @override
  void initState() {
    super.initState();

    getCourses().then((courses) {
      if (!mounted) return;

      if (courses.length == 0) {
        Timer.run(_refreshIndicatorKey.currentState.show);
      }

      setState(() {
        _courses.clear();
        _courses.addAll(courses);
      });
    });

    Application.layoutObserver.emit(
      LayoutGlobalState(title: 'Notas', singlePage: false, actions: <Widget>[
        IconButton(icon: _getShowGradesIcon(), onPressed: _switchShowGrades)
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(10),
        constraints: BoxConstraints.tightForFinite(width: 600),
        child: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: () async {
            await GradesService.refresh().then((courses) {
              if (mounted) {
                setState(() {
                  _courses.clear();
                  _courses.addAll(courses);
                });
              }
            }).catchError((_) {
              if (mounted) {
                showToast("Erro de conexão");
              }
            });
          },
          child: _courses.length == 0
              ? SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height,
                    child: EmptyListPage(),
                  ),
                )
              : ListView.builder(
                  itemBuilder: (BuildContext context, int index) {
                    var course = _courses[index];
                    return table.Table(
                      course.name,
                      course,
                      Column(
                        children: <Widget>[
                          DataTable(
                            columns: [
                              DataColumn(label: Text('Atividade')),
                              DataColumn(label: Text('Total')),
                              DataColumn(label: Text('Nota')),
                            ],
                            rows: course.grades.map(
                              (g) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(g.activityName)),
                                    DataCell(Text(g.totalValue)),
                                    DataCell(_verifyShowGrades(g.scoreValue)),
                                  ],
                                );
                              },
                            ).toList(),
                          ),
                          Padding(
                            padding: EdgeInsets.all(10),
                            child: _verifyShowTotal(course),
                          )
                        ],
                      ),
                    );
                  },
                  itemCount: _courses.length,
                ),
        ),
      ),
    );
  }

  double _sumOfGrades(List<Grade> grades) => grades
      .map((g) => double.tryParse(g.scoreValue))
      .where((e) => e != null)
      .fold(0, (a, e) => a + e);

  Widget _getShowGradesIcon() =>
      Icon(_showGrades ? Icons.visibility : Icons.visibility_off);

  void _switchShowGrades() {
    setState(() {
      this._showGrades = !this._showGrades;
    });

    Application.layoutObserver.emit(
      LayoutGlobalState(title: 'Notas', singlePage: false, actions: <Widget>[
        IconButton(icon: _getShowGradesIcon(), onPressed: _switchShowGrades)
      ]),
    );
  }

  Widget _verifyShowGrades(String text) {
    if (this._showGrades) {
      return Text(text);
    } else if (text.length > 0) {
      return Text('____');
    }
    return Text('');
  }

  Widget _verifyShowTotal(var course) {
    if (this._showGrades) {
      return Text(
        sprintf('Total: %3.2f', [_sumOfGrades(course.grades)]),
        style: TextStyle(fontWeight: FontWeight.bold),
      );
    }
    return Text(
      "Total: ______",
      style: TextStyle(fontWeight: FontWeight.bold),
    );
  }
}
