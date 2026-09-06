import '../chart/note.dart';
import '../rhythm/judgment.dart';

class NoteRuntime {
  NoteRuntime(this.note);

  final ChartNote note;
  bool hit = false;
  bool missed = false;
  bool holdActive = false;
  Judgment? judgment;
  double? hitDeltaMs;

  bool get resolved => hit || missed;
}
