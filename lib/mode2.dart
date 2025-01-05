import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localpkg/dialogue.dart';
import 'package:localpkg/online.dart';
import 'package:trafficlightsimulator/main.dart';
import 'package:trafficlightsimulator/util.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class GamePage2 extends StatefulWidget {
  final String? code;
  final String? path;
  final bool local;

  const GamePage2({
    this.code,
    this.path,
    this.local = false,
    super.key
  });

  @override
  State<GamePage2> createState() => _GamePage2State();
}

class _GamePage2State extends State<GamePage2> with SingleTickerProviderStateMixin {
  late io.Socket webSocket;
  late AnimationController animationController;
  late Animation<double> animation;
  StreamController? controller;
  int id = 0;
  int debugId = 1;

  void addEvent(dynamic event) {
    try {
      if (controller != null && !controller!.isClosed) {
        print("adding controller event...");
        controller?.add(event);
      } else {
        throw Exception("controller is either null or closed");
      }
    } catch (e) {
      print("unable to add controller event: $e");
    }
  }

  @override
  void initState() {
    id = debugId;
    super.initState();
    initializeController();

    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..repeat(reverse: true);

    animation = Tween<double>(begin: 0.0, end: 1.0).animate(animationController);
  }

  @override
  void dispose() {
    animationController.dispose();
    controller?.close();
    super.dispose();
  }

  void initializeController() {
    print("initializing controller...");
    if (controller == null || controller!.isClosed) {
      print("controller need initialized");
      controller = StreamController.broadcast();
    } else {
      print("controller initialization skipped");
    }
  }

  void delayData({required Map data, int milliseconds = 1000}) async {
    print("delaying data for ${milliseconds}ms");
    await Future.delayed(Duration(milliseconds: 500));
    addEvent(data);
    print("send delayed event: ${milliseconds}ms");
  }

  Future<Map> setup() async {
    if (widget.local) {
      print("DEBUG: using local data");
      Map data = initialData();
      delayData(data: data);
      return {"id": debugId};
    } else {
      String path = widget.path!;
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
                addEvent({"error": getDesc("no manager")});
            }
          } else {
            addEvent(data);
          }
        });

        webSocket.on('error', (error) {
          controller?.addError(error);
        });

        // Handle disconnection
        webSocket.on('disconnect', (_) {
          controller?.close();
        });

        print("waiting on first message...");
        final firstMessage = await controller?.stream.first;
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

        final idS = message["id"];
        print("id: $idS");
        id = idS;
        return {"id": id};
      } catch (e) {
        print("setup error: $e");
        return {"error": e};
      }
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
                  onPressed: () {closeDialogue(context, widget.local ? null : webSocket);},
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
                title: Text("Room: ${widget.code ?? "local"} • ID: $id", style: TextStyle(
                  fontSize: 12
                )),
                centerTitle: true,
                toolbarHeight: 48.0,
                leading: IconButton(
                  icon: Icon(Icons.cancel_outlined),
                  onPressed: () {closeDialogue(context, widget.local ? null : webSocket);},
                  iconSize: 32,
                ),
                actions: [
                  if (widget.local)
                  IconButton(
                    icon: Icon(Icons.contact_mail),
                    onPressed: () async {
                      TextEditingController textController = TextEditingController();
                      showDialog<String>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Enter a new ID'),
                            content: TextField(
                              controller: textController,
                              decoration: InputDecoration(hintText: 'ID...'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  // Close the dialog and return null
                                  Navigator.of(context).pop();
                                },
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  int oldId = id;
                                  id = int.tryParse(textController.text) ?? id;
                                  print("set id from $oldId to $id");
                                  setState(() {});
                                  Navigator.of(context).pop();
                                },
                                child: Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    iconSize: 32,
                  ),
                  if (widget.code != null)
                  IconButton(
                    icon: Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.code!));
                      showSnackBar(context, "Code copied!");
                    },
                  ),
                ],
              ),
              body: Center(
                child: StreamBuilder(
                  stream: controller?.stream,
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

                    print("received stream data");
                    Map data = snapshot.data;

                    double sizeFactor = 1.75;
                    double dimensionFactor = 6;
                    double width = MediaQuery.of(context).size.width / dimensionFactor;
                    double height = MediaQuery.of(context).size.height / dimensionFactor;
                    double size = width > height ? height / sizeFactor : width / sizeFactor;
                    print("size: $size,$width,$height");

                    if (data.containsKey("error")) {
                      print("manual error: ${data["error"]}");
                      return Text("Error: ${data["error"]}");
                    }

                    int index = id - 1;
                    print("id: $id");
                    print("index: $index");
                    return Stoplights(align: false, showNumber: false, height: height, width: width, size: size, data: data, item: data["items"][index], animation: animation, index: index);
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