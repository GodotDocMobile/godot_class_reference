import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import 'constant.dart';
import 'member.dart';
import 'method.dart';
import 'signal.dart';
import 'theme_item.dart';

// names for node tag used in node_tag
final Map<classNodeType, String> tagName = {
  classNodeType.D2: "Node",
  classNodeType.D3: "Node",
  classNodeType.Control: "Node",
  classNodeType.VisualScript: "VScript",
  classNodeType.VisualShader: "VShader",
  classNodeType.Other: "Node",
  classNodeType.None: "",
};

// color for node tag used in node_tag
final Map<classNodeType, Color> tagColor = {
  classNodeType.D2: Color(0xffa5b7f3),
  classNodeType.D3: Color(0xfffc9c9c),
  classNodeType.Control: Color(0xffa5efac),
  classNodeType.VisualScript: Colors.blueGrey,
  classNodeType.VisualShader: Colors.blueGrey,
  classNodeType.Other: Colors.blueGrey,
  classNodeType.None: Colors.blueGrey,
};

// names for class_select filter classes pop up
final Map<classNodeType, String> filterName = {
  classNodeType.D2: "2D Nodes",
  classNodeType.D3: "3D Nodes",
  classNodeType.Control: "Control Nodes",
  classNodeType.VisualScript: "Visual Script Nodes",
  classNodeType.VisualShader: "Visual Shader Nodes",
  classNodeType.Other: "Other Nodes",
  classNodeType.None: "None Nodes",
};

// names for StoredValues
final Map<classNodeType, String> filterOptionStoreKey = {
  classNodeType.D2: "show2DNodes",
  classNodeType.D3: "show3DNodes",
  classNodeType.Control: "showControlNodes",
  classNodeType.VisualScript: "showVisualScriptNodes",
  classNodeType.VisualShader: "showVisualShaderNodes",
  classNodeType.Other: "showOtherNodes",
  classNodeType.None: "showNonNodes",
};

// names of nodes in inherit chain
final Map<classNodeType, String> nodeName = {
  classNodeType.D2: "Node2D",
  classNodeType.D3: "Spatial",
  classNodeType.Control: "Control",
  classNodeType.VisualScript: "VisualScriptNode",
  classNodeType.VisualShader: "VisualShaderNode",
  classNodeType.Other: "Node",
  classNodeType.None: "",
};

enum classNodeType {
  D2,
  D3,
  Control,
  VisualScript,
  VisualShader,
  // these two has to be in the tail
  Other,
  None,
}

class ClassContent {
  String name;
  String inherits;
  String category;
  String version;
  String briefDescription;
  String demos;
  List<Constant> constants;
  String description;
  List<Member> members;
  List<Method> methods;
  List<Signal> signals;
  List<ThemeItem> themeItems;
  String tutorials;
  String inheritChain;

  /* the rest properties are not in the xml file nor json file index */
  classNodeType nodeType = classNodeType.None;

  ClassContent(
      {this.name,
      this.inherits,
      this.category,
      this.version,
      this.briefDescription,
      this.demos,
      this.constants,
      this.description,
      this.members,
      this.methods,
      this.signals,
      this.themeItems,
      this.tutorials,
      this.inheritChain});

  static void fromJson(json) {}

