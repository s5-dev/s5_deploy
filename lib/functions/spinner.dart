import 'package:cli_spin/cli_spin.dart';

CliSpin spinStart(String text) {
  return CliSpin(
    text: text,
    spinner: CliSpinners.dots,
  ).start(); // Chaining methods
}
