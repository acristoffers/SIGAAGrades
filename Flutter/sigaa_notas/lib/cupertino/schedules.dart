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
import 'package:flutter/cupertino.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:sigaa_notas/common/observer.dart';
import 'package:sigaa_notas/common/schedules.dart';
import 'package:sigaa_notas/common/sigaa.dart';
import 'package:sigaa_notas/common/utils.dart';
import 'package:sigaa_notas/cupertino/app.dart';
import 'package:sigaa_notas/cupertino/empty_list_view.dart';

class Schedules extends StatefulWidget {
  @override
  _SchedulesState createState() => _SchedulesState();
}

class _SchedulesState extends State<Schedules> {
  final _schedules = List<Schedule>();
  final _refreshController = RefreshController(initialRefresh: true);
  Subscription<bool> _updateSubscription;
  bool showGrades = true;

  @override
  void initState() {
    super.initState();

    getSchedules().then((schedules) {
      if (!mounted) return;

      setState(() {
        _schedules.clear();
        _schedules.addAll(schedules);
      });
    });

    _updateSubscription = Application.updateObserver.subscribe((_) {
      return _refreshController.requestRefresh();
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
          middle: const Text('Horários'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(CupertinoIcons.bookmark_solid),
            onPressed: () {
              return _addToCalendar().catchError((e) {
                if (mounted) {
                  switch (e.reason) {
                    case 'no-permission':
                      showToast('Sem permissão para acessar o calendário.');
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
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              padding: EdgeInsets.all(10),
              constraints: BoxConstraints.tightForFinite(width: 600),
              child: SmartRefresher(
                controller: _refreshController,
                onRefresh: _refresh,
                child: _schedules.isEmpty
                    ? EmptyListPage()
                    : ListView(
                        children: <Widget>[
                          _todayEntry(),
                          _dayEntry(2, 'Segunda'),
                          _dayEntry(3, 'Terça'),
                          _dayEntry(4, 'Quarta'),
                          _dayEntry(5, 'Quinta'),
                          _dayEntry(6, 'Sexta'),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Text _text(String text, double factor) {
    final textStyle = CupertinoTheme.of(context).textTheme.textStyle;
    return Text(text, style: textStyle.apply(fontSizeFactor: factor));
  }

  Widget _todayEntry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _text('Hoje', 1.2),
        _separator(),
        ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (BuildContext context, int index) {
              final s = SchedulesService.todaySchedules(_schedules)[index];
              return Column(
                children: <Widget>[
                  _text(s.course, 1),
                  _text('De ${s.start} até ${s.end}. Local: ${s.local}', 0.8)
                ],
              );
            },
            itemCount: SchedulesService.todaySchedules(_schedules).length)
      ],
    );
  }

  Widget _dayEntry(int day, String dayName) {
    var sortedForDay = SchedulesService.sortedForDay(_schedules, day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _text(dayName, 1.2),
        Padding(
          padding: const EdgeInsets.only(left: 32.0, top: 8.0),
          child: ListView.separated(
              separatorBuilder: (_, i) => _separator(),
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) {
                final s = sortedForDay[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _text(s.course, 1),
                    _text('De ${s.start} até ${s.end}. Local: ${s.local}', 0.8)
                  ],
                );
              },
              itemCount: sortedForDay.length),
        ),
        _separator(),
      ],
    );
  }

  Widget _separator({Widget child}) => Padding(
        padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
        child: Container(
          width: double.infinity,
          child: child,
          decoration: BoxDecoration(
            border: Border(
              bottom:
                  BorderSide(width: 0.0, color: CupertinoColors.inactiveGray),
            ),
          ),
        ),
      );

  Future<void> _refresh() async {
    await SchedulesService.refresh().then((schedules) async {
      _refreshController.refreshCompleted();

      if (mounted) {
        setState(() {
          _schedules.clear();
          _schedules.addAll(schedules);
        });
      }
    }).catchError((_) {
      if (mounted) {
        showToast("Erro de conexão");
        _refreshController.refreshFailed();
      }
    });
  }

  Future<Calendar> _showDialog(List<Calendar> calendars) async {
    return await showCupertinoModalPopup(
      context: context,
      builder: (c) => CupertinoActionSheet(
        title: Text('Selecione o calendário'),
        cancelButton: CupertinoDialogAction(
          child: Text('Cancelar'),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop(null);
          },
        ),
        actions: calendars
            .map((c) => CupertinoDialogAction(
                  child: Text(c.name),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop(c);
                  },
                ))
            .toList(),
      ),
    );
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
