import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:cps_ws22/NavDrawer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as l2;
import 'package:mqtt_client/mqtt_client.dart';

import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';


String getGroupIDMqttPath(groupID, bhvName) {
  return "${"group/by-id/" + groupID}/bhv/by-name/" + bhvName;
}
String getGroupNameMqttPath(groupID, bhvName) {
  return "${"group/by-name/" + groupID}/bhv/by-name/" + bhvName;
}


class MqttMap extends StatefulWidget {
  final MqttClient mqttClient;

  MqttMap({super.key, required this.mqttClient}) {
    mqttClient.subscribe(getGroupIDMqttPath("+", "PodUpdate"), MqttQos.exactlyOnce);
    mqttClient.subscribe(getGroupIDMqttPath("+", "PoiUpdateData"), MqttQos.exactlyOnce);
    mqttClient.subscribe(getGroupIDMqttPath("+", "StationUpdateData"), MqttQos.exactlyOnce);
    mqttClient.subscribe(getGroupNameMqttPath("SimControlGroup", "cmd"), MqttQos.exactlyOnce);
    print("Subbed to all");
  }


  void onConnected() {

  }



  String getCmdMqttPath(){
    return "cmd";
  }
  @override
  _MqttMapState createState() => _MqttMapState();
}

class StationInfo{
  /*
  data := StationUpdateData{
  ID:         station.Info.ID,
  Location:   station.Info.Location,
  Name:       station.Name,
  Capacity:   station.Capacity,
  Occupation: station.GetLoad(),
  Popularity: station.Popularity,
  */

  late String ID;
  late l2.LatLng Location;
  late String Name;
  late int Capacity;
  late int Occupation;
  late double ToAttraction;
  late double FromAttraction;

  StationInfo(String msg){
    Map<String, dynamic> message = jsonDecode(msg);
    Map<String, dynamic> data = message['Data'];

    Map<String, dynamic> location = data['Location'];
    Map<String, dynamic> popularity = data['Popularity'];
    double latitude = location['Latitude'];
    double longitude = location['Longitude'];

    ID = data['ID'];
    Location = l2.LatLng(latitude, longitude);
    Name = data['Name'];
    Capacity = data['Capacity'];
    Occupation = data['Occupation'];
    ToAttraction = double.parse(popularity['ToAttraction'].toString());
    FromAttraction = double.parse(popularity['FromAttraction'].toString());
  }
}
class PoiInfo {
  /*
  ID         uuid.UUID
	Name       string
	Location   Coordinate
	Attraction float64
   */
  late String ID;
  late String Name;
  late l2.LatLng Location;
  late double FromAttraction;
  late double ToAttraction;

  PoiInfo(String msg){
    Map<String, dynamic> message = jsonDecode(msg);
    Map<String, dynamic> data = message['Data'];

    Map<String, dynamic> location = data['Location'];
    Map<String, dynamic> popularity = data['Popularity'];
    double latitude = location['Latitude'];
    double longitude = location['Longitude'];

    ID = data['ID'];
    Name = data['Name'];
    Location = l2.LatLng(latitude, longitude);
    ToAttraction = double.parse(popularity['ToAttraction'].toString());
    FromAttraction = double.parse(popularity['FromAttraction'].toString());
  }
}
class PodInfo {
  /*
  ID       PodID
  Location Coordinate
  State    string
   */

  late String PodID;
  late l2.LatLng Location;
  late String State;

  PodInfo(String msg) {
    Map<String, dynamic> message = jsonDecode(msg);
    Map<String, dynamic> data = message['Data'];

    Map<String, dynamic> location = data['Location'];
    double latitude = location['Latitude'];
    double longitude = location['Longitude'];

    Location = l2.LatLng(latitude, longitude);
    State = data['State'];
    PodID = data['ID'];
  }
}

class _MqttMapState extends State<MqttMap> {

  final Random _random = Random();
  final Map<String, PodInfo> pods = HashMap();
  final Map<String, StationInfo> stations = HashMap();
  final Map<String, PoiInfo> Pois = HashMap();
  final List<Marker> _markers = [];

  void recalcMakers(){
    _markers.clear();
    if(NavDrawer.enablePods) {
      pods.forEach((key, pod) {
        _markers.add(Marker(
            width: 60,
            height: 60,
            point: pod.Location,
            child: _PodMarker(podInfo: pod,),
            key: ValueKey(key)));
      });
    }

    if(NavDrawer.enableStations) {
      stations.forEach((key, station) {
        _markers.add(Marker(
            width: 90,
            height: 100,
            point: station.Location,
            child: _StationMarker(stationInfo: station, enableAttr: NavDrawer.enablePOI,),
            key: ValueKey(key)));
      });
    }

    if(NavDrawer.enablePOI) {
      Pois.forEach((key, poi) {
        _markers.add(Marker(
            width: 85,
            height: 60,
            point: poi.Location,
            child: _PoiMarker(poiInfo: poi),
            key: ValueKey(key)));
      });
    }
  }

