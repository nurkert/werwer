import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whowolf/src/net/store.dart';

/// A keychain in memory.
class _Keychain extends FlutterSecureStorage {
  _Keychain();

  final values = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values.remove(key);
}

RememberedRoom _room(int n, {DateTime? at}) => RememberedRoom(
  room: '${1000 + n}',
  hostKey: List.filled(32, n),
  roomSecret: List.filled(32, 100 + n),
  savedAt: at ?? DateTime.now(),
);

void main() {
  test('room keys are kept in the keychain only, for a few hours', () async {
    final keychain = _Keychain();
    final store = Store(keychain);
    await store.rememberRoom(_room(1));
    expect(keychain.values.keys, ['rooms'], reason: 'a secret: keychain only');
    expect((await store.rememberedRooms()).single.room, '1001');

    await store.rememberRoom(
      _room(2, at: DateTime.now().subtract(const Duration(hours: 7))),
    );
    expect(
      (await store.rememberedRooms()).map((r) => r.room),
      ['1001'],
      reason: 'older than six hours: gone',
    );
  });

  test('a removed player forgets the room; only the newest are kept', () async {
    final store = Store(_Keychain());
    for (var i = 0; i < 12; i++) {
      await store.rememberRoom(_room(i));
    }
    final kept = await store.rememberedRooms();
    expect(kept, hasLength(RememberedRoom.most));
    expect(kept.first.room, '1011');

    await store.forgetRoom(List.filled(32, 11));
    expect(
      (await store.rememberedRooms()).map((r) => r.room),
      isNot(contains('1011')),
    );
  });

  test('broken records are ignored', () async {
    final keychain = _Keychain()..values['rooms'] = '[{"room":"1"},7,"x"]';
    expect(await Store(keychain).rememberedRooms(), isEmpty);
  });
}
