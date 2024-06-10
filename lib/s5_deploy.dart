import 'dart:io';

import 'package:args/args.dart';
import 'package:cli_spin/cli_spin.dart';
import 'package:dcli/dcli.dart';
import 'package:path/path.dart';
import 'package:s5_deploy/definitons/constants.dart';
import 'package:s5_deploy/functions/cli.dart';
import 'package:s5_deploy/functions/filesystem.dart';
import 'package:s5_deploy/functions/s5.dart';
import 'package:s5_deploy/functions/spinner.dart';
import 'package:xdg_directories/xdg_directories.dart';

void s5Deploy(List<String> args) async {
  // define paths
  final dbPath = join(configHome.path, 's5_deploy', 'db');
  final logPath = join(configHome.path, 's5_deploy', 'logs');
  await ensureDirExistence(Directory(dbPath));
  await ensureDirExistence(Directory(logPath));

  // Define arguments
  ArgParser topParser = defineArguments();

  // Process args
  ArgResults results;
  try {
    results = topParser.parse(args);
  } catch (e) {
    print(red(e.toString()));
    printUsage(topParser);
    exit(1);
  }

  // -V || --version
  var versionCheck = results['version'] as bool;
  if (versionCheck) {
    print("Version: $s5Version");
    exit(1);
  }

  // -h || --help || malformed path
  bool helpCheck = results['help'] as bool;
  if (results.rest.length != 1 || helpCheck) {
    if (!helpCheck) {
      print(red('You must pass the name of the file/directory to upload.'));
    }
    printUsage(topParser);
    exit(1);
  }

  // begin spinner
  CliSpin spinner = spinStart("Setting things up...");

  // --reset
  var resetCheck = results['reset'] as bool;
  if (resetCheck) {
    await Directory(dbPath).delete(recursive: true);
  }

  spinner.success();

  // init s5
  spinner = spinStart("Initializing S5...");
  String nodeURL = results['node'] as String;
  initS5(nodeURL, dbPath, logPath);
  spinner.success();

  exit(1);
}
