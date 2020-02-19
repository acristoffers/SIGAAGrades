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
import 'dart:io';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:sigaa_notas/common/schedules.dart';
import 'package:sigaa_notas/common/sigaa.dart';
import 'package:sigaa_notas/common/utils.dart';
import 'package:sigaa_notas/material/app.dart';
import 'package:sigaa_notas/material/grades_table.dart' as table;
import 'package:sigaa_notas/material/layout.dart';

class SchedulesPage extends StatefulWidget {
  @override
  _SchedulesState createState() => _SchedulesState();
}

class _SchedulesState extends State<SchedulesPage> {
  final _refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();
  final _schedules = <Schedule>[];

  @override
  void initState() {
    super.initState();

    Application.layoutObserver.emit(
      LayoutGlobalState(
        title: 'Horários',
        singlePage: false,
        actions: Platform.isAndroid || Platform.isIOS
            ? <Widget>[
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  tooltip: 'Adicionar ao calendário',
                  onPressed: () {
                    return _addToCalendar().catchError((e) {
                      if (mounted) {
                        switch (e.reason) {
                          case 'no-permission':
                            showToast(
                                'Sem permissão para acessar o calendário.');
                            break;
                          case 'calendar-fetch':
                            showToast('Erro ao listar os calendários.');
                            break;
                          case 'no-calendar':
                            showToast('Não há calendários no dispositivo.');
                            break;
                          case 'cancelled':
                            showToast('Operação cancelada.');
                            break;
                          default:
                            showToast('Erro ao adicionar ao calendário.');
                        }
                      }
                    });
                  },
                )
              ]
            : <Widget>[],
      ),
    );

    getSchedules().then((schedules) {
      if (!mounted) return;

      if (schedules.length == 0) {
        Timer.run(_refreshIndicatorKey.currentState.show);
      }

      setState(() {
        _schedules.clear();
        _schedules.addAll(schedules);
      });
    });
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
            await SchedulesService.refresh().then((schedules) {
              if (mounted) {
                setState(() {
                  _schedules.clear();
                  _schedules.addAll(schedules);
                });
              }
            });
          },
          child: ListView(
            children: <Widget>[
              _todayCard(),
              Padding(padding: EdgeInsets.all(10)),
              _dayCard(2, 'Segunda'),
              _dayCard(3, 'Terça'),
              _dayCard(4, 'Quarta'),
              _dayCard(5, 'Quinta'),
              _dayCard(6, 'Sexta'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _todayCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              final s = SchedulesService.todaySchedules(_schedules)[index];
              return ListTile(
                title: Text(
                  s.course,
                  style: TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  'De ${s.start} até ${s.end}. Local: ${s.local}',
                ),
              );
            },
            itemCount: SchedulesService.todaySchedules(_schedules).length),
      ),
    );
  }

  Widget _dayCard(int day, String dayName) {
    return table.Table(
      dayName,
      null,
      ListView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index) {
            final s = SchedulesService.sortedForDay(_schedules, day)[index];
            return ListTile(
              title: Text(
                s.course,
                style: TextStyle(fontSize: 13),
              ),
              subtitle: Text(
                'De ${s.start} até ${s.end}. Local: ${s.local}',
              ),
            );
          },
          itemCount: _schedules.where((s) => s.day == day).length),
    );
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

  Future<void> _addToCalendar() async {
    final calendars = await SchedulesService.listCalendars();

    if (calendars.isEmpty) {
      throw SimpleException('no-calendars');
    }

    final calendar = await _showDialog(calendars);
    if (calendar == null) {
      throw SimpleException('cancelled');
    }

    showToast('Buscando datas de início e fim do semestre...');

    await SchedulesService.addToCalendar(calendar, _schedules);
  }
}
