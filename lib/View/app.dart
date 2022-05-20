// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import "package:flutter_reactive_ble/flutter_reactive_ble.dart";
import 'package:location/location.dart';
import 'package:provider/provider.dart';
// import 'package:threefeet_app/Data/database_access.dart';
import 'package:threefeet_app/Data/map_markers.dart';
import 'package:threefeet_app/Data/mapbox_map.dart';
import 'package:threefeet_app/View/view_model.dart';

class ConsenseApp extends StatelessWidget {
  const ConsenseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ViewModel fbModel = ViewModel();
    return ChangeNotifierProvider(
      create: (context) => ViewModel()..initializeModel(),
      child: Consumer<ViewModel>(
        builder: (context, viewModel, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: HomePage(
                viewModel.mapMarkers,
                viewModel.state,
                viewModel.latitude,
                viewModel.longitude,
                viewModel.violationDetected),
            // theme: ThemeData(
            // primarySwatch: Colors.white,
            // ),
          );
        },
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final MapMarkers mapMarkers;
  final DeviceConnectionState state;
  final double? latitude;
  final double? longitude;
  final bool violationDetected;
  HomePage(this.mapMarkers, this.state, this.latitude, this.longitude,
      this.violationDetected);

  @override
  Widget build(BuildContext context) {
    if (violationDetected) {
      violationDetectedDialog(context);
    }
    if (latitude == null || longitude == null) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              const Text(
                'Loading...',
                style: TextStyle(fontSize: 20),
              ),
              LinearProgressIndicator(
                semanticsLabel: 'Linear progress indicator',
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            leading: Image.asset("assets/Consense-logo-imageonly.png"),
            title: FittedBox(
                fit: BoxFit.fitWidth,
                child: Text(
                  state == DeviceConnectionState.connected
                      ? 'Consense Smart-Light Connected'
                      : 'No Device Connected',
                  style: TextStyle(color: Colors.black),
                )),
          ),
          body: Stack(
            children: <Widget>[
              MapBoxMap(
                  mapMarkers: mapMarkers,
                  latitude: latitude!,
                  longitude: longitude!),
              Card(
                child: TextField(
                  textInputAction: TextInputAction.go,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: ("Enter an Address"),
                  ),
                ),
              )
            ],
          ));
    }
  }

  void violationDetectedDialog(context) async {
    await Future.delayed(Duration(microseconds: 1));
    showDialog(
        context: context,
        builder: (context) {
          Future.delayed(Duration(seconds: 3), () {
            Navigator.of(context).pop(true);
          });
          return AlertDialog(
            title: Text('Violation Detected!'),
          );
        });
  }
}
