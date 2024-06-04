import 'dart:io';

import 'package:args/args.dart';
import 'package:dcli/dcli.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart';
import 'package:s5/s5.dart';
import 'package:s5_deploy/constants.dart';
import 'package:xdg_directories/xdg_directories.dart';

void main(List<String> args) async {
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

  // Process args
  var results = topParser.parse(args);

  // Print version
  var versionCheck = results['version'] as bool;
  if (versionCheck) {
    print("Version: $s5Version");
    exit(1);
  }

  // Check for malformed path OR help flag
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

  // init s5
  Hive.init(join(configHome.path, 's5_deploy', 'data'));
  final s5 = await S5.create();
  if (!s5.hasIdentity) {
    final seed = s5.generateSeedPhrase();
    print(
        "This is your seed. If you want to keep updating this registry entry in the future you MUST have this seed");
    print(seed);
    var confirmed = confirm('Have you written this down:', defaultValue: true);
    if (!confirmed) {
      print("No like I'm serious, write this down. But to each their own.");
    }
    await s5.recoverIdentityFromSeedPhrase(seed);
    await s5.registerOnNewStorageService(
      'http://10.0.0.16:5050',
      inviteCode: 'TODO',
    );
  }
  exit(1);
}
