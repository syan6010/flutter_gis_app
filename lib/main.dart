import 'dart:async';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';
import 'package:location/location.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_app_finalmap/placeInfo_model.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Completer<GoogleMapController> _controller = Completer();

  static const LatLng _center = const LatLng(24.985546, 121.5783253);

  LatLng testLat = LatLng(24.985546, 121.5783253);

  //----------《Location物件》

  Location _locationTracker = Location();

  LocationData _locationData;

  //----------《Location物件》

  LatLng _lastMapPosition = _center;

  MapType _currentMapType = MapType.normal;

  final DatabaseReference fireBaseDB = FirebaseDatabase.instance.reference();

  List<PlaceInfo> placeInfoList = [];

  final Set<Marker> _markers = {};

//-------------《把所有屬於指定類別的資料推入placeInfoList(type為標記類別)》--------------
  void _getTypeInfo(type) {
    fireBaseDB.child("subject").once().then((DataSnapshot snapshot) {
      snapshot.value.forEach((key, value) {
        if (value["type"] == type) {
          var longitude = value["longitude"];
          var latitude = value["latitude"];
          PlaceInfo thisPlaceInfo = new PlaceInfo();
          thisPlaceInfo.address = value['address'];
          thisPlaceInfo.description = value['description'];
          thisPlaceInfo.name = value['name'];
          thisPlaceInfo.locationCoords = LatLng(latitude, longitude);
          placeInfoList.add(thisPlaceInfo);
        }
      });
      _onAddMarkerButtonPlaceInfo();
    });
  }

//   //-------------《把所有屬於指定類別的資料推入placeInfoList(type為標記類別)》--------------

// //-------------《找尋現在地點》--------------
  void getCurrentLocation() async {
    _locationData = await _locationTracker.getLocation();
    LatLng latlng = LatLng(_locationData.latitude, _locationData.longitude);
    print(_locationData.latitude);
    print(_locationData.longitude);
    setState(() {
      _markers.clear();
      _markers.add(Marker(
        markerId: MarkerId(_lastMapPosition.toString()),
        position: latlng,
        infoWindow: InfoWindow(
          title: '現在地點',
          snippet: '5 Star Rating',
        ),
        icon: BitmapDescriptor.defaultMarker,
      ));
    });
  }

//   //-------------《找尋現在地點》--------------

//   //-------------《透過placeInfoList動態標記地圖》--------------

  void _onAddMarkerButtonPlaceInfo() {
    setState(() {
      _markers.clear();
      placeInfoList.forEach((element) {
        _markers.add(Marker(
            markerId: MarkerId(element.name),
            draggable: false,
            infoWindow:
                InfoWindow(title: element.name, snippet: element.address),
            position: element.locationCoords)); //這裏可以在依據資料增加顯示資訊
      });
      placeInfoList.clear();
    });
  }

  //-------------《透過placeInfoList動態標記地圖》--------------

  //-------------《顯示出附近咖啡店（資料等資料庫連接後在吃資料配合類別coffee_model.dart)》-----

  void _onCameraMove(CameraPosition position) {
    _lastMapPosition = position.target;
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  Future<void> getMarker() async {
    fireBaseDB.child("subject").once().then((DataSnapshot snapshot) {
      snapshot.value.forEach((key, value) {
        var longitude = value["longitude"];
        var latitude = value["latitude"];
        var locationCoords = LatLng(latitude, longitude);
        _markers.add(Marker(
            markerId: MarkerId(value["name"]),
            draggable: false,
            infoWindow:
                InfoWindow(title: value["name"], snippet: value["address"]),
            position: locationCoords)); //這裏可以在依據資料增加顯示資訊
        // placeInfoList.add(thisPlaceInfo);
      });
    });
    // print(_markers);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getMarker(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          return MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                title: Text('Maps Sample App'),
                backgroundColor: Colors.green[700],
              ),
              body: Stack(
                children: <Widget>[
                  GoogleMap(
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: testLat,
                      zoom: 10.0,
                    ),
                    mapType: _currentMapType,
                    markers: _markers,
                    onCameraMove: _onCameraMove,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Column(
                        children: <Widget>[
                          FloatingActionButton(
                            //----<顯示附件輸入類別的位置>
                            onPressed: () {
                              _getTypeInfo("coffeeShop");
                            },
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            backgroundColor: Colors.green,
                            child: const Icon(Icons.cake, size: 36.0),
                          ),
                          SizedBox(height: 16.0),
                          FloatingActionButton(
                            //----<找尋目前位置>
                            onPressed: () {
                              _getTypeInfo("thaiShop"); //資c料吃進去的是我們選擇類別的資料
                            },
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            backgroundColor: Colors.green,
                            child: const Icon(Icons.emoji_food_beverage,
                                size: 36.0),
                          ),
                          SizedBox(height: 16.0),
                          FloatingActionButton(
                            //----<找尋目前位置>
                            onPressed: () {
                              getCurrentLocation();
                            },
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            backgroundColor: Colors.green,
                            child: const Icon(Icons.gps_fixed, size: 36.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
