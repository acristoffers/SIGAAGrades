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

import 'dart:io' show Platform;

import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaa_notas/common/observer.dart';
import 'package:sigaa_notas/material/about.dart';
import 'package:sigaa_notas/material/frequency.dart';
import 'package:sigaa_notas/material/grades.dart';
import 'package:sigaa_notas/material/links.dart';
import 'package:sigaa_notas/material/login.dart';
import 'package:sigaa_notas/material/layout.dart';
import 'package:sigaa_notas/material/schedules.dart';
import 'package:sigaa_notas/material/settings.dart';

class Application extends StatefulWidget {
  @override
  _ApplicationState createState() => _ApplicationState();

  static final layoutObserver = Observer<LayoutGlobalState>();
}

class _ApplicationState extends State<Application> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return DynamicTheme(
      defaultBrightness: Brightness.light,
      data: (brightness) => ThemeData(
        primarySwatch: Colors.indigo,
        primaryColor: Colors.indigo,
        primaryColorDark: Colors.indigo,
        secondaryHeaderColor: Colors.white,
        accentColor: Colors.indigoAccent,
        brightness: brightness,
      ),
      themedWidgetBuilder: (context, theme) {
        return OKToast(
          position: ToastPosition.bottom,
          backgroundColor: Color.fromARGB(255, 32, 32, 32),
          textPadding: EdgeInsets.all(8.0),
          child: MaterialApp(
            title: 'SIGAA:Notas',
            theme: theme,
            initialRoute: '/login',
            routes: {
              '/login': (_) => Layout(Login()),
              '/grades': (_) => Layout(Grades()),
              '/schedules': (_) => Layout(SchedulesPage()),
              '/links': (_) => Layout(LinkSelectionPage()),
              '/about': (_) => Layout(AboutPage()),
              '/frequency': (_) => Layout(FrequencyPage()),
              '/settings': (_) => Layout(SettingsPage()),
            },
            navigatorKey: _navigatorKey,
          ),
        );
      },
    );
  }

  final QuickActions quickActions = QuickActions();

  var _didUseQuickActions = false;
  var _canUseQuickActions = false;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs) {
      final bool loggedIn = ['username', 'password'].every(prefs.containsKey);
      final bool linkSelected = prefs.containsKey('link');

      _canUseQuickActions = loggedIn && linkSelected;

      if (Platform.isAndroid || Platform.isIOS) {
        setupQuickActions();
      }

      if (!_didUseQuickActions && loggedIn) {
        if (linkSelected) {
          _navigatorKey.currentState.pushReplacementNamed('/grades');
        } else {
          _navigatorKey.currentState.pushReplacementNamed('/links');
        }
      }
    });
  }

  void setupQuickActions() {
    quickActions.initialize((String shortcutType) {
      if (!_canUseQuickActions) {
        return;
      }

      switch (shortcutType) {
        case 'action:grades':
          _navigatorKey.currentState.pushReplacementNamed('/grades');
          _didUseQuickActions = true;
          break;
        case 'action:schedules':
          _navigatorKey.currentState.pushReplacementNamed('/schedules');
          _didUseQuickActions = true;
          break;
        case 'action:frequency':
          _navigatorKey.currentState.pushReplacementNamed('/frequency');
          _didUseQuickActions = true;
          break;
      }
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action:grades',
        localizedTitle: 'Notas',
        icon: 'assignment',
      ),
      const ShortcutItem(
          type: 'action:schedules',
          localizedTitle: 'Horários',
          icon: 'timelapse'),
      const ShortcutItem(
          type: 'action:frequency',
          localizedTitle: 'Frequência',
          icon: 'airline_seat_recline_normal'),
    ]);
  }
}
