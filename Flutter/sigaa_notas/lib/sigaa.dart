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

import 'dart:io';

import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:quiver/iterables.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaa_notas/utils.dart';

class SIGAA {
  final _baseUrl = 'https://sig.cefetmg.br';

  var _username = '';
  var _password = '';

  var _jsessionid = '';
  var _isLoggedIn = false;

  Future<http.Response> httpGet(String url, {bool redirect = false}) async {
    final request = http.Request('GET', Uri.parse('$_baseUrl$url'));
    request.followRedirects = redirect;
    request.headers[HttpHeaders.cookieHeader] = 'JSESSIONID=$_jsessionid';
    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  Future<http.Response> httpPost(String url, Map body) async {
    final request = http.Request('POST', Uri.parse('$_baseUrl$url'));
    request.headers[HttpHeaders.cookieHeader] = 'JSESSIONID=$_jsessionid';
    request.bodyFields = body;
    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  getJSessionID() async {
    final url = '/sigaa/verTelaLogin.do';
    final response = await httpGet(url);
    final cookies = response.headers['set-cookie'] ?? '';
    cookies.split(';').forEach((x) {
      final xs = x.split('=');
      if (xs[0] == 'JSESSIONID') {
        _jsessionid = xs[1].trim();
      }
    });
  }

  Future<bool> login(String username, String password) async {
    _username = username;
    _password = password;

    await getJSessionID();

    final url = '/sigaa/logar\.do;jsessionid=$_jsessionid\?dispatch=logOn';

    final data = {
      'width': '800',
      'height': '600',
      'urlRedirect': '',
      'subsistemaRedirect': '',
      'acao': '',
      'acessibilidade': '',
      'user.login': username,
      'user.senha': password
    };

    return await httpPost(url, data).then((r) {
      _isLoggedIn = r.headers.containsKey('location');
      return _isLoggedIn;
    });
  }

  Future<List<Link>> listLinks() async {
    final url = '/sigaa/vinculos.jsf';
    final response = await httpGet(url);
    final document = parse(response.body);

    final s1 = 'table.tabela-selecao-vinculo a.withoutFormat';
    final s2 = 'table.tabela-selecao-vinculo a.withoutFormatInativo';
    final linksAtivos = document.querySelectorAll(s1);
    final linksInativos = document.querySelectorAll(s2);
    final links = partition(linksAtivos + linksInativos, 3);
    return links
        .map((link) => Link(
              id: 0,
              type: link[0].innerHtml,
              immatriculation: link[1].innerHtml,
              name: link[2].innerHtml,
              url: link[0].attributes['href'],
            ))
        .toList();
  }

  Future<List<Course>> listCourses() async {
    final url = '/sigaa/verPortalDiscente.do';
    final homeResponse = await httpGet(url, redirect: true);
    final document = parse(homeResponse.body);

    return document.querySelectorAll('td.descricao').map((td) {
      final onclick = td.querySelectorAll('a').first.attributes['onclick'];
      final cname = td.querySelectorAll('a').first.text.trim();
      final fName = td.querySelectorAll('form').first.attributes['name'];

      final m = RegExp("'($fName:[a-zA-Z0-9_]+)'").firstMatch(onclick);
      final name = m.group(1);

      final m2 = RegExp("'frontEndIdTurma':'([A-Z0-9]+)'").firstMatch(onclick);
      final idTurma = m2.group(1);

      final data = {
        "frontEndIdTurma": idTurma,
        "javax.faces.ViewState": td
            .querySelectorAll("input[name='javax.faces.ViewState']")
            .first
            .attributes['value'],
        name: name,
        fName: fName
      };

      return Course(id: 0, cid: idTurma, name: cname, data: data);
    }).toList();
  }

  Future<List<Grade>> listGrades(Course course) async {
    final prefs = await SharedPreferences.getInstance();
    final link = prefs.getString('link');
    final sigaa = SIGAA();

    await sigaa.login(_username, _password);
    await sigaa.httpGet(link);

    final courses = await sigaa.listCourses();
    final data = courses.firstWhere((c) => c.cid == course.cid).data;
    final courseUrl = '/sigaa/portais/discente/discente.jsf';

    final coursePage = await sigaa.httpPost(courseUrl, data);

    final document = parse(coursePage.body);
    final viewState = document
        .querySelectorAll("input[name='javax.faces.ViewState']")
        .first
        .attributes['value'];
    final cdata = {'javax.faces.ViewState': viewState};

    try {
      final link = document
          .querySelectorAll('div')
          .where((e) => e.innerHtml.contains('Ver Notas'))
          .last
          .parent
          .attributes['onclick'];
      final regex = RegExp("formMenu:j_id_jsp_([0-9_]+)");
      final m = regex.firstMatch(link).group(1);
      final regex2 = RegExp("PanelBar\\('formMenu:j_id_jsp_([0-9_]+)");
      final m2 = regex2.firstMatch(coursePage.body).group(1);

      cdata["formMenu"] = "formMenu";
      cdata["formMenu:j_id_jsp_$m2"] = "formMenu:j_id_jsp_$m2";
      cdata["formMenu:j_id_jsp_$m"] = "formMenu:j_id_jsp_$m";
    } catch (_) {
      cdata["formMenuDrop"] = "formMenuDrop";
      cdata["formMenuDrop:menuVerNotas:hidden"] = "formMenuDrop:menuVerNotas";
    }

    final gradesUrl = '/sigaa/ava/index.jsf';
    final response = await sigaa.httpPost(gradesUrl, cdata);

    if (!response.body.contains('tabelaRelatorio')) {
      return [];
    }

    final document2 = parse(response.body);
    final table = document2.querySelectorAll('table.tabelaRelatorio').first;

    final tr = table.querySelectorAll('tbody tr').first;
    final vn = tr.querySelectorAll('td').map((td) => td.text.trim()).toList();
    final v = vn.sublist(2, vn.length - 5);

    final tr2 = table.querySelectorAll('tr#trAval').first;
    final ids = tr2
        .querySelectorAll('th[id]')
        .map((th) => th.attributes['id'])
        .where((id) => id.startsWith('aval_'))
        .map((id) => id.replaceFirst('aval_', ''))
        .toList();

    final a = ids
        .map((id) => document2
            .querySelectorAll('input#denAval_$id')
            .map((e) => e.attributes['value'])
            .first)
        .where((i) => i != null)
        .toList();

    final n = ids
        .map((id) => document2
            .querySelectorAll('input#notaAval_$id')
            .map((e) => e.attributes['value'])
            .first)
        .where((i) => i != null)
        .toList();

    final grades = zip([a, n, v])
        .map((xs) => Grade(
              id: 0,
              activityName: xs[0],
              scoreValue: xs[2].replaceAll(',', '.'),
              totalValue: xs[1].replaceAll(',', '.'),
            ))
        .toList();

    return grades;
  }

  Future<List<Schedule>> listSchedules() async {
    final url = '/sigaa/verPortalDiscente.do';
    final homeResponse = await httpGet(url, redirect: true);
    final document = parse(homeResponse.body);

    return document
        .querySelectorAll('td.descricao')
        .map((td) {
          final onclick = td.querySelectorAll('a').first.attributes['onclick'];
          final r = RegExp("'frontEndIdTurma':'([A-Z0-9]+)'");
          final m2 = r.firstMatch(onclick);
          final cid = m2.group(1);

          final tr = td.parent;
          final course = tr.querySelectorAll('td.descricao').last.text.trim();
          final local = tr.querySelectorAll('td.info').first.text.trim();
          return tr
              .querySelectorAll('td.info')
              .last
              .text
              .trim()
              .split(" ")
              .map((info) {
                var r = RegExp('([0-9]+)[A-Z]');
                final d = r.allMatches(info).first.group(1);
                r = RegExp('.*M([0-9]+)[^A-Z]?');
                final m = firstOrNull(r.allMatches(info))?.group(1) ?? '';
                r = RegExp('.*T([0-9]+)[^A-Z]?');
                final t = firstOrNull(r.allMatches(info))?.group(1) ?? '';
                r = RegExp('.*N([0-9]+)[^A-Z]?');
                final n = firstOrNull(r.allMatches(info))?.group(1) ?? '';

                return d.split('').map((day) {
                  final ms = _stringToRanges(m)
                      .map((it) => {
                            "course": course,
                            "local": local,
                            "day": day,
                            "shift": "1",
                            "start": it[0].toString(),
                            "end": it[1].toString(),
                            'cid': cid
                          })
                      .toList();
                  final ts = _stringToRanges(t)
                      .map((it) => {
                            "course": course,
                            "local": local,
                            "day": day,
                            "shift": "2",
                            "start": it[0].toString(),
                            "end": it[1].toString(),
                            'cid': cid
                          })
                      .toList();
                  final ns = _stringToRanges(n)
                      .map((it) => {
                            "course": course,
                            "local": local,
                            "day": day,
                            "shift": "3",
                            "start": it[0].toString(),
                            "end": it[1].toString(),
                            'cid': cid
                          })
                      .toList();

                  return ms + ts + ns;
                }).toList();
              })
              .toList()
              .expand((e) => e) //flatten 1
              .expand((e) => e) //flatten 2
              .toList();
        })
        .expand((e) => e)
        .map((l) => _scheduleFromMap(l))
        .toList();
  }

  Future<Frequency> listFrequency(Course course) async {
    final prefs = await SharedPreferences.getInstance();
    final link = prefs.getString('link');
    final sigaa = SIGAA();

    await sigaa.login(_username, _password);
    await sigaa.httpGet(link);

    final courses = await sigaa.listCourses();
    final data = courses.firstWhere((c) => c.cid == course.cid).data;
    final courseUrl = '/sigaa/portais/discente/discente.jsf';
    final coursePage = await sigaa.httpPost(courseUrl, data);

    var document = parse(coursePage.body);
    final viewState = document
        .querySelectorAll("input[name='javax.faces.ViewState']")
        .first
        .attributes['value'];
    final data2 = {'javax.faces.ViewState': viewState};

    try {
      final link = document
          .querySelectorAll('div')
          .lastWhere((d) => d.text.contains('Frequência'))
          .parent
          .attributes['onclick'];
      var r = RegExp(r'formMenu:j_id_jsp_([0-9_]+)');
      final m = r.allMatches(link).first.group(1);
      r = RegExp(r"PanelBar\('formMenu:j_id_jsp_([0-9_]+)");
      final m2 = r.allMatches(coursePage.body).first.group(1);
      data2['formMenu'] = 'formMenu';
      data2['formMenu:j_id_jsp_$m2'] = 'formMenu:j_id_jsp_$m2';
      data2['formMenu:j_id_jsp_$m'] = 'formMenu:j_id_jsp_$m';
    } catch (_) {
      data2['formMenuDrop'] = 'formMenuDrop';
      data2['formMenuDrop:menuFrequencia:hidden'] =
          'formMenuDrop:menuFrequencia';
    }

    final freqPage = await sigaa.httpPost('/sigaa/ava/index.jsf', data2);
    document = parse(freqPage.body);
    final text = document.querySelectorAll('#scroll-wrapper').first.text;

    if (text.contains('A frequência ainda não foi lançada.')) {
      return Frequency(absences: 0, givenClasses: 0, totalClasses: 0);
    }

    final absences = document
        .querySelectorAll('div')
        .lastWhere((d) => d.text.contains('Total de Faltas:'))
        .text
        .split(':')
        .last
        .trim();
    final frequency = int.parse(absences);

    final text2 = document.querySelectorAll('#barraDireita').first.text;
    final r = RegExp(
      r'Aulas[ ]+\(Ministradas/Total\):[ ]+([0-9]+)[ ]+/[ ]+([0-9]+)',
    );
    final m2 = r.allMatches(text2).first;
    final givenClasses = int.parse(m2.group(1));
    final totalClasses = int.parse(m2.group(2));

    return Frequency(
      absences: frequency,
      totalClasses: totalClasses,
      givenClasses: givenClasses,
    );
  }

  Future<List<DateTime>> startAndEndOfSemester() async {
    var url = '/sigaa/verPortalDiscente.do';
    final homeResponse = await httpGet(url, redirect: true);
    var document = parse(homeResponse.body);

    final jID = document
        .querySelectorAll("input[name='javax.faces.ViewState']")
        .first
        .attributes['value'];
    final id =
        document.querySelectorAll("input[name='id']").first.attributes['value'];
    var r = RegExp("menu_form_menu_discente_j_id_jsp_[0-9_]+_menu");
    final menu = r.allMatches(homeResponse.body).first.group(0);
    final data = {
      'id': id,
      'javax.faces.ViewState': jID,
      'jscook_action': '$menu:A]#{calendario.iniciarBusca}',
      'menu:form_menu_discente': 'menu:form_menu_discente',
    };

    url = '/sigaa/portais/discente/discente.jsf';
    final calsResponse = await httpPost(url, data);
    document = parse(calsResponse.body);

    final semester =
        document.querySelectorAll('.periodo-atual strong').first.text.trim();
    final index = document
        .querySelectorAll('thead')
        .indexWhere((t) => t.text.contains(semester));
    final a = document
        .querySelectorAll('.listagem tbody a')[index]
        .attributes['onclick'];
    r = RegExp("'id':'([0-9]+)'");
    final id2 = r.allMatches(a).first.group(1);
    final jID2 = document
        .querySelectorAll("input[name='javax.faces.ViewState']")
        .first
        .attributes['value'];
    final data2 = {
      "form": "form",
      "form:visualizar": "form:visualizar",
      "id": id2,
      "javax.faces.ViewState": jID2,
    };

    url = '/sigaa/administracao/calendario_academico/consulta.jsf';
    final calResponse = await httpPost(url, data2);
    document = parse(calResponse.body);

    final tr = document
        .querySelectorAll('th')
        .firstWhere((th) => th.text.contains('Período Letivo:'))
        .parent;
    r = RegExp(
        'De ([0-9]{2}/[0-9]{2}/[0-9]{4}) até ([0-9]{2}/[0-9]{2}/[0-9]{4})');
    final l = tr.children.last.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final ms = r.allMatches(l);
    final startList = ms.first.group(1).split('/').map(int.parse).toList();
    final endList = ms.first.group(2).split('/').map(int.parse).toList();

    final start = DateTime(startList[2], startList[1], startList[0]);
    final end = DateTime(endList[2], endList[1], endList[0]);

    return [start, end];
  }

  List<List<int>> _stringToRanges(String str) {
    final ns = str.split('').map((it) => int.parse(it.trim())).toList();
    final rs = <List<int>>[];

    for (final i in ns) {
      final x = rs.length > 0 ? rs.last.elementAt(1) : i;
      if ((i - 1) == x) {
        rs[rs.length - 1] = [rs.last[0], i];
      } else {
        rs.add([i, i]);
      }
    }

    return rs;
  }

  Schedule _scheduleFromMap(Map<String, String> schedule) {
    final course = schedule["course"]?.trim() ?? "";
    final local = schedule["local"]?.trim() ?? "";
    final day = schedule["day"]?.trim() ?? "";
    final shift = schedule["shift"]?.trim() ?? "";
    final start = schedule["start"]?.trim() ?? "";
    final end = schedule["end"]?.trim() ?? "";
    final cid = schedule['cid']?.trim() ?? '';

    final startTimes = [
      {
        "1": "7:00",
        "2": "7:50",
        "3": "8:55",
        "4": "9:45",
        "5": "10:50",
        "6": "11:40"
      },
      {"1": "13:50", "2": "14:40", "3": "15:50", "4": "16:40", "5": "17:40"},
      {"1": "19:00", "2": "19:50", "3": "20:50", "4": "21:40"}
    ];

    final endTimes = [
      {
        "1": "7:50",
        "2": "8:40",
        "3": "9:45",
        "4": "10:35",
        "5": "11:40",
        "6": "12:30"
      },
      {"1": "14:40", "2": "15:30", "3": "16:40", "4": "17:30", "5": "18:30"},
      {"1": "19:50", "2": "20:40", "3": "21:40", "4": "22:30"}
    ];

    final startTime = startTimes[int.parse(shift) - 1][start] ?? "";
    final endTime = endTimes[int.parse(shift) - 1][end] ?? "";

    return Schedule(
        course: course,
        local: local,
        day: int.parse(day),
        shift: int.parse(shift),
        start: startTime,
        end: endTime,
        cid: cid);
  }
}

class Link {
  Link({this.id, this.type, this.immatriculation, this.name, this.url});

  final int id;
  final String type;
  final String name;
  final String immatriculation;
  final String url;

  @override
  String toString() {
    return 'Link(type=$type, name=$name, immatriculation=$immatriculation, url=$url)';
  }
}

class Course {
  Course({this.id, this.cid, this.name, this.data, this.grades});

  final int id;
  final String name;
  final String cid;
  final Map<String, String> data;
  var grades = <Grade>[];
  Frequency frequency;

  @override
  String toString() {
    return 'Course(name=$name, id=$id, grades=$grades, data=$data)';
  }
}

class Grade {
  Grade({this.id, this.activityName, this.scoreValue, this.totalValue});

  final int id;
  final String activityName;
  final String scoreValue;
  final String totalValue;

  @override
  String toString() {
    return 'Grade(activityName=$activityName, scoreValue=$scoreValue, totalValue=$totalValue)';
  }
}

class Schedule {
  Schedule({
    this.course,
    this.local,
    this.day,
    this.shift,
    this.start,
    this.end,
    this.cid,
  });

  final String course;
  final String local;
  final int day;
  final int shift;
  final String start;
  final String end;
  final String cid;

  @override
  String toString() {
    return 'Schedule(course=$course, local=$local, day=$day, shift=$shift, start=$start, end=$end, cid:$cid)';
  }
}

class Frequency {
  Frequency({this.absences, this.givenClasses, this.totalClasses});

  final int absences;
  final int givenClasses;
  final int totalClasses;

  @override
  String toString() {
    return 'Frequency(frequency=$absences, givenClasses=$givenClasses, totalClasses=$totalClasses)';
  }
}
