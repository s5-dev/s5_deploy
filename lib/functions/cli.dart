import 'package:args/args.dart';
import 'package:dcli/dcli.dart';

ArgParser defineArguments() {
  // Define args
  var topParser = ArgParser();

  // -V || --version
  topParser.addFlag('version',
      abbr: 'V',
      defaultsTo: false,
      negatable: false,
      help: 'Gets the version number of package.');

  // -h || --help
  topParser.addFlag('help',
      abbr: 'h',
      defaultsTo: false,
      negatable: false,
      help: 'Print help dialoge.');

  // --reset
  topParser.addFlag('reset',
      defaultsTo: false,
      negatable: false,
      help: 'Resets local node ${red("BE CAREFUL")}');

  // -s || --server
  topParser.addOption('node',
      abbr: 'n',
      defaultsTo: 'https://s5.ninja',
      help: 'Which S5 node to deploy to.');

  return topParser;
}

void printUsage(ArgParser parser) {
  print(('Usage:'));
  print(('s5_deploy ./file/or/folder'));
  print((parser.usage));
}
