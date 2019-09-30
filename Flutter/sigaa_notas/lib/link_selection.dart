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
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaa_notas/empty_list_view.dart';
import 'package:sigaa_notas/grades.dart';
import 'package:sigaa_notas/sigaa.dart';
import 'package:sigaa_notas/utils.dart';
import 'package:sqflite/sqflite.dart';
import 'package:toast/toast.dart';

class LinkSelectionPage extends StatefulWidget {
  @override
  _LinkSelectionState createState() => _LinkSelectionState();
}

class _LinkSelectionState extends State<LinkSelectionPage> {
  List<Link> _links = [];
  Database _db;
  final _sigaa = SIGAA();
  final _refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();

    getDatabase()
        .then((db) => _db = db)
        .then((_) => _db.delete('links', where: null))
        .then((_) => SchedulerBinding.instance.addPostFrameCallback((_) {
              _refreshIndicatorKey.currentState.show();
            }))
        .catchError((_) {
      Toast.show(
        "Erro de conexão",
        context,
        duration: Toast.LENGTH_LONG,
        gravity: Toast.BOTTOM,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Seleção de Vínculo')),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: () async {
            await _refresh()
                .catchError((_) => showToast(context, "Erro de conexão"));
          },
          child: _links.length == 0
              ? ListView(
                  children: <Widget>[EmptyListPage()],
                )
              : ListView.builder(
                  itemBuilder: (BuildContext context, int index) {
                    var link = _links[index];
                    return ListTile(
                      title: Text(link.name),
                      subtitle: Text(link.immatriculation),
                      onTap: () async => await _selectLink(link),
                    );
                  },
                  itemCount: _links.length,
                ),
        ),
      ),
    );
  }

  Future<void> _selectLink(Link link) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('link', link.url);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (c) => GradesPage()),
    );
  }

  Future<void> _refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final password = prefs.getString('password');

    await _sigaa.login(username, password);
    final links = await _sigaa.listLinks();

    _db.delete('links', where: null).then((_) {
      links.forEach((l) => _db.insert('links', {'name': l.name, 'url': l.url}));
    });

    if (links.length > 1) {
      setState(() => _links = links);
    } else {
      prefs.setString('link', links.first.url);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (c) => GradesPage()),
      );
    }
  }
}
