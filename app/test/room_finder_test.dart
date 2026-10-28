import 'package:flutter_test/flutter_test.dart';
import 'package:whowolf/src/net/discovery.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a room closed here leaves every running search at once', () {
    final finder = RoomFinder();
    addTearDown(finder.dispose);
    var told = 0;
    finder.addListener(() => told++);

    RoomFinder.closed(List.filled(32, 7));
    expect(told, 1);

    // Closing it again changes nothing.
    RoomFinder.closed(List.filled(32, 7));
    expect(told, 1);
  });
}
