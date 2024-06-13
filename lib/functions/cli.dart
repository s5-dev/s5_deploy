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
      help: 'Gets the version number of package');

  // -h || --help
  topParser.addFlag('help',
      negatable: false,
      abbr: 'h',
      defaultsTo: false,
      help: 'Print help dialoge.');

  // --reset
  topParser.addFlag('reset',
      negatable: false,
      defaultsTo: false,
      help: 'Resets local node ${red("BE CAREFUL")}');

  // --static
  topParser.addFlag('static',
      negatable: false, defaultsTo: false, help: 'Skips resolver deploy');

  // -s || --server
  topParser.addOption('node',
      abbr: 'n',
      defaultsTo: 'https://s5.ninja',
      help: 'Which S5 node to deploy to');

  // -S || --seed
  topParser.addOption(
    'seed',
    abbr: 'S',
    help: 'Set seed to recover DNS Link Entry',
  );

  // -d || --dataKey
  topParser.addOption('dataKey',
      abbr: 'd',
      defaultsTo: null,
      help: 'Set the datakey of the upload, defaults to target directory');

  return topParser;
}

void printUsage(ArgParser parser) {
  print(('Usage:'));
  print(('s5_deploy ./file/or/folder'));
  print((parser.usage));
}
