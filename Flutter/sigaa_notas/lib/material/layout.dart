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

  var title = '';
  var singlePage = false;
  var actions = <Widget>[];
}

class Layout extends StatefulWidget {
  Layout(this.child) : super();

  final Widget child;

  @override
  LayoutState createState() => LayoutState(child);
}

class LayoutState extends State<Layout> {
  LayoutState(this.child) : super();

  final scaffoldKey = GlobalKey<ScaffoldState>(debugLabel: 'ScaffoldKey');
  var singlePage = true;
  var title = '';
  var actions = List<Widget>();
  Subscription subscription;
  final Widget child;

  bool get isAboutPage => ModalRoute.of(context).settings.name == '/about';

  @override
  void initState() {
    super.initState();

    subscription = Application.layoutObserver.subscribe((state) {
      Timer.run(() {
        if (mounted) {
          setState(() {
            title = state.title;
            singlePage = state.singlePage;
            actions = state.actions;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (subscription != null) {
      subscription.unsubscribe();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (singlePage) {
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
      key: scaffoldKey,
      appBar: AppBar(title: Text(title), actions: actions),
      body: child,
    );
  }

  Widget multiPagePhoneLayout() {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: Drawer(
        child: DrawerPage(
          heroTag: isAboutPage ? '' : 'logo',
        ),
      ),
      body: child,
    );
  }

  Widget multiPageTabletLayout() {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        elevation: 0,
      ),
      body: Row(
        children: <Widget>[
          Drawer(
              child: DrawerPage(
                docked: true,
                heroTag: isAboutPage ? '' : 'logo',
              ),
              elevation: 0),
          Expanded(child: child),
        ],
      ),
    );
  }
}
