import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:localpkg/online.dart';
import 'package:trafficlightsimulator/util.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class GamePage2 extends StatefulWidget {
  final String code;
  final String path;

  const GamePage2({
    required this.code,
    required this.path,
    super.key
  });

  @override
  State<GamePage2> createState() => _GamePage2State();
}

class _GamePage2State extends State<GamePage2> {
  late io.Socket webSocket;
  final controller = StreamController.broadcast();

  /// connect to the WebSocket
  Future<Map> setup() async {
    String path = widget.path;
    String url = "http://$host:5000";
    try {
      print("connecting at url $url$path");
      webSocket = io.io(
        url,
        io.OptionBuilder()
          .setPath(path)
          .setTransports(['websocket'])
          .build(),
      );
      webSocket.connect();
  
      webSocket.on('message', (message) {
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
      });

      webSocket.on('error', (error) {
        controller.addError(error);
      });

      // Handle disconnection
      webSocket.on('disconnect', (_) {
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
    return FutureBuilder<Map>(
      future: setup(),
      builder: (BuildContext context, AsyncSnapshot<Map> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()), appBar: AppBar(
            toolbarHeight: 48.0,
            leading: closeButton(context, null),
          ));
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        } else if (snapshot.hasData) {
          Map data = snapshot.data!;
          if (data.containsKey("error")) {
            return Scaffold(
              appBar: AppBar(
                centerTitle: true,
                toolbarHeight: 48.0,
                leading: IconButton(
                  icon: Icon(Icons.cancel_outlined),
                  onPressed: () {closeDialogue(context, webSocket);},
                  iconSize: 32,
                ),
              ),
              body: Center(
                child: Text("Error: ${data["error"]}"),
              ),
            );
          } else {
            return Scaffold(
              appBar: AppBar(
                title: Text("Match: ${widget.code} • ID: ${data["id"]}", style: TextStyle(
                  fontSize: 12
                )),
                centerTitle: true,
                toolbarHeight: 48.0,
                leading: IconButton(
                  icon: Icon(Icons.cancel_outlined),
                  onPressed: () {closeDialogue(context, webSocket);},
                  iconSize: 32,
                ),
              ),
              body: Center(
                child: StreamBuilder(
                  stream: controller.stream,
                  builder: (context, snapshot) {
                    print("building stream...");
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text("Waiting...");
                    } else if (snapshot.hasError) {
                      print("snapshot error: ${snapshot.error}");
                      return Text("Error: ${snapshot.error}");
                    } else if (!snapshot.hasData) {
                      return Text("Connection lost");
                    }
                
                    Map data = snapshot.data;
                    if (data.containsKey("error")) {
                      print("manual error: ${data["error"]}");
                      return Text("Error: ${data["error"]}");
                    }
                
                    return Text(
                      "Received: $data",
                      style: TextStyle(fontSize: 18),
                    );
                  },
                ),
              ),
            );
          }
        } else {
          return Scaffold(
            body: Center(child: Text("Something went wrong")),
          );
        }
      },
    );
  }
}