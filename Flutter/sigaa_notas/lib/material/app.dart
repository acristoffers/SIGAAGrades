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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaa_notas/common/observer.dart';
import 'package:sigaa_notas/material/about.dart';
import 'package:sigaa_notas/material/frequency.dart';
import 'package:sigaa_notas/material/grades.dart';
import 'package:sigaa_notas/material/layout.dart';
import 'package:sigaa_notas/material/links.dart';
import 'package:sigaa_notas/material/login.dart';
import 'package:sigaa_notas/material/schedules.dart';
import 'package:sigaa_notas/material/settings.dart';

class Application extends StatefulWidget {
  const Application({Key? key}) : super(key: key);

  @override
  _ApplicationState createState() => _ApplicationState();

  static final layoutObserver = Observer<LayoutGlobalState>();
}

class _ApplicationState extends State<Application> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  final themeCollection = ThemeCollection(themes: {
    0: ThemeData(
      primaryColor: Colors.indigo,
      primaryColorDark: Colors.indigo,
      secondaryHeaderColor: Colors.white,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
      ).copyWith(secondary: Colors.indigoAccent),
    ),
    1: ThemeData(
      primaryColor: Colors.indigo,
      primaryColorDark: Colors.indigo,
      secondaryHeaderColor: Colors.white,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.indigo,
        brightness: Brightness.dark,
      ).copyWith(secondary: Colors.indigoAccent),
    ),
  });

  @override
  Widget build(BuildContext context) {
    return DynamicTheme(
      defaultThemeId: 0,
      themeCollection: themeCollection,
      builder: (context, theme) {
        return OKToast(
          position: ToastPosition.bottom,
          backgroundColor: const Color.fromARGB(255, 32, 32, 32),
          textPadding: const EdgeInsets.all(8.0),
          child: MaterialApp(
            title: 'SIGAA:Notas',
            theme: theme,
            initialRoute: '/login',
            routes: {
              '/login': (_) => const Layout(Login()),
              '/grades': (_) => const Layout(Grades()),
              '/schedules': (_) => const Layout(SchedulesPage()),
              '/links': (_) => const Layout(LinkSelectionPage()),
              '/about': (_) => const Layout(AboutPage()),
              '/frequency': (_) => const Layout(FrequencyPage()),
              '/settings': (_) => const Layout(SettingsPage()),
            },
            navigatorKey: _navigatorKey,
          ),
        );
      },
    );
  }

  final QuickActions quickActions = const QuickActions();

  var _didUseQuickActions = false;
  var _canUseQuickActions = false;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs) {
      final bool loggedIn = ['username', 'password'].every(prefs.containsKey);
      final bool linkSelected = prefs.containsKey('link');

      _canUseQuickActions = loggedIn && linkSelected;

      final ps = [TargetPlatform.iOS, TargetPlatform.android];
      if (ps.contains(defaultTargetPlatform)) {
        setupQuickActions();
      }

      if (!_didUseQuickActions && loggedIn) {
        if (linkSelected) {
          _navigatorKey.currentState!.pushReplacementNamed('/grades');
        } else {
          _navigatorKey.currentState!.pushReplacementNamed('/links');
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
          _navigatorKey.currentState!.pushReplacementNamed('/grades');
          _didUseQuickActions = true;
          break;
        case 'action:schedules':
          _navigatorKey.currentState!.pushReplacementNamed('/schedules');
          _didUseQuickActions = true;
          break;
        case 'action:frequency':
          _navigatorKey.currentState!.pushReplacementNamed('/frequency');
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
