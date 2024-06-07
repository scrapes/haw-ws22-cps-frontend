// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cps_ws22/main.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:uuid/uuid.dart';
import 'package:cps_ws22/mqttUniversal/app.dart' if (dart.library.html) 'package:cps_ws22/mqttUniversal/web.dart' as mqttsetup;

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    var mqttHost = 'wss://mqtt.cps.datenspieker.de/mqtt';
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

    };
    mqttClient.connect();
    print("Connected!");
    await tester.pumpWidget(MyApp(mqttClient: mqttClient,));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
