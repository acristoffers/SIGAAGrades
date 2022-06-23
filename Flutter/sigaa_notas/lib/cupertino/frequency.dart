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

import 'package:flutter/cupertino.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:sigaa_notas/common/frequency.dart';
import 'package:sigaa_notas/common/sigaa.dart';
import 'package:sigaa_notas/common/utils.dart';
import 'package:sigaa_notas/cupertino/app.dart';
import 'package:sigaa_notas/cupertino/empty_list_view.dart';
import 'package:sprintf/sprintf.dart';

class FrequencyPage extends StatefulWidget {
  @override
  _FrequencyState createState() => _FrequencyState();
}

class _FrequencyState extends State<FrequencyPage> {
  final _courses = <Course>[];
  final _refreshController = RefreshController(initialRefresh: true);

  @override
  Widget build(BuildContext context) {
    final textStyle = CupertinoTheme.of(context).textTheme.textStyle;
    final text = (t, f) => Text(t, style: textStyle.apply(fontSizeFactor: f));
    return Application.theme(
      CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          leading: CupertinoButton(
            onPressed: _refresh,
            child: const Text("Atualizar"),
          ),
          middle: const Text('Frequência'),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints.tightForFinite(width: 600),
              child: SmartRefresher(
                controller: _refreshController,
                onRefresh: _refresh,
                child: _courses.isEmpty
                    ? EmptyListPage()
                    : ListView.separated(
                        separatorBuilder: (_, i) => _separator(),
                        itemCount: _courses.length,
                        itemBuilder: (c, i) {
                          final course = _courses[i];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              text(course.name, 1.2),
                              const Padding(padding: EdgeInsets.only(top: 8.0)),
                              text(
                                  (course.frequency.totalClasses == 0 ||
                                          course.frequency.givenClasses == 0)
                                      ? "Não lançadas"
                                      : sprintf(
                                          'Presença: %d (%3.2f%% do total, %3.2f%% das ministradas)',
                                          [
                                            course.frequency.presence,
                                            100 *
                                                course.frequency.presence /
                                                course.frequency.totalClasses,
                                            100 *
                                                course.frequency.presence /
                                                course.frequency.givenClasses,
                                          ],
                                        ),
                                  0.8)
                            ],
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _refresh() async {
    await FrequencyService.refresh().then((courses) {
      _refreshController.refreshCompleted();
      if (mounted) {
        setState(() {
          _courses.clear();
          _courses.addAll(courses);
        });
      }
    }).catchError((_) => showToast("Erro de conexão"));
  }

  Widget _separator({Widget child}) => Padding(
        padding: const EdgeInsets.only(bottom: 16.0, top: 16.0),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            border: Border(
              bottom:
                  BorderSide(width: 0.0, color: CupertinoColors.inactiveGray),
            ),
          ),
          child: child,
        ),
      );
}
