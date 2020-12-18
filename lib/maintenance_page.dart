import 'package:flutter/material.dart';

import 'customized_font.dart';

class MaintenancePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
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
              'メンテナンス中です',
              style: biggerNormalFont,
            ),
          ),
          backgroundColor: Colors.orange[50],
        ));
  }
}
