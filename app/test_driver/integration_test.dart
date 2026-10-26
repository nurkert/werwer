// Runs integration tests on a device through `flutter drive`, which can
// reach wirelessly paired iPhones (`flutter test` cannot):
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/host_return_test.dart -d <device> --publish-port
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
