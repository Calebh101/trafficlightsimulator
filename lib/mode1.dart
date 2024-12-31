import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:localpkg/online.dart';
import 'package:trafficlightsimulator/util.dart';

class GamePage1 extends StatefulWidget {
  const GamePage1({super.key});

  @override
  State<GamePage1> createState() => _GamePage1State();
}

class _GamePage1State extends State<GamePage1> {
  late WebSocket server;
  final controller = StreamController.broadcast();

  Future<Map> setup() async {
    return {};
  }

  /// connect to the WebSocket
  Future<Map> connect(int port) async {
    String url = "ws://$host:$port";
    try {
      server = await WebSocket.connect(url);
      server.listen((message) {
        print("received message: $message");
        Map data = jsonDecode(message);
        if (data.containsKey("action")) {
          String action = data["action"];
          switch (action) {
            case 'no manager':
              controller.add({"error": getDesc("no manager")});
          }
        } else {
          controller.add(data);
        }
      }, onError: (error) {
        controller.addError(error);
      }, onDone: () {
        controller.close();
      });

      print("waiting on first message...");
      final firstMessage = await controller.stream.first;
      Map message = {};

      if (firstMessage is Map) {
        message = firstMessage;
      } else {
        message = jsonDecode(firstMessage);
      }

      print("checking for errors...");
      if (message.containsKey("error")) {
        print("connection error: ${message["error"]}: ${getDesc(message["error"])}");
        return {"error": getDesc(message["error"])};
      }

      final id = message["id"];
      print("id: $id");
      return {"id": id};
    } catch (e) {
      print("setup error: $e");
      return {"error": e};
    }
  }

  @override
  Widget build(BuildContext context) {
    print("building scaffold...");
  }
}