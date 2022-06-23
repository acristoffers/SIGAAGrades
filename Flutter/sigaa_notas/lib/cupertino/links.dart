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

import 'package:flutter/cupertino.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaa_notas/common/links.dart';
import 'package:sigaa_notas/common/sigaa.dart';
import 'package:sigaa_notas/common/utils.dart';
import 'package:sigaa_notas/cupertino/app.dart';
import 'package:sigaa_notas/cupertino/empty_list_view.dart';
import 'package:sigaa_notas/cupertino/layout.dart';

class LinkSelectionPage extends StatefulWidget {
  @override
  _LinkSelectionState createState() => _LinkSelectionState();
}

class _LinkSelectionState extends State<LinkSelectionPage> {
  final _links = <Link>[];
  final _refreshController = RefreshController(initialRefresh: true);

  @override
  Widget build(BuildContext context) {
    return Application.theme(
      CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Seleção de Vínculo'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Text('Sair'),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              prefs.remove('username');
              prefs.remove('password');
              prefs.remove('link');
              final db = await getDatabase();
              await db.delete('links', where: null);
              await db.delete('courses', where: null);
              await db.delete('grades', where: null);
              await db.delete('schedules', where: null);
              LayoutState.current().navigate('/login');
            },
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints.tightForFinite(width: 600),
              child: SmartRefresher(
                controller: _refreshController,
                onRefresh: _refresh,
                child: _links.isEmpty
                    ? EmptyListPage()
                    : ListView.separated(
                        separatorBuilder: (c, i) => Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  width: 0.0,
                                  color: CupertinoColors.inactiveGray),
                            ),
                          ),
                        ),
                        itemBuilder: (_, i) {
                          var link = _links[i];
                          return GestureDetector(
                            onTap: () async => await _selectLink(link),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    link.name,
                                    style: CupertinoTheme.of(context)
                                        .textTheme
                                        .textStyle,
                                  ),
                                  Text(
                                    link.immatriculation,
                                    style: CupertinoTheme.of(context)
                                        .textTheme
                                        .textStyle,
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                        itemCount: _links.length,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectLink(Link link) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('link', link.url);
    Application.updateObserver.emit(true);
    LayoutState.current().navigate('/grades');
  }

  Future<void> _refresh() async {
    await LinksService.refresh().then((links) async {
      _refreshController.refreshCompleted();

      if (links.length > 1) {
        if (mounted) {
          setState(() {
            _links.clear();
            _links.addAll(links);
          });
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('link', links.first.url);
        LayoutState.current().navigate('/grades');
      }
    }).catchError((_) {
      if (mounted) {
        showToast("Erro de conexão");
        _refreshController.refreshFailed();
      }
    });
  }
}
