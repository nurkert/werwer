/// The room on the relay server, opened at most once and only when it is
/// needed: right away only when the host wants it always or has no Wi-Fi
/// (nobody could reach the room otherwise), else on [open] (the host shows
/// the QR code). Until then the server learns nothing of this room.
class OnDemandRelay<T extends Object> {
  OnDemandRelay(this._connect);

  final Future<T?> Function() _connect;
  T? _relay;
  Future<T?>? _opening;

  /// Whether the room opens on the server right away.
  static bool rightAway({required bool always, required bool offline}) =>
      always || offline;

  /// The open relay room, if any.
  T? get relay => _relay;

  /// Opens the relay room unless it is open; taps that come while it opens
  /// wait for the same attempt instead of opening a second room. A failed
  /// attempt may be tried again.
  Future<T?> open() async {
    final open = _relay;
    if (open != null) return open;
    final relay = await (_opening ??= _connect());
    _opening = null;
    return _relay = relay;
  }
}
