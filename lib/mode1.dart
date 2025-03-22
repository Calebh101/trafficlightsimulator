import 'dart:async';
import 'dart:convert';

import 'package:localpkg/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localpkg/dialogue.dart';
import 'package:localpkg/online.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trafficlightsimulator/drawer.dart';
import 'package:trafficlightsimulator/util.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:trafficlightsimulator/var.dart';

class GamePage1 extends StatefulWidget {
  final int mode; // 1: singleplayer; 2: multiplayer
  final int roads;
  final String path;
  final String code;

  const GamePage1({
    super.key,
    required this.mode,
    required this.roads,
    this.path = "/",
    this.code = "xxxxxxxxx",
  });

  @override
  State<GamePage1> createState() => _GamePage1State();
}

class _GamePage1State extends State<GamePage1> with SingleTickerProviderStateMixin {
  Map data = {};
  Map prevData = {};
  Map config = {};
  int id = 0;
  int stoplightRunCount = 0;
  int initializeControllerRunCount = 0;
  String currentPreset = "initial";
  bool yellowLight = false;
  bool rightRed = false;
  bool extendedStoplights = false;
  List customPresets = [];

  String initialPreset = "1/0+3/0Y";
  String initialPreset3 = "2/0+3/0";

  io.Socket? server;
  late AnimationController animationController;
  late Animation<double> animation;
  final Completer<void> serverInitialization = Completer<void>();


  @override
  void initState() {
    if (widget.roads == 3) {
      initialPreset = initialPreset3;
    }

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
    getCustomPresets();
    super.initState();
  }

  Future<void> loadSettings() async {
    print("getting settings...");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    yellowLightTime = prefs.getInt("yellowLightTimer") ?? yellowLightTime;
    rightRed = prefs.getBool("rightRed") ?? rightRed;
    extendedStoplights = prefs.getBool("extended") ?? extendedStoplights;
    print("mode1 settings: $rightRed,$extendedStoplights");
    refresh();
  }

