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
import 'package:flutter/foundation.dart';
import 'package:package_info/package_info.dart';
import 'package:sigaa_notas/cupertino/app.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  var _version = '1.1.24';

  @override
  void initState() {
    super.initState();

    final ps = [TargetPlatform.iOS, TargetPlatform.android];
    if (ps.contains(defaultTargetPlatform)) {
      PackageInfo.fromPlatform().then((info) {
        if (mounted) {
          setState(() {
            _version = info.version;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Application.theme(
      CupertinoPageScaffold(
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: BoxConstraints.tightForFinite(width: 600),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Hero(
                      tag: 'logo',
                      child: Image.asset('assets/images/logo.png', width: 200),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text('SIGAA:Notas',
                          style: CupertinoTheme.of(context)
                              .textTheme
                              .textStyle
                              .copyWith(fontSize: 40)),
                    ),
                    Text(
                      'Versão $_version',
                      style: CupertinoTheme.of(context).textTheme.textStyle,
                    ),
                    Padding(
                      padding: EdgeInsets.all(40),
                    ),
                    Text(
                      'WebScrapper que baixa notas do SIGAA das matérias do semestre atual.\n\nNão é desenvolvido nem endossado pelo CEFET.\n\nNão faz upload de sua senha.\n\nNão funciona se houver mensagem na página inicial.\n\nCódigo fonte disponível em:',
                      textAlign: TextAlign.center,
                      style: CupertinoTheme.of(context).textTheme.textStyle,
                    ),
                    GestureDetector(
                      onTap: () {
                        launch('https://github.com/acristoffers/SIGAAGrades');
                      },
                      child: Text(
                        'https://github.com/acristoffers/SIGAAGrades',
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .actionTextStyle,
                      ),
                    ),
                    Padding(padding: EdgeInsets.all(30))
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
