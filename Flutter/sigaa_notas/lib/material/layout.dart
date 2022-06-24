// ignore_for_file: use_key_in_widget_constructors, no_logic_in_create_state

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

import 'package:flutter/material.dart';
import 'package:sigaa_notas/common/observer.dart';
import 'package:sigaa_notas/material/app.dart';
import 'package:sigaa_notas/material/drawer.dart';

class LayoutGlobalState {
  LayoutGlobalState({this.title, this.singlePage, this.actions});

  String? title = '';
  bool? singlePage = false;
  List<Widget>? actions = <Widget>[];
}

class Layout extends StatefulWidget {
  const Layout(this._child) : super();

  final Widget _child;

  @override
  _LayoutState createState() => _LayoutState(_child);
}

class _LayoutState extends State<Layout> {
  _LayoutState(this._child) : super();

  bool? _singlePage = true;
  String? _title = '';
  List<Widget>? _actions = <Widget>[];
  Subscription? _subscription;
  final Widget _child;

  bool get isAboutPage => ModalRoute.of(context)!.settings.name == '/about';

  @override
  void initState() {
    super.initState();

    _subscription = Application.layoutObserver.subscribe((state) {
      Timer.run(() {
        if (mounted) {
          setState(() {
            _title = state.title;
            _singlePage = state.singlePage;
            _actions = state.actions;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (_subscription != null) {
      _subscription!.unsubscribe();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_singlePage!) {
      return singlePageLayout();
    } else {
      if (MediaQuery.of(context).size.width < 900) {
        return multiPagePhoneLayout();
      } else {
        return multiPageTabletLayout();
      }
    }
  }

  Widget singlePageLayout() {
    return Scaffold(
      appBar: AppBar(title: Text(_title!), actions: _actions),
      body: _child,
    );
  }

  Widget multiPagePhoneLayout() {
    return Scaffold(
      appBar: AppBar(title: Text(_title!), actions: _actions),
      drawer: Drawer(
        child: DrawerPage(
          heroTag: isAboutPage ? '' : 'logo',
        ),
      ),
      body: _child,
    );
  }

  Widget multiPageTabletLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title!),
        actions: _actions,
        elevation: 0,
      ),
      body: Row(
        children: <Widget>[
          Drawer(
              elevation: 0,
              child: DrawerPage(
                docked: true,
                heroTag: isAboutPage ? '' : 'logo',
              )),
          Expanded(child: _child),
        ],
      ),
    );
  }
}
