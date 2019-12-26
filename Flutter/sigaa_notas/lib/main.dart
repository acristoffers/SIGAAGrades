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

import 'dart:async';
import 'dart:io' show Platform;

import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaa_notas/frequency.dart';
import 'package:sigaa_notas/grades.dart';
import 'package:sigaa_notas/link_selection.dart';
import 'package:sigaa_notas/login.dart';
import 'package:sigaa_notas/schedules.dart';

void main() => runApp(StatelessApp());

class StatelessApp extends StatelessWidget {
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
        pageTransitionsTheme: PageTransitionsTheme(
          builders: Map.fromIterable(
            TargetPlatform.values,
            key: (dynamic k) => k,
            value: (dynamic _) => const _NoopePageTransitionsBuilder(),
          ),
        ),
      ),
      themedWidgetBuilder: (context, theme) {
        return MaterialApp(
          title: 'SIGAA:Notas',
          theme: theme,
          home: App(),
          navigatorKey: App.navKey,
        );
      },
    );
  }
}

class App extends StatefulWidget {
  static final navKey = GlobalKey<NavigatorState>(debugLabel: 'NavigatorKey');
  static final appKey = GlobalKey(debugLabel: 'AppKey');

  App() : super(key: appKey);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
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
          _navigate((_) => GradesPage());
        } else {
          _navigate((_) => LinkSelectionPage());
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LoginPage();
  }

  void setupQuickActions() {
    quickActions.initialize((String shortcutType) {
      if (!_canUseQuickActions) {
        return;
      }

      switch (shortcutType) {
        case 'action:grades':
          _navigate((_) => GradesPage());
          _didUseQuickActions = true;
          break;
        case 'action:schedules':
          _navigate((_) => SchedulesPage());
          _didUseQuickActions = true;
          break;
        case 'action:frequency':
          _navigate((_) => FrequencyPage());
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

void toggleDarkTheme(BuildContext context) {
  DynamicTheme.of(context).setBrightness(
      Theme.of(context).brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark);
}

class _NoopePageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoopePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return child;
  }
}

void _navigate(WidgetBuilder builder) {
  Timer.run(() {
    final route = MaterialPageRoute(builder: builder);
    App.navKey.currentState.pushReplacement(route);
  });
}
