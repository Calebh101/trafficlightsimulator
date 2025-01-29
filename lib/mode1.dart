import 'dart:async';
import 'dart:convert';

import 'package:localpkg/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localpkg/dialogue.dart';
import 'package:localpkg/online.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scoreboardsimulator/util.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:scoreboardsimulator/var.dart';

class GamePage1 extends StatefulWidget {
  final int mode; // 1: singleplayer; 2: multiplayer
  final String path;
  final String code;

  const GamePage1({
    super.key,
    required this.mode,
    this.path = "/",
    this.code = "xxxxxxxxx",
  });

  @override
  State<GamePage1> createState() => _GamePage1State();
}

class _GamePage1State extends State<GamePage1> with SingleTickerProviderStateMixin {
  Map data = {};
  Map prevData = {};
  int id = 0;

  io.Socket? server;
  late AnimationController animationController;
  late Animation<double> animation;
  final Completer<void> serverInitialization = Completer<void>();


  @override
  void initState() {
    print("current data: $data");
    data = {"await": "loading"};

    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: blinkTime),
    )..repeat(reverse: true);

    animation = Tween<double>(begin: 0.0, end: 1.0).animate(animationController);

    if (widget.mode == 2) {
      setup();
    } else {
      setupSingleplayer();
    }

    loadSettings();
    super.initState();
  }

  Future<void> loadSettings() async {
    print("getting settings...");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    refresh();
  }

  void uninitializeServer() {
    print("uninitializing server...");
    if (server != null) {
      print("uninitializing server...");
      server!.destroy();
      server = null;
    } else {
      print("server uninitialization skipped: not initialized");
    }
  }

  void initializeController(StreamController? controller) {
    print("initializing controller...");
    if (controller == null || controller.isClosed) {
      print("initializing controller...");
      controller = StreamController.broadcast();
    } else {
      print("reinitializing controller...");
      controller.close();
      controller = StreamController.broadcast();
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    uninitializeServer();
    super.dispose();
  }

  void refresh() {
    print("refreshing...");
    if (widget.mode == 2 && data != prevData) {
      print("sending data... (${widget.mode},${data == prevData})");
      Map dataS = {"items": data["items"]};
      server?.send([jsonEncode(dataS)]);
      prevData = Map.from(data.map((key, value) => MapEntry(key, value is Map ? Map.from(value) : value)));
    } else {
      print("not sending data: ${widget.mode},${data == prevData}");
    }
    if (mounted) {
      setState(() {});
    } else {
      warn("refresh called when not mounted");
    }
  }

  void setupSingleplayer() async {
    data = initialData();
    refresh();
  }

  void addEvent(dynamic event, StreamController? controller) {
    print("sending event...");
    try {
      if (controller != null && !controller.isClosed) {
        print("adding controller event...");
        controller.add(event);
      } else {
        print("controller needs initialized");
        initializeController(controller);
      }
    } catch (e) {
      print("unable to add controller event: $e");
    }
  }

  void setup() async {
    uninitializeServer();
    connect(widget.path, widget.code);
  }

  void connect(String path, String code) async {
    print("starting connect...");
    String host = getFetchInfo(debug: debug)["host"];
    String url = "http://$host:5000";
    StreamController? controller = StreamController.broadcast();
    try {
      print("connecting at url $url$path");
      if (server != null) {
        throw Exception("server is not ready for initialization: server is not null");
      }
      print("initializing server...");
      server = io.io(
        url,
        io.OptionBuilder()
          .setPath(path)
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
      );
      server?.io.options?['path'] = path;
      print("connecting server... (${server?.io.options?.entries})");
      if (server!.connected) {
        print("server is not ready for connection: server is already connected");
        return;
      }
      server!.connect();
      serverInitialization.complete();
      print("server initialized: ${server?.io.uri}, ($server)");

      server?.on('message', (message) {
        print("received message");
        Map dataS = jsonDecode(message);
        if (dataS.containsKey("action")) {
          String action = dataS["action"];
          switch (action) {
            case 'no manager':
              data = {"error": getDesc("no manager")};
              addEvent({"error": getDesc("no manager")}, controller);
              refresh();
            default:
              data = {"error": "No data"};
              addEvent({"error": "No data"}, controller);
              refresh();
          }
        } else {
          addEvent(dataS, controller);
        }
      });

      server?.on('error', (error) {
        data = {"error": error};
        addEvent(error, controller);
        refresh();
      });
      
      server?.on('disconnect', (_) {
        data = {"error": "Connection lost"};
        controller.close();
        refresh();
      });

      print("waiting on first message...");
      final firstMessage = await controller.stream.first;
      Map message = {};
      print("received first message: $firstMessage");

      if (firstMessage is Map) {
        message = firstMessage;
      } else {
        message = jsonDecode(firstMessage);
      }

      print("checking for errors...");
      if (message.containsKey("error")) {
        print("connection error: ${message["error"]}: ${getDesc(message["error"])}");
        data = {"error": getDesc(message["error"])};
        refresh();
        return;
      }

      final idS = message["id"];
      print("id: $id (received $idS)");
      data = {"id": id, "code": code, "items": initialData()};
      refresh();
    } catch (e) {
      print("setup error: $e");
      data = {"error": e.toString()};
      refresh();
    }
  }

  Map getData(int id, int idx) {
    return data["items"][id.toString()]["items"][idx];
  }

  io.Socket? getWebsocket() {
    dynamic websocket;
    websocket = widget.mode == 1 ? null : server;
    print("${getFetchInfo()["mode"]},${websocket.runtimeType}");
    return websocket;
  }

  @override
  Widget build(BuildContext context) {
    print("building scaffold...");

    if (data.containsKey("await")) {
      return Scaffold(body: Center(child: CircularProgressIndicator()), appBar: AppBar(
        toolbarHeight: 48.0,
        leading: closeButton(context, getWebsocket()),
      ));
    } else if (data.containsKey("error")) {
      return Scaffold(
        body: Center(
          child: Text("Error: ${getDesc(data["error"] ?? "null")}"),
        ),
        appBar: AppBar(
          toolbarHeight: 48.0,
          leading: closeButton(context, getWebsocket()),
        )
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.mode == 1 ? "Singleplayer • Manager" : "Room: ${data["code"]} • ID: $id • Manager", style: TextStyle(
            fontSize: 12
          )),
          centerTitle: true,
          toolbarHeight: 48.0,
          leading: closeButton(context, getWebsocket()),
          actions: [
            if (kDebugMode && widget.mode == 2)
            IconButton(
              icon: Icon(Icons.code),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonEncode(data)));
                showSnackBar(context, "Data copied!");
              },
            ),
            if (widget.mode == 2)
            IconButton(
              icon: Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: data["code"]));
                showSnackBar(context, "Code copied!");
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                Section(
                  child: Scoreboard(size: 0.5, data: data).build(),
                ),
                SizedBox(height: 30),
                Section(
                  child: Text("Go suck nuts"),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}