  Future<void> saveCustomPresets() async {
    String key = "customPresets${widget.roads}";
    print("customPresets: save: $key");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, json.encode(customPresets));
    print("successfully saved custom presets");
  }

  Future<void> getCustomPresets() async {
    String key = "customPresets${widget.roads}";
    print("customPresets: get: $key");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? result = prefs.getString(key);
    if (result != null) {
      customPresets = json.decode(result);
      print("successfully got custom presets");
      refresh();
    } else {
      print("no custom presets saved");
    }
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

  Future<void> refreshPreset(Map data) async {
    print("refreshing preset $currentPreset...");
    data = await applyPreset(preset: currentPreset, data: data);
    refresh();
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
      Map dataS = {"items": data["items"], "roads": widget.roads, "rightRed": rightRed, "extended": extendedStoplights};
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
    data = initialData(widget.roads);
    data = await applyPreset(preset: initialPreset, data: data);
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
    currentPreset = initialPreset;
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
      print("id: $idS (ignored)");
      List items = initialData(widget.roads)["items"];
      data = {"id": id, "code": code, "items": items};
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

  io.Socket? getWebsocket() {
    dynamic websocket;
    websocket = widget.mode == 1 ? null : server;
    print("${getFetchInfo()["mode"]},${websocket.runtimeType}");
    return websocket;
  }

  @override
  Widget build(BuildContext context) {
    print("building scaffold...");

    double size = 15;
    double factor = 2.5;
    double boxWidth = MediaQuery.of(context).size.width / factor;
    double boxHeight = ((MediaQuery.of(context).size.height / 2) - 48) / factor;

    if (data.containsKey("await")) {
      return Scaffold(body: Center(child: CircularProgressIndicator()), appBar: AppBar(
        toolbarHeight: 48.0,
        leading: closeButton(context, getWebsocket()),
      ));
    } else if (data.containsKey("error")) {
      return Scaffold(
        body: Center(
          child: Text("Error: ${getDesc(data["error"])}"),
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
                  child: StoplightsContainer(height: boxHeight, width: boxWidth, size: size, data: data, animation: animation),
                ),
                SizedBox(height: 30),
                Section(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      children: [
                        if (widget.roads == 4)
                        ControlRow(
                          title: "Straight",
                          children: [
                            Control(
                              context: context,
                              child: Text("#1 and #3 straight"),
                              function: () async {
                                data = await applyPreset(preset: "1/0+3/0Y", data: data);
                                refresh();
                              },
                            ),
                            Control(
                              context: context,
                              child: Text("#2 and #4 straight"),
                              function: () async {
                                data = await applyPreset(preset: "2/0+4/0Y", data: data);
                                refresh();
                              },
                            ),
                            Control(
                              context: context,
                              child: Text("#1 and #3 straight (no left turn yield)"),
                              function: () async {
                                data = await applyPreset(preset: "1/0+3/0", data: data);
                                refresh();
                              },
                            ),
                            Control(
                              context: context,
                              child: Text("#2 and #4 straight (no left turn yield)"),
                              function: () async {
                                data = await applyPreset(preset: "2/0+4/0", data: data);
                                refresh();
                              },
                            ),
                          ]
                        ),
                        if (widget.roads == 4)
                        ControlRow(
                          title: "Left",
                          children: [
                            Control(
                              context: context,
                              child: Text("#1 and #3 left"),
                              function: () async {
                                data = await applyPreset(preset: "1/-2+3/-2", data: data);
                                refresh();
                              }
                            ),
                            Control(
                              context: context,
                              child: Text("#2 and #4 left"),
                              function: () async {
                                data = await applyPreset(preset: "2/-2+4/-2", data: data);
                                refresh();
                              }
                            ),
                          ],
                        ),
                        if (widget.roads == 4)
                        ControlRow(
                          title: "Straight & Left",
                          children: [
                            Control(
                              context: context,
                              child: Text("#1 straight and left"),
                              function: () async {
                                data = await applyPreset(preset: "1/0+-2", data: data);
                                refresh();
                              }
                            ),
                            Control(
                              context: context,
                              child: Text("#2 straight and left"),
                              function: () async {
                                data = await applyPreset(preset: "2/0+-2", data: data);
                                refresh();
                              }
                            ),
                            Control(
                              context: context,
                              child: Text("#3 straight and left"),
                              function: () async {
                                data = await applyPreset(preset: "3/0+-2", data: data);
                                refresh();
                              }
                            ),
                            Control(
                              context: context,
                              child: Text("#4 straight and left"),
                              function: () async {
                                data = await applyPreset(preset: "4/0+-2", data: data);
                                refresh();
                              }
                            ),
                          ],
                        ),
                        if (widget.roads == 3)
                        ControlRow(
                          title: "Main",
                          children: [
                            Control(
                              context: context,
                              child: Text("#2 and #3 straight"),
                              function: () async {
                                data = await applyPreset(preset: "2/0+3/0Y", data: data);
                                refresh();
                              }
                            ),
                            Control(
                              context: context,
                              child: Text("#2 and #3 straight (no left turn yield)"),
                              function: () async {
                                data = await applyPreset(preset: "2/0+3/0", data: data);
                                refresh();
                              }
                            ),
                            Control(
                              context: context,
                              child: Text("#1 left"),
                              function: () async {
                                data = await applyPreset(preset: "1/-2", data: data);
                                refresh();
                              }
                            ),
                            Control(
                              context: context,
                              child: Text("#3 straight and left"),
                              function: () async {
                                data = await applyPreset(preset: "3/0+-2", data: data);
                                refresh();
                              },
                            ),
                          ],
                        ),
                        ControlRow(
                          title: "Other",
                          children: [
                            Control(
                              context: context,
                              child: Text("Solid green"),
                              function: () async {
                                data = await applyPreset(preset: "solidgreen", data: data, key: "global");
                                refresh();
                              }
                            ),
                            Control(
                              context: context,
                              child: Text("Solid yellow"),
                              function: () async {
                                data = await applyPreset(preset: "solidyellow", data: data, key: "global");
                                refresh();
                              }
                            ),
                            Control(
                              context: context,
                              child: Text("Solid red"),
                              function: () async {
                                data = await applyPreset(preset: "solidred", data: data, key: "global");
                                refresh();
                              }
                            ),
                            Control(
                              context: context,
                              child: Text("Flashing green"),
                              function: () async {
                                data = await applyPreset(preset: "flashgreen", data: data, key: "global");
                                refresh();
                              }
                            ),
                            Control(
                              context: context,
                              child: Text("Flashing yellow"),
                              function: () async {
                                data = await applyPreset(preset: "flashyellow", data: data, key: "global");
                                refresh();
                              }
                            ),
                            Control(
                              context: context,
                              child: Text("Flashing red"),
                              function: () async {
                                data = await applyPreset(preset: "flashred", data: data, key: "global");
                                refresh();
                              }
                            ),
                            Control(
                              context: context,
                              child: Text("Off"),
                              function: () async {
                                data = await applyPreset(preset: "off", data: data, key: "global");
                                refresh();
                              }
                            ),
                          ],
                        ),
                        ControlRow(
                          title: "Custom",
                          children: [
                            ...customPresets.asMap().entries.map<Widget>((entry) {
                              int index = entry.key;
                              Map item = entry.value;

                              return Control(
                                context: context,
                                function: () async {
                                  data = await applyPreset(data: data, preset: item["name"], key: "custom", index: index);
                                  refresh();
                                },
                                child: Text("${item["name"]}"),
                                button: IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () async {
                                    print("editing preset ${item["name"]}");
                                    Map? result = await editPreset(preset: jsonDecode(jsonEncode(item)), delete: true);
                                    if (result == null) {
                                      print("action cancelled");
                                      return;
                                    }
                                    if (result.containsKey("delete")) {
                                      if (result["delete"] == true) {
                                        print("deleting preset ${result["name"]}");
                                        customPresets.removeAt(index);
                                        refresh();
                                      } else {
                                        throw Exception("Unable to delete custom preset ${result["name"]}: result contains key 'delete', but 'delete' is not true.");
                                      }
                                    }
                                    print("editing preset ${result["name"]}");
                                    customPresets[index] = result;
                                    saveCustomPresets();
                                    refresh();
                                  },
                                ),
                              );
                            }).toList(),
                            Control(
                              context: context,
                              function: () async {
                                try {
                                  Map configS = jsonDecode(jsonEncode(config));
                                  Map? result = await editPreset(delete: false, preset: {"name": "New Preset", "items": configS});
                                  if (result == null) {
                                    print("action cancelled");
                                    return;
                                  }
                                  print("adding preset ${result["name"]}");
                                  customPresets.add(result);
                                  saveCustomPresets();
                                  refresh();
                                } catch (e) {
                                  print("new custom preset error: $e");
                                  showSnackBar(context, "There was an unexpected error creating a new custom preset. Maybe it didn't finish setting up.");
                                }
                              },
                              child: Text("New preset"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Future<Map?> editPreset({required Map preset, bool delete = false}) async {
    print("editing custom preset ${preset["name"]} (delete: $delete)");
    TextEditingController textController = TextEditingController(text: preset["name"]);
    final result = showDialog<Map>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text("Customize Preset ${preset["name"]}"),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.95,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            decoration: InputDecoration(hintText: 'Enter a name...'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Column(
                          children: List.generate(widget.roads, (index) {
                            int road = index + 1;
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text("Stoplight #$road"),
                                  ...List.generate(3, (index) {
                                    int dir = index - 1;
                                    Widget row = Row(
                                      children: [
                                        Container(
                                          width: 80,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(getNameForDirection(dir)),
                                          ),
                                        ),
                                        DropdownButton<int>(
                                          value: preset["items"]["$road"]["$dir"],
                                          hint: Text(getNameForDirection(dir)),
                                          onChanged: (int? newValue) {
                                            setState(() {
                                              preset["items"]["$road"]["$dir"] = newValue;
                                            });
                                          },
                                          items: <int>[0, 1, 2, 3, 4, 5, 6]
                                              .map<DropdownMenuItem<int>>((int value) {
                                            return DropdownMenuItem<int>(
                                              value: value,
                                              child: Text(getNameForState(value)),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    );
                                    print("output check in progress: ${widget.roads},null,null");
                                    if (widget.roads == 4) {
                                      print("output check successful: ${widget.roads},true,null");
                                      return row;
                                    } else {
                                      print("output check in progress: ${widget.roads},false,null");
                                      print(data);
                                      List? allowed = data["items"].firstWhere((item) => item['id'] == road)["dir"];
                                      if (allowed == null) {
                                        throw Exception("allowed is null");
                                      }
                                      if (allowed.contains(dir)) {
                                        print("output check successful: ${widget.roads},false,true");
                                        return row;
                                      } else {
                                        print("output check failed: ${widget.roads},false,false");
                                        return SizedBox.shrink();
                                      }
                                    }
                                  }),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text("Save"),
                  onPressed: () {
                    preset["name"] = textController.text;
                    Navigator.of(context).pop(preset);
                  },
                ),
                if (delete)
                TextButton(
                  child: Text("Delete"),
                  onPressed: () async {
                    if (await showConfirmDialogue(context: context, title: "Are you sure?", description: "Are you sure you want to delete your custom preset, ${preset["name"]}?") ?? false) {
                      showSnackBar(context, "Deleted preset ${preset["name"]}");
                      Navigator.of(context).pop({"delete": true});
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
    return result;
  }

  Future<Map> applyPreset({required String preset, required Map data, String? key, int index = -1}) async {
    key ??= widget.roads.toString();
    print("applying preset $preset for $key[$index]");
    currentPreset = preset;
    Map presetS = {};

    if (key == "custom") {
      print("detected custom preset: $preset[$key[$index]]");
      if (index >= 0) {
        presetS = customPresets[index]["items"];
      } else {
        throw Exception("applyPreset: Invalid index for custom preset: $index");
      }
    } else {
      presetS = presets[key][preset];
    }

    print("initializing preset merge...");
    List areas = data["items"];
    config = presetS;
    stoplightRunCount++;

    print("starting preset merge...");
    for (var i = 0; i < areas.length; i++) {
      var area = areas[i];
      print("using area[${area["id"]}]");
      Map values = presetS["${area["id"]}"];
      List items = area["items"];
      items = await setStoplightProperty(key: "subactive", value: values["-1"], items: items, direction: -1, areaIndex: i); // left
      items = await setStoplightProperty(key: "active", value: values["0"], items: items, direction: 0, areaIndex: i); // straight
      items = await setStoplightProperty(key: "subactive", value: values["1"], items: items, direction: 1, areaIndex: i); // right
      area["items"] = items;
    }

    data["items"] = areas;
    return data;
  }

  void customizeLights(Map data, int light) {
    int index = light - 1;
    Map item = json.decode(json.encode(data["items"][index]));
    print("customizing light $light($index)");
    print("item types: ${item.runtimeType},${data["items"].runtimeType},${data["items"][index].runtimeType}");

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
                                  Stoplight(size: 30, direction: itemS["direction"], active: itemS["active"], subactive: itemS["subactive"], animation: animation, rightRed: rightRed, extended: extendedStoplights),
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
                    ClipOval(
                      child: PopupMenuButton(
                        child: Icon(
                          Icons.add,
                          color: Colors.green,
                          size: 60,
                        ),
                        onSelected: (value) {
                          print('adding stoplight: $value');
                          item["items"] = insertItem(item["items"], {
                            "direction": value,
                            "active": 0,
                            "subactive": 0,
                          });
                          setState(() {});
                        },
                        itemBuilder: (BuildContext context) {
                          List allowed = data["items"].firstWhere((item) => item['id'] == light)["allowed"] ?? [-2,-1,0,1,2];
                          return [
                            if (allowed.contains(-2))
                            PopupMenuItem(
                              value: -2,
                              child: Text('Left only'),
                            ),
                            if (allowed.contains(-1))
                            PopupMenuItem(
                              value: -1,
                              child: Text('Left/straight'),
                            ),
                            if (allowed.contains(0))
                            PopupMenuItem(
                              value: 0,
                              child: Text('Straight only'),
                            ),
                            if (allowed.contains(1))
                            PopupMenuItem(
                              value: 1,
                              child: Text('Right/straight'),
                            ),
                            if (allowed.contains(2))
                            PopupMenuItem(
                              value: 2,
                              child: Text('Right only'),
                            ),
                          ];
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text("Save"),
                  onPressed: () {
                    print("saving stoplight $index");
                    data["items"][index] = Map<String, Object>.from(item.map((key, value) => MapEntry(key, value as Object)));
                    try {
                      refreshPreset(data);
                    } catch (e) {
                      print("customizeLights.refreshPreset error: $e");
                      refresh();
                    }
                    Navigator.of(context).pop();
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
        return Stoplights(
          roads: widget.roads,
          height: height,
          width: width,
          size: stoplightSize,
          data: data,
          item: data["items"][index],
          index: index,
          animation: animation,
          rightRed: rightRed,
          extended: extendedStoplights,
          function: () {
            customizeLights(data, item["id"]);
          },
        );
      }).toList(),
    );
  }

  Future<Map> lightCountdownHandler({required Map data, required int areaIndex, required int itemIndex, required String key, required dynamic value}) async {
    await Future.delayed(Duration(milliseconds: 1));
    Map item = data["items"][areaIndex]["items"][itemIndex];
    print("setting up light countdown for $areaIndex,$itemIndex to $key:$value");
    if ((item[key] == 3 || item[key] == 5) && (value == 1)) {
      yellowLight = true;
      item[key] = 2;
    }
    await Future.delayed(Duration(milliseconds: 1));
    if (yellowLight) {
      lightCountdown(data: data, areaIndex: areaIndex, itemIndex: itemIndex, key: key, value: value);
    } else {
      item[key] = value;
    }
    return item;
  }

  Future<void> lightCountdown({required Map data, required int areaIndex, required int itemIndex, required String key, required dynamic value}) async {
    int currentStoplightRunCount = stoplightRunCount;
    print("starting yellow light countdown for $areaIndex,$itemIndex for ${yellowLight}ms to $key:$value");
    await Future.delayed(Duration(milliseconds: yellowLightTime));
    if (stoplightRunCount == currentStoplightRunCount) {
      yellowLight = false;
      data["items"][areaIndex]["items"][itemIndex][key] = value;
    } else {
      print("yellow light countdown cancelled: $stoplightRunCount,$currentStoplightRunCount");
    }
    await Future.delayed(Duration(milliseconds: 2));
    refresh();
  }

  Future<List> setStoplightProperty({int? direction, int? index, required String key, required dynamic value, required List items, required int areaIndex}) async {
    if (direction != null) {
      print("setting property based on direction: $direction");
      for (var i = 0; i < items.length; i++) {
        Map item = items[i];
        print("checking property for $areaIndex,$i ($direction,${item["direction"]})");
        if (direction == 0) {
          if (item['direction'] == direction || item['direction'] == direction - 1 || item['direction'] == direction + 1) { // directions -1 to 1 (straight)
            await lightCountdownHandler(data: data, areaIndex: areaIndex, itemIndex: i, key: key, value: value);
          }
        } else if (direction == -1) {
          if (item['direction'] == direction || item['direction'] == direction - 1) { // directions -1 to -2 (left)
            await lightCountdownHandler(data: data, areaIndex: areaIndex, itemIndex: i, key: key, value: value);
          }
        } else if (direction == 1) {
          if (item['direction'] == direction || item['direction'] == direction + 1) { // directions 1 to 2 (right)
            await lightCountdownHandler(data: data, areaIndex: areaIndex, itemIndex: i, key: key, value: value);
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