  static ClassContent fromXml(XmlElement node) {
    ClassContent toReturn = ClassContent();

    final rootAttrs = node.attributes;

    // attribute fields
    toReturn.name = _getAttrByName(rootAttrs, 'name');

    toReturn.inherits = _getAttrByName(rootAttrs, 'inherits');

    toReturn.category = _getAttrByName(rootAttrs, 'category');

    toReturn.version = _getAttrByName(rootAttrs, 'version');

    toReturn.briefDescription =
        node.findElements('brief_description').first.text;

    // constants
    final constantRoot = node.findElements('constants');
    if (constantRoot.length > 0) {
      final constantNodes = constantRoot.first.children;
      toReturn.constants = constantNodes.map((f) {
        final nodeAttr = f.attributes;
        return Constant(
            name: _getAttrByName(nodeAttr, 'name'),
            value: _getAttrByName(nodeAttr, 'value'),
            enumValue: _getAttrByName(nodeAttr, 'enum'),
            constantText: f.text);
      }).toList();
    }

    toReturn.description = node.findElements('description').first.text;

    // members
    final memberRoot = node.findElements('members');
    if (memberRoot.length > 0) {
      final memberNodes = memberRoot.first.children;
      toReturn.members = memberNodes.map((f) {
        final nodeAttr = f.attributes;
        return Member(
            name: _getAttrByName(nodeAttr, 'name'),
            type: _getAttrByName(nodeAttr, 'type'),
            setter: _getAttrByName(nodeAttr, 'setter'),
            getter: _getAttrByName(nodeAttr, 'getter'),
            enumValue: _getAttrByName(nodeAttr, 'enum'),
            memberText: f.text);
      }).toList();
    }

    // methods
    final methodRoot = node.findElements('methods');
    if (methodRoot.length > 0) {
      final methodNodes = methodRoot.first.children;
      toReturn.methods = methodNodes.map((f) {
        final element = f as XmlElement;
        final nodeAttr = f.attributes;

        final argumentNodes = element.findElements('argument');
        final methodReturnNodes = element.findAllElements('return');

        MethodReturn methodRtn;
        if (methodReturnNodes.length > 0) {
          final methodReturnAttr = methodReturnNodes.first.attributes;
          methodRtn = MethodReturn(
            type: _getAttrByName(methodReturnAttr, 'type'),
            enumValue: _getAttrByName(methodReturnAttr, 'enum'),
          );
        }

        List<MethodArgument> _arguments = argumentNodes.map((a) {
          final argumentAttr = a.attributes;
          return MethodArgument(
              index: _getAttrByName(argumentAttr, 'index'),
              name: _getAttrByName(argumentAttr, 'name'),
              type: _getAttrByName(argumentAttr, 'type'),
              enumValue: _getAttrByName(argumentAttr, 'enum'),
              defaultValue: _getAttrByName(argumentAttr, 'default'));
        }).toList();

        _arguments.sort((a, b) => a.index.compareTo(b.index));

        return Method(
            name: _getAttrByName(nodeAttr, 'name'),
            qualifiers: _getAttrByName(nodeAttr, 'qualifiers'),
            description: element.findAllElements('description').first.text,
            arguments: _arguments,
            returnValue: methodRtn);
      }).toList();
    }

    // signals
    final signalRoot = node.findElements('signals');
    if (signalRoot.length > 0) {
      final signalNodes = signalRoot.first.children;
      toReturn.signals = signalNodes.map((f) {
        final element = f as XmlElement;
        final nodeAttr = f.attributes;
        final argumentNodes = element.findElements('argument');
        return Signal(
            name: _getAttrByName(nodeAttr, 'name'),
            description: element.findElements('description').first.text,
            arguments: argumentNodes.map((a) {
              final argumentAttr = a.attributes;
              return SignalArgument(
                  index: _getAttrByName(argumentAttr, 'index'),
                  name: _getAttrByName(argumentAttr, 'name'),
                  type: _getAttrByName(argumentAttr, 'type'));
            }).toList());
      }).toList();
    }

    // theme_items
    final themeItemRoot = node.findElements('theme_items');
    if (themeItemRoot.length > 0) {
      final themeItemNodes = themeItemRoot.first.children;
      toReturn.themeItems = themeItemNodes.map((f) {
        final nodeAttr = f.attributes;
        return ThemeItem(
            name: _getAttrByName(nodeAttr, 'name'),
            type: _getAttrByName(nodeAttr, 'type'));
      }).toList();
    }

    return toReturn;
  }

  static String _getAttrByName(List<XmlAttribute> attrs, String attrName) {
    return attrs.singleWhere((w) => w.name.local == attrName, orElse: () {
      return null;
    })?.value;
  }

  void setNodeType() {
    if (this.inheritChain == null) {
      return;
    }
    for (var e in classNodeType.values) {
      if (this.inheritChain.contains('[${nodeName[e]}]')) {
        this.nodeType = e;
        return;
      }
    }
  }
}
