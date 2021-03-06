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

import 'dart:async' show Timer;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaa_notas/common/links.dart';
import 'package:sigaa_notas/common/sigaa.dart';
import 'package:sigaa_notas/common/utils.dart';
import 'package:sigaa_notas/material/app.dart';
import 'package:sigaa_notas/material/empty_list_view.dart';
import 'package:sigaa_notas/material/layout.dart';

class LinkSelectionPage extends StatefulWidget {
  @override
  _LinkSelectionState createState() => _LinkSelectionState();
}

class _LinkSelectionState extends State<LinkSelectionPage> {
  List<Link> _links = [];
  final _refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();

    Application.layoutObserver.emit(
      LayoutGlobalState(
        title: 'Seleção de Vínculo',
        singlePage: true,
        actions: <Widget>[],
      ),
    );

    Timer.run(() => _refreshIndicatorKey.currentState.show());
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
            await LinksService.refresh().then((links) async {
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
                Navigator.pushReplacementNamed(context, '/grades');
              }
            }).catchError((_) {
              if (mounted) {
                showToast("Erro de conexão");
              }
            });
          },
          child: _links.length == 0
              ? SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height,
                    child: EmptyListPage(),
                  ),
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
    Navigator.pushReplacementNamed(context, '/grades');
  }
}
