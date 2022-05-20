import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
// import 'package:uuid/uuid.dart';

class MapMarkers {
  final List<Marker> _markers = [];
  final List<String> _ids = [];

  UnmodifiableListView<Marker> get markers => UnmodifiableListView(_markers);

  void add(var violation) {
    try {
      var id = violation.keys.first;
      var lat = violation[id]['coordinates']['latitude'];
      var long = violation[id]['coordinates']['longitude'];
      var distance = violation[id]['distance'];
      if (!_ids.contains(id)) {
        _ids.add(id);
        _markers.add(Marker(
          width: 20,
          height: 20,
          point: LatLng(lat, long),
          builder: (ctx) => Icon(MdiIcons.mapMarker,
              color: (distance < 48) ? Colors.red : Colors.orange, size: 20),
          anchorPos: AnchorPos.align(AnchorAlign.bottom),
          rotate: false,
        ));
      }
    } catch (exception) {
      print(exception);
      print(violation);
      print(violation.runtimeType);
    }
  }
}
