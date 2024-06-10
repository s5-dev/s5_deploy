import 'package:dcli/dcli.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart';
import 'package:s5_deploy/definitons/logging.dart';
import 'package:s5/s5.dart';

void initS5(String nodeURL, String dbPath, String logPath) async {
  final nowInMilliseconds = DateTime.now().millisecondsSinceEpoch;
  final lastEightDigits = nowInMilliseconds
      .toString()
      .substring(nowInMilliseconds.toString().length - 8);
  Hive.init(dbPath);
  final s5 = await S5.create(
      logger: FileLogger(file: join(logPath, 'log-$lastEightDigits.txt')));
  if (!s5.hasIdentity) {
    final seed = s5.generateSeedPhrase();
    print("");
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
      nodeURL,
    );
  }
}
