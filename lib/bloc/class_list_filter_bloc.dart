import 'dart:async';

enum FilterType { Node2D, Node3D, NodeControl, NodeOther, NonNode }

class FilterOption {
  final FilterType type;
  final bool value;

  FilterOption(this.type, this.value);
}

class ClassListFilterBloc {
  final _filterStateController = StreamController<FilterOption>();
  StreamSink<FilterOption> get _inArgs => _filterStateController.sink;
  Stream<FilterOption> get argStream => _filterStateController.stream;

  final _filterEventController = StreamController<FilterOption>();
  Sink<FilterOption> get argSink => _filterEventController.sink;

  ClassListFilterBloc() {
    _filterEventController.stream.listen(_onAdd);
  }

  void _onAdd(FilterOption data) {
    _inArgs.add(data);
  }

  void dispose() {
    _filterEventController.close();
    _filterStateController.close();
  }
}
