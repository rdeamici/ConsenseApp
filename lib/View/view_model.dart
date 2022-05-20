import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:location/location.dart';
import 'package:threefeet_app/View/busy_notifier.dart';
import 'package:threefeet_app/Data/map_markers.dart';
import 'package:permission_handler/permission_handler.dart';

import '../Data/firebase_options.dart';

final Uuid _DISTANCE_SVC_UUID =
    Uuid.parse("adee5748-a528-4a95-bdc1-a770520cf415");
final Uuid _DISTANCE_CHRC_UUID =
    Uuid.parse("e26bc0a1-5009-4ac9-ae09-b549855b0342");

class ViewModel extends ChangeNotifier with BusyNotifier {
  /////////////// BLE VARIABLES ///////////////
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  late DiscoveredDevice _consenseSmartLight;
  late StreamSubscription<DiscoveredDevice> _scanStream;
  late Stream<ConnectionStateUpdate> _currentConnectionStream;
  late StreamSubscription<ConnectionStateUpdate> _connection;
  final _deviceConnectionController = StreamController<ConnectionStateUpdate>();
  late QualifiedCharacteristic _distanceCharacteristic;
  late DeviceConnectionState _state = DeviceConnectionState.disconnected;

  bool _scanning = false;
  bool _connected = false;
  bool permissionGranted = false;
  String _logTexts = "";
  String deviceName = "";

  DeviceConnectionState get state => _state;

  /////////////////////////////////////////////

  /////////////// FIREBASE VARIABLES ///////////////
  final _database = FirebaseDatabase.instance.ref();
  late DataSnapshot violations;
  final MapMarkers _mapMarkers = MapMarkers();
  late String violationTimeMs;
  bool violationDetected = false;

  MapMarkers get mapMarkers => _mapMarkers;

  /////////////// current location variables ///////////////
  late LocationData currentLocation;
  late double? latitude = null;
  late double? longitude = null;

  Future<void> initializeModel() async {
    await checkPermissions();
    await updateUserLocation();
    busy = true;
    listenForData();
    await startScan();
  }

  /////////////// BLE METHODS ///////////////
  Future<void> disconnect() async {
    try {
      _logTexts =
          '${_logTexts}disconnecting from device: ${_consenseSmartLight.name}\n';
      await _connection.cancel();
      _connected = false;
      deviceName = '';
    } on Exception catch (e, _) {
      _logTexts = '{$_logTexts}Error disconnecting from a device: $e\n';
    } finally {
      // Since [_connection] subscription is terminated, the "disconnected" state cannot be received and propagated
      _logTexts = "$_logTexts";
    }
  }

  Future<void> _stopScan() async {
    _logTexts = "stopping Ble scan";
    await _scanStream.cancel();
    _scanning = false;
  }

  Future<void> checkPermissions() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      permissionGranted = await Permission.location.request().isGranted;
    } else {
      permissionGranted = true;
    }
    if (permissionGranted) {
      _logTexts = "location permission granted";
    }
  }

  void subscribeToNotifications() async {
    _distanceCharacteristic = QualifiedCharacteristic(
        serviceId: _DISTANCE_SVC_UUID,
        characteristicId: _DISTANCE_CHRC_UUID,
        deviceId: _consenseSmartLight.id);
    _ble.subscribeToCharacteristic(_distanceCharacteristic).listen((data) {
      // another async call inside a listener...
      // not sure if its a big deal or not
      _logTexts = "data: $data";
      addNewDataToFirebase(data.first);
    }, onError: (dynamic error) {
      _logTexts = "${_logTexts}Error:$error${_consenseSmartLight.id}\n";
    });
  }

  void discoverServices() async {
    _logTexts = "Discovering Services for ${_consenseSmartLight.name}";
    if (_consenseSmartLight != null) {
      var services = await _ble.discoverServices(_consenseSmartLight.id);
      // for (var service in services) {
      //   for (var chrc in service.characteristicIds) {}
      // }
    }
  }

  Future<void> startScan() async {
    _logTexts = "starting BLE scan";
    if (permissionGranted) {
      _logTexts = "location permission granted";
      if (_scanning) {
        _logTexts = "${_logTexts}Already scanning!\n";
      } else {
        _scanning = true;
        _logTexts = "set _scanning: $_scanning";
        _scanStream = _ble.scanForDevices(
            withServices: [], scanMode: ScanMode.lowLatency).listen((device) {
          if (device.name == "Consense Smart-Light") {
            _consenseSmartLight = device;
            deviceName = device.name;
            _logTexts = "found smart-light";
            // not sure how to stop a synchronous scan with
            // an asynchronous method cancel()
            _scanStream.cancel();
            // discoverServices();
            // discoverServices();
            connectToDevice();
          }
        }, onError: (Object error) {
          _logTexts = "${_logTexts}ERROR while _scanning:$error\n";
        });
      }
    } else {
      _logTexts = "permissions denied";
    }
  }

  Future<void> connectToDevice() async {
    _logTexts = "";
    _logTexts = "connecting to device";
    _connection = _ble
        .connectToAdvertisingDevice(
            id: _consenseSmartLight.id,
            prescanDuration: const Duration(seconds: 5),
            withServices: _consenseSmartLight.serviceUuids)
        .listen((event) {
      var id = event.deviceId.toString();
      _state = event.connectionState;
      switch (_state) {
        case DeviceConnectionState.connecting:
          {
            _logTexts = "${_logTexts}Connecting to $id\n";
            _logTexts = "$_logTexts";
            break;
          }
        case DeviceConnectionState.connected:
          {
            _connected = true;
            _logTexts = "${_logTexts}Connected to $id\n";
            _logTexts = "$_logTexts";
            notifyListeners();
            subscribeToNotifications();
            break;
          }
        case DeviceConnectionState.disconnecting:
          {
            _logTexts = "${_logTexts}Disconnecting from $id\n";
            _logTexts = "$_logTexts";
            break;
          }
        case DeviceConnectionState.disconnected:
          {
            _connected = false;
            _logTexts = "${_logTexts}Disconnected from $id\n";
            _logTexts = "$_logTexts";
            break;
          }
      }
    });
  }

  Future<void> updateUserLocation() async {
    Location location = Location();
    if (permissionGranted) {
      currentLocation = await location.getLocation();
      latitude = currentLocation.latitude;
      longitude = currentLocation.longitude;
    }
  }

  Future<void> listenForData() async {
    _logTexts = "getting firebase data...";
    _database.child('ThreeFeet').onChildAdded.listen((event) {
      var k = event.snapshot.key;
      var v = event.snapshot.value;
      _logTexts = "firebase data received";
      _logTexts = "key  : $k (${k.runtimeType})";
      _logTexts = "value: $v (${k.runtimeType})";
      _mapMarkers.add({k: v});
      // });
      notifyListeners();
    });
  }

  Future<void> addNewDataToFirebase(distance) async {
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
    _logTexts = "adding data to firebase...";
    _logTexts = "distance: '$distance'";
    await updateUserLocation();
    violationTimeMs = DateTime.now().millisecondsSinceEpoch.toString();
    var violation = {
      "distance": distance,
      "coordinates": {
        "latitude": currentLocation.latitude,
        "longitude": currentLocation.longitude
      }
    };
    _logTexts = "writing data to firebase: Threefeet/$violationTimeMs";
    _logTexts = "${violation}";
    _database.child("ThreeFeet/$violationTimeMs").set(violation);
    violationDetected = true;
    _logTexts = "    done!";
  }
}
