import 'package:flutter/material.dart';

import 'customized_font.dart';

class ErrorPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ErrorPageState();
}

class _ErrorPageState extends State<ErrorPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.brown,
          title: Text('ワードウルフ'),
        ),
        body: Scaffold(
          body: Center(
            child: Text(
              'エラーが発生しました．',
              style: biggerNormalFont,
            ),
          ),
          backgroundColor: Colors.orange[50],
        ));
  }
}
