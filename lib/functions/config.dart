import 'dart:convert';
import 'dart:io';

import 'package:cli_spin/cli_spin.dart';
import 'package:dcli/dcli.dart';
import 'package:path/path.dart';
import 'package:s5_deploy/s5_deploy.dart';

class DeployConfig {
  String seed;
  List<String> dataKeys;

  DeployConfig({required this.seed, required this.dataKeys});

  factory DeployConfig.fromJson(Map<String, dynamic> json) {
    return DeployConfig(
      seed: json['seed'] as String,
      dataKeys: List<String>.from(json['dataKeys'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seed': seed,
      'dataKeys': dataKeys,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  static DeployConfig fromJsonString(String jsonString) {
    return DeployConfig.fromJson(jsonDecode(jsonString));
  }
}

DeployConfig? getConfig(CliSpin spinner) {
  if (File(join(configPath, "config.json")).existsSync()) {
    try {
      return DeployConfig.fromJsonString(
          File(join(configPath, "config.json")).readAsStringSync());
    } catch (e) {
      spinner.fail();
      print(e.toString());
      print(red("Failed to read config file from XDG home"));
      exit(1);
    }
  }
  return null;
}

void setConfig(DeployConfig conf) {
  File configFile = File(join(configPath, "config.json"));
  configFile.writeAsStringSync(conf.toJsonString());
}
