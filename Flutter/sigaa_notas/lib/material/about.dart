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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sigaa_notas/material/app.dart';
import 'package:sigaa_notas/material/layout.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({Key key}) : super(key: key);

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  var _version = '1.1.26';

  @override
  void initState() {
    super.initState();

    Application.layoutObserver.emit(
      LayoutGlobalState(title: 'Sobre', singlePage: false, actions: <Widget>[]),
    );

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Hero(
              tag: 'logo',
              child: Image.asset('assets/images/logo.png', width: 200),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Text('SIGAA:Notas', style: TextStyle(fontSize: 40)),
            ),
            Text('Versão $_version'),
            const Padding(
              padding: EdgeInsets.all(5),
            ),
            const Text(
              'WebScrapper que baixa notas do SIGAA das matérias do semestre atual.\n\nNão é desenvolvido nem endossado pelo CEFET.\n\nNão faz upload de sua senha.\n\nNão funciona se houver mensagem na página inicial.\n\nCódigo fonte disponível em:',
              textAlign: TextAlign.center,
            ),
            InkWell(
              onTap: () {
                launchUrlString('https://github.com/acristoffers/SIGAAGrades');
              },
              child: Text(
                'https://github.com/acristoffers/SIGAAGrades',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
            const Padding(padding: EdgeInsets.all(30))
          ],
        ),
      ),
    );
  }
}
