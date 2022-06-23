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

import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaa_notas/common/schedules.dart';
import 'package:sigaa_notas/material/app.dart';
import 'package:sigaa_notas/material/layout.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<SettingsPage> {
  int _scheduleType = 5;

  @override
  void initState() {
    super.initState();

    Application.layoutObserver.emit(LayoutGlobalState(
      title: 'Configurações',
      singlePage: false,
      actions: [],
    ));

    SharedPreferences.getInstance().then((prefs) {
      if (prefs.containsKey('scheduleType')) {
        setState(() {
          _scheduleType = prefs.getInt('scheduleType');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints.tightForFinite(width: 600),
        child: ListView(
          children: <Widget>[
            const Text('Tema'),
            SwitchListTile(
              title: const Text('Tema Escuro'),
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (_) => toggleDarkTheme(context),
              activeColor: Theme.of(context).colorScheme.secondary,
            ),
            const Text('Formato de Horários'),
            RadioListTile(
              title: const Text('Campus II'),
              value: 2,
              groupValue: _scheduleType,
              onChanged: (int v) async {
                final prefs = await SharedPreferences.getInstance();
                prefs.setInt('scheduleType', v);
                setState(() => _scheduleType = v);
                SchedulesService.refresh().whenComplete(() => null);
              },
            ),
            RadioListTile(
              title: const Text('Campus V'),
              value: 5,
              groupValue: _scheduleType,
              onChanged: (int v) async {
                final prefs = await SharedPreferences.getInstance();
                prefs.setInt('scheduleType', v);
                setState(() => _scheduleType = v);
                SchedulesService.refresh().whenComplete(() => null);
              },
            )
          ],
        ),
      ),
    );
  }
}

void toggleDarkTheme(BuildContext context) {
  DynamicTheme.of(context)
      .setTheme(Theme.of(context).brightness == Brightness.dark ? 0 : 1);
}
