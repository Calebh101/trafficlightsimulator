import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:localpkg/online.dart';
import 'package:trafficlightsimulator/drawer.dart';
import 'package:trafficlightsimulator/main.dart';
import 'package:trafficlightsimulator/util.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:trafficlightsimulator/var.dart';

class GamePage1 extends StatefulWidget {
  final int mode; // 1: singleplayer; 2: multiplayer
  final int roads;

  const GamePage1({
    super.key,
    required this.mode,
    this.roads = 4,
  });

  @override
  State<GamePage1> createState() => _GamePage1State();
}

class _GamePage1State extends State<GamePage1> with SingleTickerProviderStateMixin {
  int id = 0;
  Map data = {"await": "loading"};
  Map prevData = {};
  int stoplightRunCount = 0;
  String currentPreset = "initial";
  String initialPreset = "1/0+3/0Y";
  bool yellowLight = false;

  late io.Socket server;
  late AnimationController animationController;
  late Animation<double> animation;

  @override
  void initState() {
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..repeat(reverse: true);

    animation = Tween<double>(begin: 0.0, end: 1.0).animate(animationController);

    if (widget.mode == 2) {
      setup();
    } else {
      setupSingleplayer();
    }

    super.initState();
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

  void refreshPreset(Map data) {
    print("refreshing preset $currentPreset...");
    data = applyPreset(preset: currentPreset, data: data);
    refresh();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  void refresh() {
    print("refreshing...");
    if (widget.mode == 2 && data != prevData) {
      print("sending data... (${widget.mode},${data == prevData})");
      Map dataS = {"items": data["items"]};
      server.send([jsonEncode(dataS)]);
      prevData = Map.from(data.map((key, value) => MapEntry(key, value is Map ? Map.from(value) : value)));
    } else {
      print("not sending data: ${widget.mode},${data == prevData}");
    }
    setState(() {});
  }

  void setupSingleplayer() {
    data = initialData();
    data = applyPreset(preset: initialPreset, data: data);
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
        addEvent(event, controller);
      }
    } catch (e) {
      print("unable to add controller event: $e");
    }
  }

  void setup() async {
    Map dataS = await getServerJsonData("/api/services/trafficlightsimulator/new");
    print("data: $dataS");
    if (dataS.containsKey("error")) {
      print("new room issue: ${dataS["error"]}");
      data = {"error": getDesc(dataS["error"])};
      refresh();
      return;
    }
    String path = dataS["path"];
    String code = dataS["code"];
    currentPreset = initialPreset;
    connect(path, code);
    refresh();
  }

