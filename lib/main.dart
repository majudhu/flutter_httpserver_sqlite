import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:get_ip/get_ip.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _startServer();
  runApp(MyApp());
}

_startServer() async {
  print('starting');
  HttpServer server;
  Database db;

  db = await openDatabase('my_db.db');
//    db.execute('CREATE TABLE test(xid INTEGER PRIMARY KEY, name TEXT)');
  print('starting server');
  server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('starting listener');
  server.listen((request) async {
    request.response.headers.set(
      'content-type',
      'application/json; charset=utf-8',
    );

    final json = jsonDecode(utf8.decode(await request.single));

    if (json['create'] != null) {
      await db.rawInsert(
        'INSERT INTO test (name) VALUES (?)',
        [json['create']],
      );
      request.response.write(jsonEncode({'status': 1, 'message': 'created'}));
    } else if (json['read'] != null) {
      final res = await db.rawQuery('SELECT * FROM test');
      request.response
          .write(jsonEncode({'status': 1, 'message': 'read', 'result': res}));
    } else if (json['update'] != null) {
      await db.rawUpdate(
        'UPDATE test SET name = ? WHERE xid  = ?',
        [json['name'], json['update']],
      );
      request.response.write(jsonEncode({'status': 1, 'message': 'updated'}));
    } else if (json['delete'] != null) {
      await db.rawDelete('DELETE FROM test WHERE xid = ?', [json['delete']]);
      request.response.write(jsonEncode({'status': 1, 'message': 'deleted'}));
    } else {
      request.response.write(jsonEncode({'status': 1, 'message': 'error'}));
    }


    await request.response.close();
  });
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Server Test 1'),
      ),
      body: Center(
        child: FutureBuilder(
          future: GetIp.ipAddress,
          builder: (context, snapshot) =>
              Text((snapshot?.data ?? '') + ':8080'),
        ),
      ),
    );
  }
}
