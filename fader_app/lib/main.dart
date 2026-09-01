// Default Flutter entrypoint for the integrated FADER application.
// The implementation lives in second_main.dart to preserve the project's
// original file history, while `flutter run` now launches the current build.
import 'second_main.dart' as integrated;
export 'second_main.dart' show FaderApp;

void main() => integrated.main();
