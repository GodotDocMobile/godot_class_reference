import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:godotclassreference/constants/class_list.dart';
import 'package:godotclassreference/constants/stored_values.dart';
import 'package:godotclassreference/screens/class_detail.dart';
import 'package:godotclassreference/components/drawer.dart';

class ClassSelect extends StatelessWidget {
  static Future<List<String>> getXmlFiles() async {
    await StoredValues().readValue();

    String version = StoredValues().prefs.getString('version');
//    print(version);
    if (version == null || version.length == 0) {
      version = '3.0';
      await StoredValues().prefs.setString('version', '3.0');
    }

    final file = await rootBundle.loadString('xmls/files_' + version + '.json');
    final decoded = json.decode(file);
    final parsedList = List<String>.from(decoded);
    ClassList().updateList(parsedList);
    return parsedList;
  }

  @override
  Widget build(BuildContext context) {
    Future<List<String>> jsonContent = getXmlFiles();

    return Scaffold(
      drawer: GCRDrawer(),
      appBar: AppBar(
        title: Text("Classes"),
//          actions: <Widget>[
//            FlatButton(
//              child: Icon(Icons.search),
//              onPressed: () {},
//            )
//          ],
      ),
      body: FutureBuilder<List<String>>(
        future: jsonContent,
        builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
          if (snapshot.hasData) {
            snapshot.data.sort();
            return ListView(
              children: snapshot.data
                  .map((f) => ListTile(
                      title: Text(f.replaceAll('.xml', '')),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClassDetail(
                                  className: f.replaceAll('.xml', '')),
                            ));
                      }))
                  .toList(),
            );
          }
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
