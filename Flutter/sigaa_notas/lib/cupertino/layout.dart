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
import 'package:sigaa_notas/cupertino/about.dart';
import 'package:sigaa_notas/cupertino/app.dart';
import 'package:sigaa_notas/cupertino/frequency.dart';
import 'package:sigaa_notas/cupertino/links.dart';
import 'package:sigaa_notas/cupertino/login.dart';
import 'package:sigaa_notas/cupertino/schedules.dart';

import 'grades.dart';

class Layout extends StatefulWidget {
  Layout({key}) : super(key: key);

  @override
  LayoutState createState() => LayoutState();
}

class LayoutState extends State<Layout> {
  final _tabController = CupertinoTabController(initialIndex: 0);
  Widget _currentWidget = Login();

  static LayoutState current() => Application.layoutKey.currentState;

  @override
  Widget build(BuildContext context) {
    return _currentWidget != null ? _currentWidget : _multiPageLayout();
  }

  void navigate(String route) {
    switch (route) {
      case '/links':
        setState(() {
          _currentWidget = LinkSelectionPage();
        });
        break;
      case '/grades':
        setState(() {
          _currentWidget = null;
          _tabController.index = 0;
        });
        break;
      case '/schedules':
        setState(() {
          _currentWidget = null;
          _tabController.index = 1;
        });
        break;
      case '/frequency':
        setState(() {
          _currentWidget = null;
          _tabController.index = 2;
        });
        break;
      default:
        setState(() {
          _currentWidget = Login();
        });
    }
  }

  Widget _multiPageLayout() {
    return CupertinoTabScaffold(
      controller: _tabController,
      tabBar: CupertinoTabBar(
        items: <String, IconData>{
          'Notas': CupertinoIcons.news,
          'Horários': CupertinoIcons.time,
          'Frequência': CupertinoIcons.check_mark_circled,
          'Vínculo': CupertinoIcons.collections,
          'Sobre': CupertinoIcons.info
        }
            .entries
            .map((e) => BottomNavigationBarItem(
                  icon: Icon(e.value),
                  title: Text(e.key),
                ))
            .toList(),
      ),
      tabBuilder: (_, index) {
        final ws = [
          () => Grades(),
          () => Schedules(),
          () => FrequencyPage(),
          () => LinkSelectionPage(),
          () => AboutPage(),
        ];

        return CupertinoTabView(builder: (_) => ws[index]());
      },
    );
  }
}
