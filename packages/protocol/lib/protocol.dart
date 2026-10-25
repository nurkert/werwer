/// Versioned JSON messages between a Whowolf host and its players: intents
/// in, filtered views out. Everything received is parsed strictly.
library;

export 'src/messages.dart';
export 'src/reader.dart' show ProtocolError;
export 'src/view_codec.dart';
