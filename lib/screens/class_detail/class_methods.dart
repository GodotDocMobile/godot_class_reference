import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../components/description_text.dart';
import '../../constants/class_db.dart';
import '../../constants/colors.dart';
import '../../bloc/tap_event_arg.dart';
import '../../constants/stored_values.dart';
import '../../models/class_content.dart';

class ClassMethods extends StatefulWidget {
  final ClassContent clsContent;
  final Function(TapEventArg args) onLinkTap;
  final Stream<TapEventArg> eventStream;

  ClassMethods(
      {Key key, this.clsContent, this.eventStream, @required this.onLinkTap})
      : assert(onLinkTap != null),
        super(key: key);

  @override
  _ClassMethodsState createState() => _ClassMethodsState();
}

class _ClassMethodsState extends State<ClassMethods> {
  ItemScrollController _scrollController;
  ItemPositionsListener _itemPositionsListener;

  bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = StoredValues().themeChange.isDark;
    _scrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create();
    widget.eventStream.listen((v) {
      try {
        scrollTo(v);
      } catch (_) {}
    });
  }

  void scrollTo(TapEventArg args) {
    if (widget.clsContent.name == args.className &&
        args.linkType == LinkType.Method) {
      final _targetIndex =
          widget.clsContent.methods.indexWhere((w) => w.name == args.fieldName);
      if (_targetIndex != -1) {
        _scrollController.scrollTo(
          curve: Curves.easeInOutCubic,
          index: _targetIndex,
          duration: Duration(milliseconds: 500),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.clsContent.methods == null ||
        widget.clsContent.methods.length == 0) {
      return Center(
        child: Text('0 method in this class'),
      );
    }

    return ScrollablePositionedList.builder(
        itemCount: widget.clsContent.methods.length,
        itemScrollController: _scrollController,
        itemPositionsListener: _itemPositionsListener,
        itemBuilder: (context, index) {
          final m = widget.clsContent.methods[index];
          return ListTile(
            leading: m.returnValue == null
                ? Text('void')
                : ClassDB()
                        .getDB()
                        .any((element) => element.name == m.returnValue.type)
                    ? InkWell(
                        child: Text(
                          m.returnValue.type,
                          style: TextStyle(
                            fontSize: 15,
                            color: godotColor,
                          ),
                        ),
                        onTap: () {
                          TapEventArg _arg = TapEventArg(
                              className: m.returnValue.type,
                              linkType: LinkType.Class,
                              fieldName: '');
                          widget.onLinkTap(_arg);
                        },
                      )
                    : Text(
                        m.returnValue.type,
                        style: TextStyle(
                          fontSize: 15,
                        ),
                      ),
            title: Text(
              m.name,
              softWrap: true,
              style: TextStyle(
                fontSize: 25,
              ),
            ),
            subtitle: Column(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    (m.arguments != null && m.arguments.length > 0
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'arguments:',
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: <Widget>[
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: m.arguments.map((a) {
                                        return ClassDB().getDB().any(
                                                (element) =>
                                                    element.name == a.type)
                                            ? InkWell(
                                                child: Text(
                                                  a.type,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: godotColor,
                                                  ),
                                                ),
                                                onTap: () {
                                                  TapEventArg _arg =
                                                      TapEventArg(
                                                          className: a.type,
                                                          linkType:
                                                              LinkType.Class,
                                                          fieldName: '');
                                                  widget.onLinkTap(_arg);
                                                },
                                              )
                                            : Text(
                                                a.type,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                ),
                                              );
                                      }).toList(),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: m.arguments.map((a) {
                                        return Text(
                                          a.name,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: _isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: m.arguments.map((a) {
                                        return a.defaultValue == null
                                            ? Text('')
                                            : Row(
                                                children: <Widget>[
                                                  Text(
                                                    ' = ',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  Text(
                                                    a.defaultValue,
                                                    style: TextStyle(
                                                      color: _isDarkMode
                                                          ? Colors.white
                                                          : Colors.black,
                                                    ),
                                                  )
                                                ],
                                              );
                                      }).toList(),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          )
                        : SizedBox()),
                    Row(
                      children: <Widget>[
                        m.qualifiers == null
                            ? SizedBox()
                            : Row(
                                children: <Widget>[
                                  Text(
                                    'qualifiers ',
                                  ),
                                  Text(
                                    m.qualifiers,
                                    style: TextStyle(
                                        color: _isDarkMode
                                            ? Colors.white
                                            : Colors.black),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ],
                ),
                DescriptionText(
                  className: widget.clsContent.name,
                  content: m.description,
                  onLinkTap: widget.onLinkTap,
                ),
              ],
            ),
          );
        });
  }
}
