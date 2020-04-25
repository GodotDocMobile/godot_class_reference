import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:godotclassreference/constants/stored_values.dart';
import 'package:godotclassreference/constants/tap_event_arg.dart';
import 'package:xml/xml.dart' as xml;

import 'package:godotclassreference/screens/class_detail/class_constants.dart';
import 'package:godotclassreference/screens/class_detail/class_enums.dart';
import 'package:godotclassreference/screens/class_detail/class_info.dart';
import 'package:godotclassreference/screens/class_detail/class_members.dart';
import 'package:godotclassreference/screens/class_detail/class_methods.dart';
import 'package:godotclassreference/screens/class_detail/class_signals.dart';
import 'package:godotclassreference/screens/class_detail/class_theme_items.dart';

import 'package:godotclassreference/models/class_content.dart';

class ClassDetail extends StatelessWidget {
  final String className;

  const ClassDetail({Key key, @required this.className})
      : assert(className != null),
        super(key: key);

  Future<ClassContent> getClassDetail() async {
    final version = StoredValues().prefs.getString('version');

    final file = await rootBundle
        .loadString('xmls/' + version + '/' + className + '.xml');
//    final aaa = xml.parse(file).root.children;
    final rootNode = xml
        .parse(file)
        .root
        .children
        .lastWhere((w) => w.nodeType != xml.XmlNodeType.TEXT);
    return ClassContent.fromXml(rootNode);
  }

  void onLinkTap(TapEventArg args) {}

  @override
  Widget build(BuildContext context) {
    final _classContent = getClassDetail();

    return FutureBuilder<ClassContent>(
      future: _classContent,
      builder: (BuildContext context, AsyncSnapshot<ClassContent> snapshot) {
        if (snapshot.hasData) {
          List<ClassTab> tabs = getClassTabs(snapshot.data, this.onLinkTap);
          // append theme item tab if needed
          if (snapshot.data.themeItems != null &&
              snapshot.data.themeItems.length > 0) {
            tabs.add(ClassTab(
              title: 'Theme Item',
              child: ClassThemeItems(
                clsContent: snapshot.data,
              ),
              showCnt: true,
              itemCount: snapshot.data.themeItems.length,
            ));
          }
          return DefaultTabController(
            length: tabs.length,
            child: Scaffold(
//              drawer: GCRDrawer(),
              appBar: AppBar(
                title: Text(className),
                bottom: TabBar(
                  isScrollable: true,
                  tabs: tabs.map((f) {
                    return Tab(
                      child: Row(
                        children: <Widget>[
                          Text(f.title),
                          f.showCnt
                              ? Row(
                                  children: <Widget>[
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(3)),
                                      ),
                                      height: 20,
                                      child: Center(
                                        child: Text(
                                          " " + f.itemCount.toString() + " ",
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : SizedBox()
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              body: TabBarView(
                children: tabs.map((c) {
                  return c.child;
                }).toList(),
              ),
            ),
          );
        }
        return Container(
          color: Colors.white,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

class ClassTab {
  ClassTab({this.title, this.child, this.itemCount, this.showCnt = false});

  final String title;

  final Widget child;

  final int itemCount;

  final bool showCnt;
}

List<ClassTab> getClassTabs(
    ClassContent clsContent, Function(TapEventArg args) onLinkTap) {
  return <ClassTab>[
    ClassTab(
      title: "Info",
      child: ClassInfo(
        clsContent: clsContent,
        onLinkTap: onLinkTap,
      ),
    ),
    ClassTab(
      title: "Enums",
      child: ClassEnums(
        clsContent: clsContent,
        onLinkTap: onLinkTap,
      ),
      showCnt: true,
      itemCount: clsContent.constants == null
          ? 0
          : clsContent.constants.where((w) => w.enumValue != null).length,
    ),
    ClassTab(
      title: "Constants",
      child: ClassConstants(
        clsContent: clsContent,
        onLinkTap: onLinkTap,
      ),
      showCnt: true,
      itemCount: clsContent.constants == null
          ? 0
          : clsContent.constants.where((w) => w == null).length,
    ),
    ClassTab(
      title: "Members",
      child: ClassMembers(
        clsContent: clsContent,
        onLinkTap: onLinkTap,
      ),
      showCnt: true,
      itemCount: clsContent.members == null ? 0 : clsContent.members.length,
    ),
    ClassTab(
      title: "Methods",
      child: ClassMethods(
        clsContent: clsContent,
        onLinkTap: onLinkTap,
      ),
      showCnt: true,
      itemCount: clsContent.methods == null ? 0 : clsContent.methods.length,
    ),
    ClassTab(
      title: "Signals",
      child: ClassSignals(
        clsContent: clsContent,
        onLinkTap: onLinkTap,
      ),
      showCnt: true,
      itemCount: clsContent.signals == null ? 0 : clsContent.signals.length,
    )
  ];
}
