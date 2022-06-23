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
import 'package:sigaa_notas/common/utils.dart';

class DrawerPage extends StatelessWidget {
  final bool docked;
  final String heroTag;

  const DrawerPage({this.docked = false, this.heroTag = 'logo'});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        DrawerHeader(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.topLeft,
                colors: [
                  Colors.indigo,
                  docked ? Colors.indigo : Colors.indigoAccent
                ]),
          ),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(context, '/about'),
              child: Column(
                children: <Widget>[
                  Hero(
                    tag: heroTag,
                    child: Image.asset('assets/images/logo.png', width: 100),
                  ),
                  const Text(
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
          ),
        ),
        ListTile(
          title: Row(
            children: const <Widget>[
              Icon(Icons.assignment),
              Padding(padding: EdgeInsets.all(10)),
              Text('Notas'),
            ],
          ),
          onTap: () => Navigator.pushReplacementNamed(context, '/grades'),
        ),
        ListTile(
          title: Row(
            children: const <Widget>[
              Icon(Icons.timelapse),
              Padding(padding: EdgeInsets.all(10)),
              Text('Horários'),
            ],
          ),
          onTap: () => Navigator.pushReplacementNamed(context, '/schedules'),
        ),
        ListTile(
          title: Row(
            children: const <Widget>[
              Icon(Icons.airline_seat_recline_normal),
              Padding(padding: EdgeInsets.all(10)),
              Text('Frequência'),
            ],
          ),
          onTap: () => Navigator.pushReplacementNamed(context, '/frequency'),
        ),
        ListTile(
          title: Row(
            children: const <Widget>[
              Icon(Icons.assignment_ind),
              Padding(padding: EdgeInsets.all(10)),
              Text('Alterar Vínculo'),
            ],
          ),
          onTap: () => Navigator.pushReplacementNamed(context, '/links'),
        ),
        ListTile(
          title: Row(
            children: const <Widget>[
              Icon(Icons.settings),
              Padding(padding: EdgeInsets.all(10)),
              Text('Configurações'),
            ],
          ),
          onTap: () => Navigator.pushReplacementNamed(context, '/settings'),
        ),
        ListTile(
          title: Row(
            children: const <Widget>[
              Icon(Icons.assessment),
              Padding(padding: EdgeInsets.all(10)),
              Text('Sobre'),
            ],
          ),
          onTap: () => Navigator.pushReplacementNamed(context, '/about'),
        ),
        ListTile(
          title: Row(
            children: const <Widget>[
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
            await db.delete('schedules', where: null);
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ],
    );
  }
}