  void connect(String path, String code) async {
    String url = "http://$host:5000";
    StreamController? controller = StreamController.broadcast();
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

      server.on('error', (error) {
        data = {"error": error};
        addEvent(error, controller);
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
      print("id: $idS (ignored)");
      data = {"id": id, "code": code, "items": initialData()["items"]};
      refresh();
    } catch (e) {
      print("setup error: $e");
      data = {"error": e};
      refresh();
    }
  }

  Map getData(int id, int idx) {
    return data["items"][id.toString()]["items"][idx];
  }

  @override
  Widget build(BuildContext context) {
    print("building scaffold...");
    double size = 20;
    double boxWidth = MediaQuery.of(context).size.width / 3;
    double boxHeight = ((MediaQuery.of(context).size.height / 2) - 48) / 3;

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
        appBar: AppBar(
          toolbarHeight: 48.0,
          leading: closeButton(context, null),
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
          leading: closeButton(context, mode == 1 ? null : server),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                Section(
                  child: StoplightsContainer(height: boxHeight, width: boxWidth, size: size, data: data, animation: animation),
                ),
                SizedBox(height: 30),
                Section(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: widget.roads == 4 ? Column(
                      children: [
                        ControlRow(
                          title: "Straight",
                          children: [
                            Control(
                              context: context,
                              child: Text("#1 and #3 straight"),
                              function: () {
                                data = applyPreset(preset: "1/0+3/0Y", data: data);
                                refresh();
                              },
                            ),
                            Control(
                              context: context,
                              child: Text("#2 and #4 straight"),
                              function: () {
                                data = applyPreset(preset: "2/0+4/0Y", data: data);
                                refresh();
                              },
                            ),
                            Control(
                              context: context,
                              child: Text("#1 and #3 straight (no left turn yield)"),
                              function: () {
                                data = applyPreset(preset: "1/0+3/0", data: data);
                                refresh();
                              },
                            ),
                            Control(
                              context: context,
                              child: Text("#2 and #4 straight (no left turn yield)"),
                              function: () {
                                data = applyPreset(preset: "2/0+4/0", data: data);
                                refresh();
                              },
                            ),
                          ]
                        ),
                        ControlRow(
                          title: "Left",
                          children: [
                            Control(
                              context: context,
                              child: Text("#1 and #3 left"),
                              function: () {
                                data = applyPreset(preset: "1/-2+3/-2", data: data);
                                refresh();
                              }
                            ),
                            Control(
                              context: context,
                              child: Text("#2 and #4 left"),
                              function: () {
                                data = applyPreset(preset: "2/-2+4/-2", data: data);
                                refresh();
                              }
                            ),
                          ],
                        ),
                        ControlRow(
                          title: "Straight & Left",
                          children: [
                            Control(
                              context: context,
                              child: Text("#1 straight and left"),
                              function: () {
                                data = applyPreset(preset: "1/0+-2", data: data);
                                refresh();
                              }
                            ),
                            Control(
                              context: context,
                              child: Text("#2 straight and left"),
                              function: () {
                                data = applyPreset(preset: "2/0+-2", data: data);
                                refresh();
                              }
                            ),
                            Control(
                              context: context,
                              child: Text("#3 straight and left"),
                              function: () {
                                data = applyPreset(preset: "3/0+-2", data: data);
                                refresh();
                              }
                            ),
                            Control(
                              context: context,
                              child: Text("#4 straight and left"),
                              function: () {
                                data = applyPreset(preset: "4/0+-2", data: data);
                                refresh();
                              }
                            ),
                          ],
                        ),
                        ControlRow(
                          title: "Global",
                          children: [
                            Control(
                              context: context,
                              child: Text("Solid green"),
                              function: () {
                                data = applyPreset(preset: "solidgreen", data: data, global: true);
                                refresh();
                              }
                            ),
                            Control(
                              context: context,
                              child: Text("Solid yellow"),
                              function: () {
                                data = applyPreset(preset: "solidyellow", data: data, global: true);
                                refresh();
                              }
                            ),
                            Control(
                              context: context,
                              child: Text("Solid red"),
                              function: () {
                                data = applyPreset(preset: "solidred", data: data, global: true);
                                refresh();
                              }
                            ),
                            Control(
                              context: context,
                              child: Text("Flashing green"),
                              function: () {
                                data = applyPreset(preset: "flashgreen", data: data, global: true);
                                refresh();
                              }
                            ),
                            Control(
                              context: context,
                              child: Text("Flashing yellow"),
                              function: () {
                                data = applyPreset(preset: "flashyellow", data: data, global: true);
                                refresh();
                              }
                            ),
                            Control(
                              context: context,
                              child: Text("Flashing red"),
                              function: () {
                                data = applyPreset(preset: "flashred", data: data, global: true);
                                refresh();
                              }
                            ),
                          ],
                        ),
                      ],
                    ) : widget.roads == 3 ? Column() : Text("Error: invalid road count: ${widget.roads}"),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget Section({Widget? child}) {
    return Expanded(
      child: Center(
        child: child,
      ),
    );
  }

  Map applyPreset({required String preset, required Map data, bool global = false}) {
    print("applying preset $preset for roads ${widget.roads}");
    currentPreset = preset;
    Map presetS = presets[global ? "global" : "${widget.roads}"][preset];
    List areas = data["items"];
    stoplightRunCount++;

    for (var i = 0; i < areas.length; i++) {
      var area = areas[i];
      Map values = presetS["${area["id"]}"];
      List items = area["items"];
      items = setStoplightProperty(key: "subactive", value: values["-1"], items: items, direction: -1, areaIndex: i); // left
      items = setStoplightProperty(key: "active", value: values["0"], items: items, direction: 0, areaIndex: i); // straight
      items = setStoplightProperty(key: "subactive", value: values["1"], items: items, direction: 1, areaIndex: i); // right
      area["items"] = items;
    }

    data["items"] = areas;
    return data;
  }

  void customizeLights(Map data, int light) {
    int index = light - 1;
    Map item = json.decode(json.encode(data["items"][index]));
    print("customizing light $light($index)");
    print("${item.runtimeType},${data["items"].runtimeType},${data["items"][index].runtimeType}");

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text("Customize Light #$light"),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.95,
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: item["items"].asMap().entries.map<Widget>((entry) {
                            Map itemS = entry.value;
                            int index = entry.key;
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stoplight(size: 30, direction: itemS["direction"], active: itemS["active"], subactive: itemS["subactive"], animation: animation),
                                  IconButton(
                                    icon: Icon(Icons.remove),
                                    color: Colors.red,
                                    iconSize: 40,
                                    onPressed: () {
                                      item["items"].removeAt(index);
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList()
                        ),
                      ),
                    ),
                    PopupMenuButton(
                      child: Icon(
                        Icons.add,
                        color: Colors.green,
                        size: 60,
                      ),
                      onSelected: (value) {
                        print('adding stoplight: $value');
                        item["items"] = insertItem(item["items"], {
                          "direction": value,
                          "active": 6,
                          "subactive": 0,
                        });
                        setState(() {});
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          PopupMenuItem(
                            value: -2,
                            child: Text('Left only'),
                          ),
                          PopupMenuItem(
                            value: -1,
                            child: Text('Left/straight'),
                          ),
                          PopupMenuItem(
                            value: 0,
                            child: Text('Straight only'),
                          ),
                          PopupMenuItem(
                            value: 1,
                            child: Text('Right/straight'),
                          ),
                          PopupMenuItem(
                            value: 2,
                            child: Text('Right only'),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
                TextButton(
                  child: Text("Save"),
                  onPressed: () {
                    print("saving stoplight $index");
                    data["items"][index] = Map<String, Object>.from(item.map((key, value) => MapEntry(key, value as Object)));
                    refreshPreset(data);
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  List insertItem(List list, Map newItem) {
    int newDirection = newItem['direction'];
    int lastIndex = -1;

    for (int i = 0; i < list.length; i++) {
      if (list[i]['direction'] == newDirection) {
        lastIndex = i;
      }
    }

    if (lastIndex != -1) {
      list.insert(lastIndex + 1, newItem);
    } else {
      int insertIndex = list.length;
      for (int i = 0; i < list.length; i++) {
        if (list[i]['direction'] > newDirection) {
          insertIndex = i;
          break;
        }
      }
      list.insert(insertIndex, newItem);
    }

    return list;
  }

  Widget StoplightsContainer({required double height, required double width, required double size, required Map data, required Animation<double> animation}) {
    double stoplightSize = size * (width * 0.006);
    stoplightSize = stoplightSize > size ? size : stoplightSize;
    return Stack(
      children: data["items"].asMap().entries.map<Widget>((entry) {
        Map item = entry.value;
        int index = entry.key;
        return GestureDetector(
          onTap: () {
            customizeLights(data, item["id"]);
          },
          child: Container(
            child: Stoplights(
              height: height,
              width: width,
              size: stoplightSize,
              data: data,
              item: data["items"][index],
              index: index,
              animation: animation,
            ),
          ),
        );
      }).toList(),
    );
  }

  Map lightCountdownHandler({required Map data, required int areaIndex, required int itemIndex, required String key, required dynamic value}) {
    Map item = data["items"][areaIndex]["items"][itemIndex];
    print("setting up light countdown for $areaIndex,$itemIndex to $key:$value");
    if ((item[key] == 3 || item[key] == 5) && (value == 1)) {
      yellowLight = true;
      item[key] = 2;
    }
    if (yellowLight) {
      lightCountdown(data: data, areaIndex: areaIndex, itemIndex: itemIndex, key: key, value: value);
    } else {
      item[key] = value;
    }
    return item;
  }

  void lightCountdown({int milliseconds = 750, required Map data, required int areaIndex, required int itemIndex, required String key, required dynamic value}) async {
    int currentStoplightRunCount = stoplightRunCount;
    print("starting yellow light countdown for $areaIndex,$itemIndex for ${milliseconds}ms to $key:$value");
    await Future.delayed(Duration(milliseconds: milliseconds));
    if (stoplightRunCount == currentStoplightRunCount) {
      yellowLight = false;
      data["items"][areaIndex]["items"][itemIndex][key] = value;
    } else {
      print("yellow light countdown cancelled: $stoplightRunCount,$currentStoplightRunCount");
    }
    refresh();
  }

  List setStoplightProperty({int? direction, int? index, required String key, required dynamic value, required List items, required int areaIndex}) {
    if (direction != null) {
      print("setting property based on direction: $direction");
      for (var i = 0; i < items.length; i++) {
        Map item = items[i];
        print("checking property for $areaIndex,$i ($direction,${item["direction"]})");
        if (direction == 0) {
          if (item['direction'] == direction || item['direction'] == direction - 1 || item['direction'] == direction + 1) { // directions -1 to 1 (straight)
            lightCountdownHandler(data: data, areaIndex: areaIndex, itemIndex: i, key: key, value: value);
          }
        } else if (direction == -1) {
          if (item['direction'] == direction || item['direction'] == direction - 1) { // directions -1 to -2 (left)
            lightCountdownHandler(data: data, areaIndex: areaIndex, itemIndex: i, key: key, value: value);
          }
        } else if (direction == 1) {
          if (item['direction'] == direction || item['direction'] == direction + 1) { // directions 1 to 2 (right)
            lightCountdownHandler(data: data, areaIndex: areaIndex, itemIndex: i, key: key, value: value);
          }
        } else {
          throw Exception("Invalid direction in setStoplightProperty.");
        }
      }
    } else if (index != null) {
      print("setting property based on index: $index");
      items[index][key] = value;
    } else {
      throw Exception("Either direction or index is required in setStoplightProperty.");
    }
    return items;
  }
}