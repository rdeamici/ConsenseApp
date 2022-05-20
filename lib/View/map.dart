import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:threefeet_app/Data/map_api_access.dart';
import 'package:threefeet_app/Data/map_markers.dart';

class MapBoxMap extends StatelessWidget {
  const MapBoxMap({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var startLat = context.watch();
    var startLong = context.watch();
    var mapmarkers = context.watch<MapMarkers>();

    return FlutterMap(
      options: MapOptions(
        center: LatLng(startLat, startLong),
        zoom: 13.0,
      ),
      layers: [
        TileLayerOptions(
          urlTemplate: get_style_prefs() + "" "" + get_access_token(),
        ),
        MarkerLayerOptions(markers: mapmarkers.markers)
      ],
    );
  }
}
