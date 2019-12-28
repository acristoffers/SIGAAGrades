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
import 'package:flutter/services.dart';
import 'package:sigaa_notas/common/login.dart';
import 'package:sigaa_notas/common/utils.dart';
import 'package:sigaa_notas/cupertino/app.dart';
import 'package:sigaa_notas/cupertino/layout.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  var _loginClicked = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Application.theme(
      CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Login'),
        ),
        child: SafeArea(
          child: Container(
            alignment: Alignment.center,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 600,
                    child: CupertinoTextField(
                      controller: _usernameController,
                      keyboardType: TextInputType.number,
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                width: 0.0,
                                color: CupertinoColors.inactiveGray)),
                      ),
                      placeholder: 'CPF',
                    ),
                  ),
                  SizedBox(
                    width: 600,
                    child: CupertinoTextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                width: 0.0,
                                color: CupertinoColors.inactiveGray)),
                      ),
                      placeholder: 'Senha',
                    ),
                  ),
                  CupertinoButton(
                    onPressed: _loginClicked
                        ? null
                        : () {
                            SystemChannels.textInput
                                .invokeMethod('TextInput.hide');
                            setState(() => _loginClicked = true);

                            final username = _usernameController.text;
                            final password = _passwordController.text;

                            LoginService.login(username, password)
                                .then((_) =>
                                    LayoutState.current().navigate('/links'))
                                .catchError((e) {
                              if (mounted) {
                                if (e
                                    .toString()
                                    .contains('invalid_credentials')) {
                                  showToast("Credenciais Incorretas");
                                } else {
                                  showToast("Erro de conexão");
                                }
                              }
                            }).whenComplete(() {
                              if (mounted) {
                                setState(() => _loginClicked = false);
                              }
                            });
                          },
                    child: Text('Entrar', style: TextStyle(fontSize: 20)),
                  )
                ].map((e) {
                  return Padding(padding: EdgeInsets.all(10), child: e);
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
