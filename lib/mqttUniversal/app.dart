import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient setup(String serverAddress, String uniqueID) {
  var client = MqttServerClient(serverAddress, uniqueID);
  if(serverAddress.contains("wss://") || serverAddress.contains("ws://")){
    client.useWebSocket = true;
  }
  return client;
}