  void setPointList(dynamic c) {
    final MqttPublishMessage recMess = c[0].payload;
    final String topic = c[0].topic;
    if (topic == getGroupNameMqttPath("SimControlGroup", "cmd")){
      print("Reset msg");
      final pt =
      MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      Map<String, dynamic> message = jsonDecode(pt);
      Map<String, dynamic> data = message['Data'];
      if(data['Reset'] == true){
        pods.clear();
        stations.clear();
        Pois.clear();
      }

    } else if (topic.split("/").last == "PodUpdate"){
      final pt =
      MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final pod = PodInfo(pt);
      setState(() {
        pods[pod.PodID] = pod;
        recalcMakers();
      });
    } else if (topic.split("/").last == "StationUpdateData") {
      final pt =
      MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final station = StationInfo(pt);
      setState(() {
        stations[station.ID] = station;
        recalcMakers();
      });
    } else if (topic.split("/").last == "PoiUpdateData") {
      final pt =
      MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final poi = PoiInfo(pt);
      setState(() {
        Pois[poi.ID] = poi;
        recalcMakers();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.mqttClient.updates!.listen(((event) {}));
  }

  @override
  Widget build(BuildContext context) {
    print("addedUpdates");
    widget.mqttClient.updates!.listen(setPointList);

    return Flexible(
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: l2.LatLng(53.58585627858511, 9.912900441839117),
            initialZoom: 13.5,
          ),
          children: [
            TileLayer(
              urlTemplate:
              'https://api.mapbox.com/styles/v1/anwski/clx3v88ge01t901nyh6ue8y0x/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiYW53c2tpIiwiYSI6ImNsYWRyczM1aDA5MzYzcG82bTR5NTljazAifQ.UflNU104hejKt9dLVZ-irQ',
              //'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'de.anwski.cps.ws22',
            ),
            MarkerLayer(markers: _markers),
          ],
        ),
      );
  }
}

class _PodMarker extends StatefulWidget {
  const _PodMarker({Key? key, required this.podInfo}) : super(key: key);

  final PodInfo podInfo;
  @override
  _PodMarkerState createState() => _PodMarkerState();
}

class _PodMarkerState extends State<_PodMarker> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var color = Colors.white;
    if (widget.podInfo.State == "Dumped") {
      color = Colors.green;
    }

    if (widget.podInfo.State == "WaitingForLoading") {
      color = Colors.red;
    }
    var style = TextStyle(color: color, fontSize: 40, fontFamily: CupertinoIcons.iconFont);
    var text = "🚚";
    return Stack(
      children: <Widget>[
          Text(text, style: TextStyle(
      fontSize: 40,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = Colors.black, )),
        Text(text, style: TextStyle(
          fontSize: 40,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = color, ))
        ],
    );
  }
}

class _StationMarker extends StatefulWidget {
  const _StationMarker({Key? key, required this.stationInfo, required this.enableAttr}) : super(key: key);
  final StationInfo stationInfo;
  final bool enableAttr;

  @override
  _StationMarkerState createState() => _StationMarkerState();
}

class _StationMarkerState extends State<_StationMarker> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var ocup = widget.stationInfo.Occupation.toString();
    var capa = widget.stationInfo.Capacity.toString();
    var attrTo = widget.stationInfo.ToAttraction.toString().substring(0, 4);
    var attrFrom = widget.stationInfo.FromAttraction.toString().substring(0,4);
    var txt = "";
    if(!widget.enableAttr){
      txt = "🚉$ocup/$capa";
    } else {
      txt = "🚉$ocup/$capa\n$attrTo|$attrFrom";
    }
    var style = const TextStyle(color: Colors.white, fontSize: 17);
    return Stack(
      children: <Widget>[
        Text(txt, style: TextStyle(
          fontSize: 20,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.black, )),
        Text(txt, style: TextStyle(
          fontSize: 20,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = Colors.white, ))
      ],
    );
  }
}

class _PoiMarker extends StatefulWidget {
  const _PoiMarker({Key? key, required this.poiInfo}) : super(key: key);
  final PoiInfo poiInfo;

  @override
  _PoiMarkerState createState() => _PoiMarkerState();
}

class _PoiMarkerState extends State<_PoiMarker> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var attrTo = widget.poiInfo.FromAttraction.toString();
    var attrFrom = widget.poiInfo.ToAttraction.toString();
    var text ="🗼$attrTo|$attrFrom";
    return Stack(
      children: <Widget>[
        Text(text, style: TextStyle(
          fontSize: 14,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = Colors.black, )),
        Text(text, style: TextStyle(
          fontSize: 14,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = Colors.red, ))
      ],
    );
  }
}

class _ColorGenerator {
  static List<Color> colorOptions = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.indigo,
    Colors.amber,
    Colors.black,
    Colors.white,
    Colors.brown,
    Colors.pink,
    Colors.cyan
  ];

  static final Random _random = Random();

  static Color getColor() {
    return colorOptions[_random.nextInt(colorOptions.length)];
  }
}