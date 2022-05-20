import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Violation {
  DateTime time;
  double longitude;
  double latitude;

  Violation(this.time, this.longitude, this.latitude);
}

class ReadExample extends StatefulWidget {
  const ReadExample({Key? key}) : super(key: key);

  @override
  _ReadExampleState createState() => _ReadExampleState();
}

class _ReadExampleState extends State<ReadExample> {
  // List _threeftViolations = <String>['Results go here'];
  final _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _activateListeners();
  }

  Future<void> _activateListeners() async {
    final data = await _database.child('ThreeFeet').get();
    if (data.exists) {
      print(data.value);
    } else {
      print('No data available.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Read Example'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: Column(
            children: [],
          ),
        ),
      ),
    );
  }
}
