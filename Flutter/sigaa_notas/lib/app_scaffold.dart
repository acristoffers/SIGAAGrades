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

import 'package:flutter/material.dart';
import 'package:sigaa_notas/drawer.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold(
      {@required this.body,
      @required this.appBar,
      this.floatingActionButton,
      this.pageTitle = '',
      this.heroTag = 'logo',
      Key key})
      : super(key: key);

  final FloatingActionButton floatingActionButton;
  final AppBar appBar;
  final Widget body;
  final String pageTitle;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width < 900) {
      return Scaffold(
        appBar: appBar,
        drawer: Drawer(
          child: DrawerPage(heroTag),
        ),
        body: Center(
          child: Container(
              constraints: BoxConstraints.tightForFinite(width: 600),
              child: body),
        ),
        floatingActionButton: floatingActionButton,
      );
    } else {
      return Row(
        children: <Widget>[
          Drawer(
            child: DrawerPage(heroTag),
          ),
          Expanded(
            child: Scaffold(
              appBar: appBar,
              body: Center(
                child: Container(
                  alignment: Alignment.center,
                  constraints: BoxConstraints.tightForFinite(width: 600),
                  child: body,
                ),
              ),
              floatingActionButton: floatingActionButton,
            ),
          )
        ],
      );
    }
  }
}
