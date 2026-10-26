/// A stable 32-bit hash of [text] (FNV-1a): the same on every device and
/// platform, for choices every phone must make alike from public values
/// (the night's sounds, the narrator's walk and lines). Not for secrets.
///
/// The multiplication is done in 16-bit halves: in a browser numbers are
/// doubles, and a plain 32-bit by 24-bit product would lose its low bits.
int stableHash(String text) {
  var hash = 0x811c9dc5;
  for (final unit in text.codeUnits) {
    hash = _times(hash ^ unit, 0x01000193);
  }
  return hash;
}

/// [a] times [b] modulo 2^32, exact on every platform.
int _times(int a, int b) {
  final low = (a & 0xffff) * b;
  final high = ((a ~/ 0x10000) & 0xffff) * b;
  return (low + (high & 0xffff) * 0x10000) % 0x100000000;
}
