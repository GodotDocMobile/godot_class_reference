import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:godotclassreference/screens/class_detail/zero_content_hint.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:godotclassreference/theme/themes.dart';
import 'package:godotclassreference/bloc/tap_event_bloc.dart';
import 'package:godotclassreference/components/link_text.dart';
import 'package:godotclassreference/components/description_text.dart';
import 'package:godotclassreference/bloc/tap_event_arg.dart';
import 'package:godotclassreference/constants/stored_values.dart';
import 'package:godotclassreference/models/class_content.dart';

class ClassSignals extends StatefulWidget {
  final ClassContent? clsContent;

  ClassSignals({
    Key? key,
    this.clsContent,
  }) : super(key: key);

  @override
  _ClassSignalsState createState() => _ClassSignalsState();
}

class _ClassSignalsState extends State<ClassSignals> {
  ItemScrollController? _scrollController;

  ItemPositionsListener? _itemPositionsListener;

  double propertyIndent = 50;

  @override
  void initState() {
    super.initState();
    _scrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (storedValues.tapEventBloc.state.fieldName.isNotEmpty) {
        try {
          scrollTo(storedValues.tapEventBloc.state);
        } catch (_) {}
        storedValues.tapEventBloc.reached();
      }
    });
  }

  void scrollTo(TapEventArg args) {
    if (widget.clsContent!.name == args.className &&
        args.propertyType == PropertyType.Signal) {
      final _targetIndex = widget.clsContent!.signals!
          .indexWhere((w) => w.name == args.fieldName);
      if (_targetIndex != -1) {
        _scrollController!.scrollTo(
          curve: Curves.easeInOutCubic,
          index: _targetIndex,
          duration: Duration(milliseconds: 500),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.clsContent!.signals == null ||
        widget.clsContent!.signals!.length == 0) {
      return ZeroContentHint(clsContent: widget.clsContent!);
    }

    return BlocListener<TapEventBloc, TapEventArg>(
      bloc: storedValues.tapEventBloc,
      listenWhen: (previous, current) => ModalRoute.of(context)!.isCurrent,
      listener: (context, state) {
        if (state.className == widget.clsContent!.name &&
            state.propertyType == PropertyType.Signal) {
          try {
            scrollTo(storedValues.tapEventBloc.state);
          } catch (_) {}
          storedValues.tapEventBloc.reached();
        }
      },
      child: ScrollablePositionedList.builder(
          itemCount: widget.clsContent!.signals!.length,
          itemScrollController: _scrollController,
          itemPositionsListener: _itemPositionsListener,
          itemBuilder: (context, index) {
            final s = widget.clsContent!.signals![index];
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: [
                ListTile(
                  title: Text(
                    s.name!,
                    style: monoOptionalStyle(context,
                        baseStyle: TextStyle(fontSize: 25)),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                          children: s.arguments!.map((e) {
                        return Column(children: [
                          Row(children: [
                            LinkText(
                              text: e.type!,
                              // onLinkTap: widget.onLinkTap,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              e.name!,
                              style: TextStyle(fontSize: 15),
                            ),
                          ]),
                        ]);
                      }).toList()),
                      Divider(
                        indent: propertyIndent,
                      ),
                      DescriptionText(
                        className: widget.clsContent!.name!,
                        content: s.description!,
                        // onLinkTap: widget.onLinkTap,
                      ),
                    ],
                  ),
                ),
                Divider(
                  color: Colors.blueGrey,
                )
              ]),
            );
          }),
    );
  }
}
