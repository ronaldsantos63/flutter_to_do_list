import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    title: "Lista de Tarefas",
    theme: ThemeData(
        primaryColor: Colors.blue,
        accentColor: Colors.blueAccent,
        hintColor: Colors.blueAccent),
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];
  final _todoController = TextEditingController();
  Map<String, dynamic> _lastRemoved;
  int _lastRemovePos;

  void _addToDo() {
    Map<String, dynamic> newToDo = new Map();
    newToDo['title'] = _todoController.text;
    newToDo['done'] = false;
    setState(() {
      _toDoList.add(newToDo);
    });
    _todoController.clear();
    _saveData();
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _readData().then((data) {
        setState(() {
          _toDoList = json.decode(data);
        });
      });
    });
  }

  Future<Null> _onRefresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b){
        if (a['done'] && !b["done"]) return 1;
        else if (!a['done'] && b["done"]) return -1;
        else return 0;
      });
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: TextField(
                  controller: _todoController,
                  maxLength: 50,
                  cursorWidth: 3,
                  autofocus: true,
                  autocorrect: true,
                  style:
                      TextStyle(color: Colors.lightBlueAccent, fontSize: 25.0),
                  decoration: InputDecoration(
                    labelText: "Nova Tarefa",
                  ),
                )),
                IconButton(
                    icon: Icon(Icons.add_circle),
                    iconSize: 35,
                    color: Colors.blue,
                    onPressed: _addToDo)
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10),
                itemCount: _toDoList.length,
                itemBuilder: buildItem,
              ),
            )
          )
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: UniqueKey(),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]['title']),
        value: _toDoList[index]['done'],
        dense: false,
        secondary: CircleAvatar(
          child:
              Icon(_toDoList[index]['done'] ? Icons.check : Icons.access_time),
        ),
        onChanged: (done) {
          setState(() {
            _toDoList[index]['done'] = done;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovePos = index;
          _toDoList.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa ${_lastRemoved['title']} removida!"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemovePos, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 4),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
