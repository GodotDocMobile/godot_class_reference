import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../bloc/search_bloc.dart';
import '../bloc/tap_event_arg.dart';
import '../constants/class_db.dart';
import '../constants/stored_values.dart';
import '../models/class_content.dart';
import '../theme/themes.dart';

import 'class_detail.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  final _searchBloc = SearchBloc();

  final _argList = List<TapEventArg>();

  final _options = [
    'All',
    'Classes Only',
    'Methods Only',
    'Members Only',
    'Signals Only',
    'Constants Only',
    'Enums Only',
    'Theme Items Only'
  ];
  bool _caseSensitive = false;
  String _searchCat = 'All';

  bool _searching = false;
  String _searchingTerm = '';

  bool _searchClass = true;
  bool _searchMethod = true;
  bool _searchConstant = true;
  bool _searchMember = true;
  bool _searchSignal = true;
  bool _searchThemeItem = true;
  bool _searchEnum = true;

  bool _isDarkTheme;

  StreamSubscription<TapEventArg> _xmlSub;

  @override
  void initState() {
    super.initState();
    _xmlSub = _searchBloc.argStream.listen((event) {
      if (event != null) {
        setState(() {
          if (_argList.length == 0 ||
              _argList.last.fieldName != event.fieldName) {
            _argList.add(event);
          }
        });
      }
    });
    _isDarkTheme = StoredValues().themeChange.isDark;
    ClassDB().loadBloc.argStream.listen(_xmlLoadSearch);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _searchBloc.dispose();
    _xmlSub.cancel().then((value) {
      _xmlSub = null;
    });
  }

  List<TapEventArg> filterResult() {
    List<TapEventArg> _rtn = List<TapEventArg>.from(_argList);

    if (!_searchClass) {
      _rtn.removeWhere((element) => element.linkType == LinkType.Class);
    }
    if (!_searchMethod) {
      _rtn.removeWhere((element) => element.linkType == LinkType.Method);
    }
    if (!_searchMember) {
      _rtn.removeWhere((element) => element.linkType == LinkType.Member);
    }
    if (!_searchSignal) {
      _rtn.removeWhere((element) => element.linkType == LinkType.Signal);
    }
    if (!_searchConstant) {
      _rtn.removeWhere((element) => element.linkType == LinkType.Constant);
    }
    if (!_searchEnum) {
      _rtn.removeWhere((element) => element.linkType == LinkType.Enum);
    }
    if (!_searchThemeItem) {
      _rtn.removeWhere((element) => element.linkType == LinkType.ThemeItem);
    }

    return _rtn;
  }

  void _onTextSubmit(String val) {
    if (_controller.text.length > 0) {
      _argList.clear();
      val = val.toLowerCase().replaceAll(' ', '');
      _searchingTerm = val;
      _doSearch(val);
    }

    if (_xmlSub != null) {
      setState(() {
        _searching = ClassDB().getDB().last.version == null;
      });
    }
  }

  void _xmlLoadSearch(ClassContent clsContent) {
    if (_xmlSub != null) {
      if (_searching && _searchingTerm.length > 0) {
        _searchSingle(clsContent);
      }

      setState(() {
        _searching = ClassDB().getDB().last.version == null;
      });
    }
  }

  void _searchSingle(ClassContent _class) {
    var _classNameContains = false;
    if (_caseSensitive) {
      _classNameContains = _class.name.contains(_searchingTerm);
    } else {
      _classNameContains = _class.name.toLowerCase().contains(_searchingTerm);
    }

    if (_classNameContains) {
      _searchBloc.argSink.add(TapEventArg(
          linkType: LinkType.Class, className: _class.name, fieldName: ''));
    }

    //search methods
    if (_class.methods != null && _class.methods.length > 0) {
      _class.methods.forEach((element) {
        if (_caseSensitive
            ? element.name.contains(_searchingTerm)
            : element.name.toLowerCase().contains(_searchingTerm)) {
          _searchBloc.argSink.add(TapEventArg(
              linkType: LinkType.Method,
              className: _class.name,
              fieldName: element.name));
        }
      });
    }

    //search signals
    if (_class.signals != null && _class.signals.length > 0) {
      _class.signals.forEach((element) {
        if (_caseSensitive
            ? element.name.contains(_searchingTerm)
            : element.name.toLowerCase().contains(_searchingTerm)) {
          _searchBloc.argSink.add(TapEventArg(
              linkType: LinkType.Signal,
              className: _class.name,
              fieldName: element.name));
        }
      });
    }

    //search constants & enum values
    if (_class.constants != null && _class.constants.length > 0) {
      _class.constants.forEach((element) {
        if (_caseSensitive
            ? element.name.contains(_searchingTerm)
            : element.name.toLowerCase().contains(_searchingTerm)) {
          if (element.enumValue != null) {
            //search enum values
            if (element.enumValue.length > 0) {
              _searchBloc.argSink.add(TapEventArg(
                  linkType: LinkType.Enum,
                  className: _class.name,
                  fieldName: "${element.enumValue}.${element.name}"));
            }
          } else {
            //search constants
            _searchBloc.argSink.add(TapEventArg(
                linkType: LinkType.Constant,
                className: _class.name,
                fieldName: element.name));
          }
        }

        //search enum names,but will show enum values as well
        if (element.enumValue != null &&
            element.enumValue.length > 0 &&
            (_caseSensitive
                ? element.enumValue.contains(_searchingTerm)
                : element.enumValue.toLowerCase().contains(_searchingTerm))) {
          _searchBloc.argSink.add(TapEventArg(
              linkType: LinkType.Enum,
              className: _class.name,
              fieldName: "${element.enumValue}.${element.name}"));
        }
      });
    }

    //search properties
    if (_class.members != null && _class.members.length > 0) {
      _class.members.forEach((element) {
        if (_caseSensitive
            ? element.name.contains(_searchingTerm)
            : element.name.toLowerCase().contains(_searchingTerm)) {
          _searchBloc.argSink.add(TapEventArg(
              linkType: LinkType.Member,
              className: _class.name,
              fieldName: element.name));
        }
      });
    }

    //search theme items
    if (_class.themeItems != null && _class.themeItems.length > 0) {
      _class.themeItems.forEach((element) {
        if (_caseSensitive
            ? element.name.contains(_searchingTerm)
            : element.name.toLowerCase().contains(_searchingTerm)) {
          _searchBloc.argSink.add(TapEventArg(
              linkType: LinkType.ThemeItem,
              className: _class.name,
              fieldName: element.name));
        }
      });
    }
  }

  void _doSearch(String term) async {
    if (_searchingTerm != term || term.length <= 1) {
      return;
    }

    if (!_caseSensitive) {
      term = term.toLowerCase();
    }
    _searching = true;
    for (int i = 0; i < ClassDB().getDB().length; i++) {
      if (ClassDB().getDB()[i].version == null) {
        break;
      }
      _searchSingle(ClassDB().getDB()[i]);
    }
  }

  List<Widget> _buildSearchResult() {
    _argList.remove(null);
    if (_argList.length == 0) {
      List<Widget> _rtn = [
        ListTile(
          title: Text('No Result'),
        )
      ];
      return _rtn;
    }

    var _filteredList = filterResult();

    List<Widget> _toRtnList = _filteredList.map((e) {
      if (e == null) {
      } else {
        if (e.linkType == LinkType.Class) {
          return ListTile(
            title:
                Text(e.linkType.toString().substring(9) + " : " + e.className),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClassDetail(
                    className: e.className,
                    args: e,
                  ),
                ),
              );
            },
          );
        }
        return ListTile(
          title: Text(e.linkType.toString().substring(9) + " : " + e.fieldName),
          subtitle: Text("Class:" + e.className),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClassDetail(
                  className: e.className,
                  args: e,
                ),
              ),
            );
          },
        );
      }
    }).toList();

    if (_searching) {
      _toRtnList.add(ListTile(
        title: Center(
          child: CircularProgressIndicator(),
        ),
      ));
    }
    return _toRtnList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            _isDarkTheme ? darkTheme.backgroundColor : Colors.white,
        iconTheme: IconThemeData(
            color: _isDarkTheme ? darkTheme.iconTheme.color : Colors.black),
        title: TextField(
          autofocus: true,
          controller: _controller,
          decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Enter a search term',
              hintStyle: TextStyle(color: Colors.white54)),
          onSubmitted: _onTextSubmit,
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _controller.clear();
            },
          )
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.0),
          child: ListTile(
            title: DropdownButton<String>(
              icon: Icon(Icons.list),
              value: _searchCat,
              items: _options.map((e) {
                return DropdownMenuItem<String>(
                  value: e,
                  child: Text(e),
                );
              }).toList(),
              onChanged: (v) {
                final _idx = _options.indexOf(v);
                _searchClass = _idx < 2;
                _searchMethod = _idx == 0 || _idx == 2;
                _searchMember = _idx == 0 || _idx == 3;
                _searchSignal = _idx == 0 || _idx == 4;
                _searchConstant = _idx == 0 || _idx == 5;
                _searchEnum = _idx == 0 || _idx == 6;
                _searchThemeItem = _idx == 0 || _idx == 7;
                setState(() {
                  _searchCat = v;
                });
              },
            ),
          ),
        ),
      ),
      body: ListView(
        children: _buildSearchResult(),
      ),
    );
  }
}
