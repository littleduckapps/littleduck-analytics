/// Little Duck's one analytics door.
///
/// Anonymous usage counting through Aptabase, with the studio's rules built
/// in: no identifiers, no free text, no amounts; an off switch the app puts in
/// Settings; debug builds send nothing.
///
/// Copyright Little Duck Interactive Pty Ltd.
library;

export 'src/analytics.dart';
export 'src/aptabase_sink.dart';
export 'src/buckets.dart';
export 'src/rules.dart';
export 'src/sink.dart';
