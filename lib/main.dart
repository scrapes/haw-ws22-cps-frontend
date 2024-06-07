import 'package:cps_ws22/MqttMap.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';

import 'NavDrawer.dart';

import 'package:uuid/uuid.dart';
import 'mqttUniversal/app.dart' if (dart.library.html) 'mqttUniversal/web.dart' as mqttsetup;

void main() {
  var mqttHost = 'wss://k3s.anwski.de/mqtt';
  MqttClient mqttClient;

  var uuid = const Uuid();
  String clientId = uuid.v4().substring(20, 36);
  mqttClient = mqttsetup.setup(mqttHost, clientId);


  mqttClient.logging(on: false);
  mqttClient.setProtocolV311();

  mqttClient.port = 443;
  mqttClient.websocketProtocols = MqttClientConstants.protocolsSingleDefault;


  final connMess = MqttConnectMessage()
      .withClientIdentifier(clientId)
      .withWillMessage("ByeBye")
      .withWillTopic("/ctrl/bye")
      .startClean(); // Non persistent session for testing
  mqttClient.connectionMessage = connMess;
  mqttClient.onConnected = () {
    print("Connected!");
    runApp(MyApp(mqttClient: mqttClient,));
  };
  mqttClient.connect();
}
class MyApp extends StatefulWidget {
  final MqttClient mqttClient;

  const MyApp({super.key, required this.mqttClient});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CPS Simulation',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'CPSWS22 Simulation', mqttClient: widget.mqttClient,),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title, required this.mqttClient}) : super(key: key);



  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final MqttClient mqttClient;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Key? get key => null;

  final _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar:true,
      drawer: NavDrawerWidget(mqttClient: widget.mqttClient,),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, size: 60), // change this size and style
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        backgroundColor: Colors.transparent, elevation: 20.0,
        foregroundColor: Colors.white,
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: [MqttMap(mqttClient: widget.mqttClient,),
          ]
        ),
      ),
    );
  }
}
