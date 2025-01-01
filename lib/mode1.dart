import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:localpkg/online.dart';
import 'package:trafficlightsimulator/drawer.dart';
import 'package:trafficlightsimulator/util.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class GamePage1 extends StatefulWidget {
  final int mode; // 1: singleplayer; 2: multiplayer

  const GamePage1({
    super.key,
    required this.mode
  });

  @override
  State<GamePage1> createState() => _GamePage1State();
}

class _GamePage1State extends State<GamePage1> {
  Map data = {"await": "loading"};
  late io.Socket server;
  final controller = StreamController.broadcast();

  @override
  void initState() {
    super.initState();
    if (widget.mode == 2) {
      setup();
    } else {
      setupSingleplayer();
    }
  }

  void refresh() {
    setState(() {});
  }

  void setupSingleplayer() {
    data = initialData();
    refresh();
  }

  void setup() async {
    Map dataS = await getServerJsonData("/api/services/trafficlightsimulator/new");
    print("data: $dataS");
    if (dataS.containsKey("error")) {
      print("new match issue: ${dataS["error"]}");
      data = {"error": getDesc(dataS["error"])};
      refresh();
      return;
    }
    String path = dataS["path"];
    String code = dataS["code"];
    data = await connect(path, code);
    refresh();
  }

  Future<Map> connect(String path, String code) async {
    String url = "http://$host:5000";
    try {
      print("connecting at url $url$path");
      server = io.io(
        url,
        io.OptionBuilder()
          .setPath(path)
          .setTransports(['websocket'])
          .build(),
      );
      server.connect();

      server.on('message', (message) {
        print("received message: $message");
        Map dataS = jsonDecode(message);
        if (dataS.containsKey("action")) {
          String action = dataS["action"];
          switch (action) {
            case 'no manager':
              data = {"error": getDesc("no manager")};
              controller.add({"error": getDesc("no manager")});
              refresh();
            default:
              data = {"error": "No data"};
              controller.add({"error": "No data"});
              refresh();
          }
        } else {
          data = dataS;
          controller.add(dataS);
          refresh();
        }
      });

      server.on('error', (error) {
        data = {"error": error};
        controller.addError(error);
        refresh();
      });
      
      server.on('disconnect', (_) {
        data = {"error": "Connection lost"};
        controller.close();
        refresh();
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
      return {"id": id, "code": code};
    } catch (e) {
      print("setup error: $e");
      return {"error": e};
    }
  }

  @override
  Widget build(BuildContext context) {
    print("building scaffold...");
    if (data.containsKey("await")) {
      return Scaffold(body: Center(child: CircularProgressIndicator()), appBar: AppBar(
        toolbarHeight: 48.0,
        leading: closeButton(context, null),
      ));
    } else if (data.containsKey("error")) {
      return Scaffold(
        body: Center(
          child: Text("Error: ${getDesc(data["error"])}"),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(mode == 1 ? "Singleplayer • Manager" : "Match: ${data["code"]} • ID: ${data["id"]} • Manager", style: TextStyle(
            fontSize: 12
          )),
          centerTitle: true,
          toolbarHeight: 48.0,
          leading: closeButton(context, mode == 1 ? null : server),
        ),
        body: Center(
          child: Column(
            children: [
              Section(child: Row(
                children: [
                  Stoplight(),
                ],
              )),
              Section(child: Text("Controls")),
            ],
          ),
        ),
      );
    }
  }

  Widget Section({required Widget child}) {
    return Expanded(
      child: SingleChildScrollView(
        child: Center(
          child: child,
        ),
      ),
    );
  }
}