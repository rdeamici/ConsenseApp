import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:threefeet_app/Data/map_markers.dart';
import 'package:threefeet_app/Data/map_api_access.dart';
import 'package:threefeet_app/View/view_model.dart';

// ignore: must_be_immutable
class MapBoxMap extends StatelessWidget {
  final MapMarkers mapMarkers;
  final double latitude;
  final double longitude;
  const MapBoxMap(
      {required this.mapMarkers,
      required this.longitude,
      required this.latitude});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        center: LatLng(latitude, longitude),
        zoom: 13.0,
      ),
      layers: [
        TileLayerOptions(
          urlTemplate: get_style_prefs() + "" "" + get_access_token(),
        ),
        MarkerLayerOptions(markers: mapMarkers.markers)
      ],
    );
  }
}
