import 'package:godotclassreference/bloc/monospace_font_bloc.dart';
import 'package:godotclassreference/bloc/tap_event_bloc.dart';
import 'package:godotclassreference/bloc/theme_bloc.dart';
import 'package:godotclassreference/constants/stored_values.dart';

export 'xml_load_bloc.dart';
export 'search_bloc.dart';
export 'monospace_font_bloc.dart';
export 'theme_bloc.dart';
export 'tap_event_bloc.dart';
export 'tap_event_arg.dart';

class AllBlocs {
  MonospaceFontBloc monospaceFontBloc =
      MonospaceFontBloc(storedValues.isMonospaced);
  ThemeChangeBloc themeChangeBloc = ThemeChangeBloc(storedValues.isDarkTheme);
  TapEventBloc tapEventBloc = TapEventBloc();

  static final AllBlocs _singleton = AllBlocs._internal();

  factory AllBlocs() {
    return _singleton;
  }

  AllBlocs._internal();
  // late them
}

final AllBlocs blocs = AllBlocs();
