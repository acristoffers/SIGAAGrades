import 'package:flutter/material.dart';

class Table extends StatelessWidget {
  final course;
  final Widget body;
  final String title;

  Table(this.title, this.course, this.body);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.fromLTRB(5, 15, 5, 0),
        title: Text(this.title, textAlign: TextAlign.center,),
        subtitle: _verifyCardLength()
      ),
    );
  }

  Widget _verifyCardLength(){
    if(this.course == null){
      return this.body;
    }
    if(this.course.grades.length > 0){
      return  this.body;
    }else {
      return Column(
        children: <Widget>[
          Padding(padding: EdgeInsets.all(10)),
          Text('A matéria não possui notas cadastradas'),
          Padding(padding: EdgeInsets.all(10)),
        ],
      );
    }
  }
}

