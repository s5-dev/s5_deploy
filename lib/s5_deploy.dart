import 'dart:io';

import 'package:args/args.dart';
import 'package:cli_spin/cli_spin.dart';
import 'package:dcli/dcli.dart';
import 'package:lib5/node.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:s5/s5.dart';
import 'package:s5_deploy/definitons/constants.dart';
import 'package:s5_deploy/functions/cli.dart';
import 'package:s5_deploy/functions/filesystem.dart';
import 'package:s5_deploy/functions/s5.dart';
import 'package:s5_deploy/functions/spinner.dart';
import 'package:xdg_directories/xdg_directories.dart';

final String configPath = join(configHome.path, 's5_deploy');
final String dbPath = join(configPath, 'db');
final String logPath = join(configPath, 'logs');

void s5Deploy(List<String> args) async {
  // define paths

  await (Directory(dbPath)).create(recursive: true);
  await (Directory(logPath)).create(recursive: true);

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
    exit(0);
  }

  // -h || --help || malformed path
  bool helpCheck = results['help'] as bool;
  if (results.rest.length != 1 || helpCheck) {
    if (!helpCheck) {
      print(red('You must pass the name of the file/directory to upload.'));
    }
    printUsage(topParser);
    exit(2);
  }

  // begin spinner
  CliSpin spinner = spinStart("Setting things up...");

  // --reset
  bool resetCheck = results['reset'] as bool;
  if (resetCheck && Directory(configPath).listSync().isNotEmpty) {
    await Directory(configPath).delete(recursive: true);
    await (Directory(dbPath)).create(recursive: true);
    await (Directory(logPath)).create(recursive: true);
  }

  spinner.success();

  // init s5
  spinner = spinStart("Initializing S5...");
  String nodeURL = results['node'] as String;
  late S5 s5;
  try {
    s5 = await initS5(nodeURL, dbPath, logPath, (results['seed'] as String?));
  } catch (e) {
    spinner.fail();
    print(red(e.toString()));
  }

  spinner.success();

  // scan directory
  spinner = spinStart("Scanning ${results.arguments.first}");
  if (!(Directory(results.arguments.first).existsSync())) {
    spinner.fail();
    print(red("Directory doesn't exist, scan failed."));
    exit(1);
  }
  ProcessedDirectory procDir = processDirectory(
      Directory(results.arguments.first), results.arguments.first);

  if (procDir == ProcessedDirectory()) {
    spinner.fail();
    print(red("Directory empty, scan failed."));
  } else {
    spinner.success();
  }

  // now upload to S5 & set registry
  spinner = spinStart("Uploading to S5...");
  S5NodeAPIWithIdentity nodewIden = (s5.api as S5NodeAPIWithIdentity);
  final CID staticCID = await uploadDirectory(
      procDir.fileStreams, procDir.lengths, nodewIden, "",
      lookupMimeType: lookupMimeType);

  if (staticCID.hash.toString() != "") {
    spinner.success();
  } else {
    spinner.fail();
  }

  // Then give the CIDs to the users
  if ((results['static'] as bool)) {
    print(green("Sucsesss!"));
    print("${green("Static Link:")} s5://${staticCID.toBase58()}");
  } else {
    // get resolver link
    spinner = spinStart("Updating resolver link...");
    final resolverCID = await updateResolver(s5, results.arguments.first,
        staticCID, spinner, (results['dataKey'] as String?));

    // Then a little url manipulation
    final nodeURI = Uri.parse(nodeURL);
    final finalURI =
        nodeURI.replace(host: "${resolverCID.toBase32()}.${nodeURI.host}");

    // now print out to the user
    print(green("Sucsesss!"));
    print("${green("Static Link:")} s5://${staticCID.toBase58()}");
    print("${green("Resolver Link:")} s5://${resolverCID.toBase58()}");
    print("${green("Resolver Link Subdomain:")} ${finalURI.toString()}");
    print(
        "NOTE: This subdomain may not work depending on wildcard permissions");
    var confirmed =
        confirm('Would you like DNSLink instructions?', defaultValue: true);
    if (confirmed) {
      print(
          "Please put this ${magenta('TXT')} record on your domain: ${green('dnslink=/s5/${resolverCID.toBase58()}')}");
    }
  }

  // And it's over folks
  exit(0);
}
