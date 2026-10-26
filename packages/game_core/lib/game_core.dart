/// Whowolf game rules: a pure, deterministic state machine.
///
/// `apply(state, action)` returns the next state plus narrator events;
/// `viewFor(state, player)` filters what one player may know.
library;

export 'src/actions.dart';
export 'src/events.dart';
export 'src/model.dart';
export 'src/role.dart';
export 'src/rules.dart';
export 'src/settings.dart';
export 'src/view.dart';
export 'src/violation.dart';
