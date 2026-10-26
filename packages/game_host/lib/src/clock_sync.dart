import 'dart:math';

/// How this device's clock stands to the host's, from timed pings (the NTP
/// idea): a ping leaves at `sent`, the host answers with its time `hostAt`,
/// the pong arrives at `received`. If the way there and back took equally
/// long, the host's clock is `hostAt - (sent + received) / 2` ahead.
///
/// Wi-Fi delays vary, and a slow sample is an unequal one, so only the
/// fastest sample of the recent ones counts.
class ClockSync {
  /// How many recent samples are kept.
  static const window = 8;

  /// Samples slower than this are useless (and probably stale).
  static const maxRoundTrip = 2000;

  final _samples = <({int roundTrip, int offset})>[];

  /// Records one ping's answer (all times in milliseconds).
  void add({required int sent, required int hostAt, required int received}) {
    final roundTrip = received - sent;
    if (roundTrip < 0 || roundTrip > maxRoundTrip) return;
    _samples.add((
      roundTrip: roundTrip,
      offset: hostAt - (sent + received) ~/ 2,
    ));
    if (_samples.length > window) _samples.removeAt(0);
  }

  ({int roundTrip, int offset})? get _best => _samples.isEmpty
      ? null
      : _samples.reduce((a, b) => a.roundTrip <= b.roundTrip ? a : b);

  /// Milliseconds the host's clock is ahead of this one, or `null` before
  /// the first answer.
  int? get offset => _best?.offset;

  /// At most this far off (half the fastest round trip).
  int? get uncertainty {
    final best = _best;
    return best == null ? null : max(1, best.roundTrip ~/ 2);
  }

  /// This device's time for the host's [hostMs].
  int? toLocal(int hostMs) {
    final offset = this.offset;
    return offset == null ? null : hostMs - offset;
  }

  /// Forgets everything (another host, another clock).
  void reset() => _samples.clear();
}
