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
import 'package:flutter/foundation.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaa_notas/common/observer.dart';
import 'package:sigaa_notas/cupertino/layout.dart';

class Application extends StatefulWidget {
  static final layoutKey = GlobalKey(debugLabel: 'LayoutKey');
  static final updateObserver = Observer<bool>();

  const Application({Key key}) : super(key: key);

  @override
  _ApplicationState createState() => _ApplicationState();

  static CupertinoTheme lightTheme(Widget child) {
    return CupertinoTheme(
      data: const CupertinoThemeData(brightness: Brightness.light),
      child: child,
    );
  }

  static CupertinoTheme darkTheme(Widget child) {
    return CupertinoTheme(
      data: const CupertinoThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: CupertinoColors.tertiarySystemBackground,
        textTheme: CupertinoTextThemeData(
          primaryColor: CupertinoColors.white,
          textStyle: TextStyle(color: CupertinoColors.white),
        ),
      ),
      child: child,
    );
  }

  static CupertinoTheme theme(Widget child) {
    final query = MediaQuery.of(LayoutState.current().context);
    return query.platformBrightness == Brightness.dark
        ? darkTheme(child)
        : lightTheme(child);
  }
}

class _ApplicationState extends State<Application> {
  final _quickActions = const QuickActions();
  var _didUseQuickActions = false;
  var _canUseQuickActions = false;

  @override
  Widget build(BuildContext context) {
    return RefreshConfiguration(
      headerBuilder: () => const ClassicHeader(),
      enableScrollWhenRefreshCompleted: true,
      child: OKToast(
        position: ToastPosition.bottom,
        backgroundColor: const Color.fromARGB(255, 32, 32, 32),
        textPadding: const EdgeInsets.all(8.0),
        child: CupertinoApp(
          title: 'SIGAA:Notas',
          home: Layout(key: Application.layoutKey),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs) {
      final bool loggedIn = ['username', 'password'].every(prefs.containsKey);
      final bool linkSelected = prefs.containsKey('link');
      final ps = [TargetPlatform.iOS, TargetPlatform.android];
      final bool mobile = ps.contains(defaultTargetPlatform);

      _canUseQuickActions = loggedIn && linkSelected && mobile;

      if (mobile) {
        _setupQuickActions();
      }

      if (!_didUseQuickActions && loggedIn) {
        if (linkSelected) {
          LayoutState.current().navigate('/grades');
        } else {
          LayoutState.current().navigate('/links');
        }
      }
    });
  }

  void _setupQuickActions() {
    _quickActions.initialize((String shortcutType) {
      if (!_canUseQuickActions) {
        return;
      }

      switch (shortcutType) {
        case 'action:grades':
          LayoutState.current().navigate('/grades');
          _didUseQuickActions = true;
          break;
        case 'action:schedules':
          LayoutState.current().navigate('/schedules');
          _didUseQuickActions = true;
          break;
        case 'action:frequency':
          LayoutState.current().navigate('/frequency');
          _didUseQuickActions = true;
          break;
      }
    });

    _quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action:grades',
        localizedTitle: 'Notas',
      ),
      const ShortcutItem(
        type: 'action:schedules',
        localizedTitle: 'Horários',
      ),
      const ShortcutItem(
        type: 'action:frequency',
        localizedTitle: 'Frequência',
      ),
    ]);
  }
}
