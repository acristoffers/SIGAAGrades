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
import 'package:flutter_cupertino_settings/flutter_cupertino_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaa_notas/common/schedules.dart';
import 'package:sigaa_notas/cupertino/app.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Application.theme(
      CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Configurações'),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              padding: EdgeInsets.all(10),
              constraints: BoxConstraints.tightForFinite(width: 600),
              child: FutureBuilder<SharedPreferences>(
                future: SharedPreferences.getInstance(),
                builder: (_, prefs) {
                  if (!prefs.hasData) {
                    return Container();
                  }
                  return CupertinoSettings(
                    items: [
                      const CSHeader('Horários'),
                      CSSelection<int>(
                        items: const <CSSelectionItem<int>>[
                          CSSelectionItem<int>(text: 'Campus II', value: 2),
                          CSSelectionItem<int>(text: 'Campus V', value: 5),
                        ],
                        onSelected: (v) async {
                          final prefs = await SharedPreferences.getInstance();
                          prefs.setInt('scheduleType', v);
                          await SchedulesService.refresh();
                        },
                        currentSelection: prefs.data.getInt('scheduleType'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
