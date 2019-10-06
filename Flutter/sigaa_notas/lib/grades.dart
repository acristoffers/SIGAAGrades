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
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';
import 'package:quiver/iterables.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaa_notas/drawer.dart';
import 'package:sigaa_notas/empty_list_view.dart';
import 'package:sigaa_notas/sigaa.dart';
import 'package:sigaa_notas/utils.dart';
import 'package:sprintf/sprintf.dart';
import 'package:sqflite/sqflite.dart';
import 'widgets/table.dart' as table;

class GradesPage extends StatefulWidget {
  @override
  _GradesState createState() => _GradesState();
}

class _GradesState extends State<GradesPage> {
  final _sigaa = SIGAA();
  final _refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();
  final _courses = <Course>[];
  Database _db;
  bool showGrades= true;

  @override
  void initState() {
    super.initState();

    getDatabase().then((db) => _db = db);

    getCourses().then((courses) {
      if (courses.length == 0) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _refreshIndicatorKey.currentState.show();
        });
      }

      setState(() {
        _courses.clear();
        _courses.addAll(courses);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notas'),
        actions: <Widget>[
          IconButton(
              icon: _getShowGradesIcon(),
              onPressed: _switchShowGrades)
        ],
      ),
      drawer: Drawer(
        child: DrawerPage('logo'),
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          await _refresh()
              .catchError((_) => showToast(context, "Erro de conexão"));
        },
        child: _courses.length == 0
            ? ListView(
          children: <Widget>[EmptyListPage()],
        )
            : ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            var course = _courses[index];
            return table.Table(course.name, course,
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
                      child: _verifyShowTotal(course)
                    )
                  ],
                )
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
    final fs = await Future.wait(courses.map((c) => _sigaa.listGrades(c)));

    zip([fs, courses]).forEach((e) => (e[1] as Course).grades = e[0]);

    setState(() {
      _courses.clear();
      _courses.addAll(courses);
    });

    final links = await _db.query('links', where: 'url=?', whereArgs: [link]);
    final linkID = links.first['id'];

    await _db.delete('courses', where: null);
    await _db.delete('grades', where: null);
    for (final course in courses) {
      final courseDict = {
        'name': course.name,
        'cid': course.cid,
        'link': linkID,
      };

      final id = await _db.insert('courses', courseDict);

      for (final grade in course.grades) {
        final gradeDict = {
          'activityName': grade.activityName,
          'scoreValue': grade.scoreValue,
          'totalValue': grade.totalValue,
          'course': id,
        };

        await _db.insert('grades', gradeDict);
      }
    }
  }

  double _sumOfGrades(List<Grade> grades) {
    var x = 0.0;
    for (final g in grades) {
      final t = double.tryParse(g.scoreValue);
      if (t != null) {
        x += t;
      }
    }
    return x;
  }

  Widget _getShowGradesIcon(){
    if(this.showGrades){
      return Icon( Icons.visibility);
    }else{
      return Icon( Icons.visibility_off);
    }
  }

  void _switchShowGrades()async{
    setState(() {
      this.showGrades = !this.showGrades;
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('showGrades', this.showGrades);
  }

  Widget _verifyShowGrades(String text){
    if(this.showGrades){
      return Text(text);
    }
    if(text.length > 0){
      return Text("_____");
    }
    return Text(" ");
  }

  Widget _verifyShowTotal(var course){
    if(this.showGrades){
      return Text(
        sprintf(
          'Total: %3.2f',
          [_sumOfGrades(course.grades)],
        ),
        style: TextStyle(fontWeight: FontWeight.bold),
      );
    }
    return Text("Total: ______",
        style: TextStyle(fontWeight: FontWeight.bold),
        );
  }

}
