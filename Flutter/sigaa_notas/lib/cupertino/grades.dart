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

import 'package:collection/collection.dart' show IterableNullableExtension;
import 'package:flutter/cupertino.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:sigaa_notas/common/grades.dart';
import 'package:sigaa_notas/common/observer.dart';
import 'package:sigaa_notas/common/sigaa.dart';
import 'package:sigaa_notas/common/utils.dart';
import 'package:sigaa_notas/cupertino/app.dart';
import 'package:sigaa_notas/cupertino/empty_list_view.dart';
import 'package:sprintf/sprintf.dart';

class Grades extends StatefulWidget {
  const Grades({Key? key}) : super(key: key);

  @override
  _GradesState createState() => _GradesState();
}

class _GradesState extends State<Grades> {
  final _courses = <Course>[];
  final _refreshController = RefreshController(initialRefresh: true);
  late Subscription<bool> _updateSubscription;
  bool _showGrades = true;

  @override
  void initState() {
    super.initState();

    getCourses().then((courses) {
      if (!mounted) return;

      setState(() {
        _courses.clear();
        _courses.addAll(courses);
      });
    });

    _updateSubscription = Application.updateObserver.subscribe((_) {
      _refreshController.requestRefresh();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _updateSubscription.unsubscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Application.theme(
      CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Notas'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _switchShowGrades,
            child: _getShowGradesIcon(),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
              constraints: const BoxConstraints.tightForFinite(width: 600),
              child: SmartRefresher(
                controller: _refreshController,
                onRefresh: _refresh,
                child: _courses.isEmpty
                    ? const EmptyListPage()
                    : ListView.separated(
                        separatorBuilder: (c, i) => _separator(),
                        itemBuilder: (_, i) => _courseEntry(_courses[i]),
                        itemCount: _courses.length,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget text(textStyle, t, f) {
    return Text(t, style: textStyle.apply(fontSizeFactor: f));
  }

  Widget _courseEntry(Course course) {
    final textStyle = CupertinoTheme.of(context).textTheme.textStyle;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: <Widget>[
          const Padding(padding: EdgeInsets.all(10)),
          text(textStyle, course.name, 1.2),
          course.grades!.isEmpty
              ? Column(
                  children: <Widget>[
                    const Padding(padding: EdgeInsets.all(10)),
                    text(textStyle, 'A matéria não possui notas cadastradas',
                        0.8),
                    const Padding(padding: EdgeInsets.all(10)),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Column(
                    children: <Widget>[
                      Column(
                        children: [
                              _separator(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: ['Atividade', 'Total', 'Nota']
                                        .mapIndex((e, i) => Expanded(
                                              flex: i == 0 ? 2 : 1,
                                              child: text(textStyle, e, 0.8),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              )
                            ] +
                            course.grades!
                                .map(
                                  (grade) => _separator(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: text(textStyle,
                                                grade.activityName, 0.8),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: text(textStyle,
                                                grade.totalValue, 0.8),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: _verifyShowGrades(
                                                grade.scoreValue),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                      const Padding(padding: EdgeInsets.all(8)),
                      _verifyShowTotal(course)
                    ],
                  ),
                )
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    await GradesService.refresh().then((courses) async {
      _refreshController.refreshCompleted();

      if (mounted) {
        setState(() {
          _courses.clear();
          _courses.addAll(courses);
        });
      }
    }).catchError((_) {
      if (mounted) {
        showToast("Erro de conexão");
        _refreshController.refreshFailed();
      }
    });
  }

  Widget _separator({Widget? child}) => Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(width: 0.0, color: CupertinoColors.inactiveGray),
          ),
        ),
        child: child,
      );

  double _sumOfGrades(List<Grade> grades) => grades
      .map((g) => double.tryParse(g.scoreValue))
      .whereNotNull()
      .fold(0, (a, e) => a + e);

  Widget _getShowGradesIcon() => Icon(
      _showGrades ? CupertinoIcons.group_solid : CupertinoIcons.person_solid);

  void _switchShowGrades() {
    setState(() {
      _showGrades = !_showGrades;
    });
  }

  Widget _verifyShowGrades(String? grade) {
    final textStyle = CupertinoTheme.of(context).textTheme.textStyle;

    if (_showGrades) {
      return text(textStyle, grade, 0.8);
    } else if (grade!.isNotEmpty) {
      return text(textStyle, '____', 0.8);
    }

    return const Text('');
  }

  Widget _verifyShowTotal(var course) {
    final textStyle = CupertinoTheme.of(context).textTheme.textStyle;

    return _showGrades
        ? text(textStyle,
            sprintf('Total: %3.2f', [_sumOfGrades(course.grades)]), 0.8)
        : text(textStyle, "Total: ______", 0.8);
  }
}

extension ExtendedIterable<E> on Iterable<E> {
  Iterable<T> mapIndex<T>(T Function(E e, int i) f) {
    var i = 0;
    return map((e) => f(e, i++));
  }
}
