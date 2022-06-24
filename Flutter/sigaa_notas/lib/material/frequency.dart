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
import 'package:sigaa_notas/common/frequency.dart';
import 'package:sigaa_notas/common/sigaa.dart';
import 'package:sigaa_notas/common/utils.dart';
import 'package:sigaa_notas/material/app.dart';
import 'package:sigaa_notas/material/empty_list_view.dart';
import 'package:sigaa_notas/material/layout.dart';
import 'package:sprintf/sprintf.dart';

class FrequencyPage extends StatefulWidget {
  const FrequencyPage({Key? key}) : super(key: key);

  @override
  _FrequencyState createState() => _FrequencyState();
}

class _FrequencyState extends State<FrequencyPage> {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  final _courses = <Course>[];

  @override
  void initState() {
    super.initState();

    Application.layoutObserver.emit(
      LayoutGlobalState(
        title: 'Frequência',
        singlePage: false,
        actions: <Widget>[],
      ),
    );

    Timer.run(() => _refreshIndicatorKey.currentState!.show());
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints.tightForFinite(width: 600),
        child: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: () async {
            await FrequencyService.refresh().then((courses) {
              if (mounted) {
                setState(() {
                  _courses.clear();
                  _courses.addAll(courses);
                });
              }
            }).catchError((_) {
              showToast("Erro de conexão");
            });
          },
          child: _courses.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height,
                    child: const EmptyListPage(),
                  ),
                )
              : ListView.builder(
                  itemBuilder: (BuildContext context, int index) {
                    final course = _courses[index];
                    return Card(
                      margin: const EdgeInsets.all(5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Text(course.name),
                        subtitle: Text(
                          (course.frequency!.totalClasses == 0 ||
                                  course.frequency!.givenClasses == 0)
                              ? "Não lançadas"
                              : sprintf(
                                  'Presença: %d (%3.2f%% do total, %3.2f%% das ministradas)',
                                  [
                                    course.frequency!.presence,
                                    100 *
                                        course.frequency!.presence /
                                        course.frequency!.totalClasses,
                                    100 *
                                        course.frequency!.presence /
                                        course.frequency!.givenClasses,
                                  ],
                                ),
                        ),
                      ),
                    );
                  },
                  itemCount: _courses.length,
                ),
        ),
      ),
    );
  }
}
