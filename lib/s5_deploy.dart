import 'dart:io';

import 'package:args/args.dart';
import 'package:dcli/dcli.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart';
import 'package:s5/s5.dart';
import 'package:s5_deploy/definitons/constants.dart';
import 'package:s5_deploy/functions/filesystem.dart';
import 'package:s5_deploy/definitons/logging.dart';
import 'package:xdg_directories/xdg_directories.dart';

void main(List<String> args) async {
  // define paths
  final dbPath = join(configHome.path, 's5_deploy', 'db');
  final logPath = join(configHome.path, 's5_deploy', 'logs');
  await ensureDirExistence(Directory(dbPath));
  await ensureDirExistence(Directory(logPath));

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

  // Process args
  var results = topParser.parse(args);

  // -V || --version
  var versionCheck = results['version'] as bool;
  if (versionCheck) {
    print("Version: $s5Version");
    exit(1);
  }

  // -h || --help || malformed path
  var helpCheck = results['help'] as bool;
  if (results.rest.length != 1 || helpCheck) {
    if (!helpCheck) {
      print(red('You must pass the name of the file/directory to upload.'));
    }
    print(green('Usage:'));
    print(green('s5_deploy ./file/or/folder'));
    print(green(topParser.usage));
    exit(1);
  }

  // --reset
  var resetCheck = results['reset'] as bool;
  if (resetCheck) {
    await Directory(dbPath).delete(recursive: true);
  }

  // init s5
  final nowInMilliseconds = DateTime.now().millisecondsSinceEpoch;
  final lastEightDigits = nowInMilliseconds
      .toString()
      .substring(nowInMilliseconds.toString().length - 8);
  Hive.init(dbPath);
  final s5 = await S5.create(
      logger: FileLogger(file: join(logPath, 'log-$lastEightDigits.txt')));
  if (!s5.hasIdentity) {
    final seed = s5.generateSeedPhrase();
    print(
        "This is your ${green("seed")}. If you want to keep updating this registry entry in the future you ${green("MUST")} have this seed");
    print(green(seed));
    var confirmed = confirm('Have you written this down:', defaultValue: true);
    if (!confirmed) {
      print(
          "No like I'm ${red("serious")}, write this down. But to each their own.");
    }
    await s5.recoverIdentityFromSeedPhrase(seed);
    await s5.registerOnNewStorageService(
      'http://s5.ninja',
      inviteCode: 'TODO',
    );
  }
  exit(1);
}
