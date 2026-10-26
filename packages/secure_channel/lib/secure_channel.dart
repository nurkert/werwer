/// End-to-end encryption for Whowolf connections: a Noise handshake (NN, or
/// NKpsk2 with the host key and room secret from the QR code) and encrypted,
/// padded messages afterwards. Pure Dart; works over LAN, relay and browser.
library;

export 'src/noise.dart';
