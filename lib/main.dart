import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:get_ip/get_ip.dart';

void main() => runApp(MyApp());

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

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static HttpServer server;
  static Database db;

  _start() async {
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

      try {
        final utf8Stream = Utf8Decoder().bind(request);
        final jsonStream = JsonDecoder().bind(utf8Stream);
        final jsonRequest = await jsonStream.single;
        final response = await _route(jsonRequest);
        final jsonResponse = jsonEncode(response);
        request.response.write(jsonResponse);
      } catch (e) {
        request.response.write(
          jsonEncode(
            {'status': 0, 'message': 'invalid request'},
          ),
        );
        print(e);
      } finally {
        await request.response.close();
      }
    });

    print('server started on ' + await GetIp.ipAddress);
  }

  Future<Object> _route(dynamic json) async {
    if (json['create'] != null) {
      await db.rawInsert(
        'INSERT INTO test (name) VALUES (?)',
        [json['create']],
      );
      return {'status': 1, 'message': 'created'};
    } else if (json['read'] != null) {
      final res = await db.rawQuery('SELECT * FROM test');
      return {'status': 1, 'message': 'read', 'result': res};
    } else if (json['update'] != null) {
      await db.rawUpdate(
        'UPDATE test SET name = ? WHERE xid  = ?',
        [json['name'], json['update']],
      );
      return {'status': 1, 'message': 'updated'};
    } else if (json['delete'] != null) {
      await db.rawDelete('DELETE FROM test WHERE xid = ?', [json['delete']]);
      return {'status': 1, 'message': 'deleted'};
    } else
      throw (Exception);
  }

  _stop() async {
    try {
      print('stopping server');
      await server.close();
      await db.close();
      print('server stopped');
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Server Test 1")),
      body: ListView(
        children: <Widget>[
          FlatButton(
            onPressed: _start,
            child: Text('start'),
          ),
          FlatButton(
            onPressed: _stop,
            child: Text('stop'),
          ),
        ],
      ),
    );
  }
}
