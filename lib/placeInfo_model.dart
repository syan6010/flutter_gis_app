import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceInfo {
  String name;
  String address;
  String description;
  LatLng locationCoords;

  PlaceInfo(
      {this.name,
        this.address,
        this.description,
        this.locationCoords});
}

