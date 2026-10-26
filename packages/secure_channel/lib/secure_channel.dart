/// End-to-end encryption for Whowolf connections, built from libsodium:
/// crypto_kx for the keys, the room secret from the QR code bound in with a
/// keyed BLAKE2b hash, and crypto_secretstream for padded messages
/// afterwards. Works natively and in the browser (sodium.js).
library;

export 'src/channel.dart';
export 'src/custody.dart';
