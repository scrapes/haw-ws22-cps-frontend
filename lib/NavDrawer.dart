import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';


class NavDrawerWidget extends StatefulWidget{
  final MqttClient mqttClient;
  const NavDrawerWidget({super.key, required this.mqttClient});
  @override
  NavDrawer createState() => NavDrawer();
}


class NavDrawer extends State {
  static bool enablePOI = false;
  static bool enableStations = true;
  static bool enablePods = true;

  String getAttrJson(double attr, String name){
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: min(800, MediaQuery.of(context).size.width - 60),
      elevation: 30.0,
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: <Widget>[
          const DrawerHeader(
            margin: EdgeInsets.all(0),
            decoration: BoxDecoration(
                color: Colors.redAccent,
            ),
            child: Text(
              'Menü',
              style: TextStyle(color: Colors.white, fontSize: 35),
            )
          ),
          const ListTile(
            title: Text(
              "Sichtbar"
            ),
          ),
          ListTile(
            leading: const Text("🚚 Pod", style: TextStyle(color: Colors.black, fontSize: 20)),
            trailing: Switch(onChanged: (val) => {
            setState((){ NavDrawer.enablePods = val;})
            }, value: NavDrawer.enablePods),
            onTap: () => { },
          ),
          ListTile(
            leading: const Text("🚉 Station", style: TextStyle(color: Colors.black, fontSize: 20)),
            trailing: Switch(onChanged: (val) => {
              setState((){ NavDrawer.enableStations = val;})
            }, value: NavDrawer.enableStations),
            onTap: () => { },
          ),
          ListTile(
            leading: const Text("🗼POI", style: TextStyle(color: Colors.black, fontSize: 20)),
            trailing: Switch(onChanged: (val) => {
              setState((){ NavDrawer.enablePOI = val;})
            }, value: NavDrawer.enablePOI),
            onTap: () => { },
          ),
          const ListTile(
            title: Text(
                "Legende"
            ),
          ),
          const ListTile(
            leading: const Text("🚚", style: TextStyle(color: Colors.black, fontSize: 20)),
            title: Text(
                "Pod in bewegung"
            ),
          ),
          const ListTile(
            leading: const Text("🚚", style: TextStyle(color: Colors.green, fontSize: 20)),
            title: Text(
                "Pod lädt ab"
            ),
          ),
          const ListTile(
            leading: const Text("🚚", style: TextStyle(color: Colors.redAccent, fontSize: 20)),
            title: Text(
                "Pod lädt auf"
            ),
          ),
          const ListTile(
            leading: const Text("🚉", style: TextStyle(color: Colors.black, fontSize: 20)),
            title: Text(
                "Station <Auslastung>/<Kapazität>\n<Anziehung>|<Abstoßung>"
            ),
          ),
          const ListTile(
            leading: const Text("🗼", style: TextStyle(color: Colors.black, fontSize: 20)),
            title: Text(
                "Point of interest\n<Anziehung>|<Abstoßung>"
            ),
          ),
        ],
      ),
    );
  }
}