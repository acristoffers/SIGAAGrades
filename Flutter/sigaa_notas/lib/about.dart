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

import 'package:flutter/material.dart';
import 'package:sigaa_notas/drawer.dart';
import 'package:url_launcher/url_launcher.dart';

const version = '1.1.19'; //Change the version in future updates

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notas')),
      drawer: Drawer(
        child: DrawerPage(),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 100, 20, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/images/logo.png',
              width: 200,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Text(
                'SIGAA:Notas',
                style: TextStyle(fontSize: 40),
              ),
            ),
            Text('Versão $version'),
            Padding(padding: EdgeInsets.all(5),),
            Text(
              'WebScrapper que baixa notas do SIGAA das matérias do semestre atual.\n\nNão é desenvolvido nem endossado pelo CEFET.\n\nNão faz upload de sua senha.\n\nNão funciona se houver mensagem na página inicial.\n\nCódigo fonte disponível em:',
              textAlign: TextAlign.center,
            ),
            InkWell(
              onTap: () {
                launch('https://github.com/acristoffers/SIGAAGrades');
              },
              child: Text(
                'https://github.com/acristoffers/SIGAAGrades',
                style: TextStyle(color: Theme
                    .of(context)
                    .accentColor),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.code),
        onPressed: () {
          launch('https://github.com/acristoffers/SIGAAGrades');
        },
      ),
    );
  }
}
