/// Seals the room for the successor of a host (see `GameHost.custody`).
/// `game_host` stays free of cryptography: the app passes the libsodium
/// implementation from `secure_channel`, tests a stand-in.
abstract interface class RoomSealer {
  /// A fresh random key (32 bytes) from a secure source.
  List<int> newKey();

  /// Seals [room] with [key], bound to [epoch]: nobody without the key can
  /// read or change it.
  Future<String> seal(String room, List<int> key, {required int epoch});

  /// Opens what [seal] made; `null` if the key, the epoch or the data is
  /// wrong.
  Future<String?> open(String sealed, List<int> key, {required int epoch});
}

/// What a host needs to let another player take over: the sealer, and how
/// to turn its snapshot into the whole room (the app adds the room keys).
class CustodyConfig {
  /// Creates the configuration.
  const CustodyConfig({required this.sealer, required this.room});

  /// Seals and opens rooms.
  final RoomSealer sealer;

  /// The whole room for a successor, from the host's snapshot. It holds
  /// every secret of the game; it only ever leaves the host sealed.
  final String Function(String snapshot) room;
}
