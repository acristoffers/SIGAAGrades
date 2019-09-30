/*
 * Copyright (c) 2019 Álan Crístoffer
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the 'Software'), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaa_notas/about.dart';
import 'package:sigaa_notas/frequency.dart';
import 'package:sigaa_notas/grades.dart';
import 'package:sigaa_notas/link_selection.dart';
import 'package:sigaa_notas/login.dart';
import 'package:sigaa_notas/schedules.dart';
import 'package:sigaa_notas/settings.dart';
import 'package:sigaa_notas/utils.dart';

class DrawerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        DrawerHeader(
          child: Center(
            child: Column(
              children: <Widget>[
                Image.asset(
                  'assets/images/logo.png',
                  width: 100,
                ),
                Text(
                  'SIGAA:Notas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          decoration: BoxDecoration(
            color: Colors.indigo,
          ),
        ),
        ListTile(
          title: Row(
            children: <Widget>[
              Icon(Icons.assignment),
              Padding(padding: EdgeInsets.all(10)),
              Text('Notas'),
            ],
          ),
          onTap: () => _navigate(context, (_) => GradesPage()),
        ),
        ListTile(
          title: Row(
            children: <Widget>[
              Icon(Icons.timelapse),
              Padding(padding: EdgeInsets.all(10)),
              Text('Horários'),
            ],
          ),
          onTap: () => _navigate(context, (_) => SchedulesPage()),
        ),
        ListTile(
          title: Row(
            children: <Widget>[
              Icon(Icons.airline_seat_recline_normal),
              Padding(padding: EdgeInsets.all(10)),
              Text('Frequência'),
            ],
          ),
          onTap: () => _navigate(context, (_) => FrequencyPage()),
        ),
        ListTile(
          title: Row(
            children: <Widget>[
              Icon(Icons.assignment_ind),
              Padding(padding: EdgeInsets.all(10)),
              Text('Alterar Vínculo'),
            ],
          ),
          onTap: () => _navigate(context, (_) => LinkSelectionPage()),
        ),
        ListTile(
          title: Row(
            children: <Widget>[
              Icon(Icons.settings),
              Padding(padding: EdgeInsets.all(10)),
              Text('Configurações'),
            ],
          ),
          onTap: () => _navigate(context, (_) => SettingsPage()),
        ),
        ListTile(
          title: Row(
            children: <Widget>[
              Icon(Icons.assessment),
              Padding(padding: EdgeInsets.all(10)),
              Text('Sobre'),
            ],
          ),
          onTap: () => _navigate(context, (_) => AboutPage()),
        ),
        ListTile(
          title: Row(
            children: <Widget>[
              Icon(Icons.transit_enterexit),
              Padding(padding: EdgeInsets.all(10)),
              Text('Sair'),
            ],
          ),
          onTap: () async {
            final prefs = await SharedPreferences.getInstance();
            prefs.remove('username');
            prefs.remove('password');
            prefs.remove('link');
            final db = await getDatabase();
            await db.delete('links', where: null);
            await db.delete('courses', where: null);
            await db.delete('grades', where: null);
            _navigate(context, (_) => LoginPage());
          },
        ),
      ],
    );
  }
}

void _navigate(BuildContext context, WidgetBuilder builder) =>
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: builder),
    );
