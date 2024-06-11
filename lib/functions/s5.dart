import 'dart:io';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:dcli/dcli.dart';
import 'package:hive/hive.dart';
import 'package:http_parser/http_parser.dart';
import 'package:lib5/constants.dart';
import 'package:lib5/identity.dart';
import 'package:lib5/node.dart';
import 'package:lib5/registry.dart';
import 'package:path/path.dart';
import 'package:s5_deploy/definitons/logging.dart';
import 'package:s5/s5.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bip39/bip39.dart' as bip39;

Future<S5> initS5(String nodeURL, String dbPath, String logPath) async {
  final nowInMilliseconds = DateTime.now().millisecondsSinceEpoch;
  final lastEightDigits = nowInMilliseconds
      .toString()
      .substring(nowInMilliseconds.toString().length - 8);
  Hive.init(dbPath);
  final S5 s5 = await S5.create(
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
    Box<dynamic> box = await Hive.openBox('s5_deploy');
    box.put('seed', seed);
    await s5.recoverIdentityFromSeedPhrase(seed);
    await s5.registerOnNewStorageService(
      nodeURL,
    );
  }
  return s5;
}

Future<CID> uploadDirectory(
  Map<String, Stream<List<int>>> fileStreams,
  Map<String, int> lengths,
  S5NodeAPIWithIdentity nodewIdentity,
  String name, {
  List<String>? tryFiles,
  Map<String, String>? errorPages,
  required Function lookupMimeType,
}) async {
  final params = {
    'name': name,
  };

  if (tryFiles != null) {
    params['tryfiles'] = json.encode(tryFiles);
  }
  if (errorPages != null) {
    params['errorpages'] = json.encode(errorPages);
  }

  final uc = nodewIdentity.accountConfigs.values.first;

  var uri = uc.getAPIUrl('/s5/upload/directory').replace(
        queryParameters: params,
      );

  var request = http.MultipartRequest("POST", uri);

  request.headers.addAll(uc.headers);

  for (final filename in fileStreams.keys) {
    var stream = http.ByteStream(fileStreams[filename]!);

    final mimeType = lookupMimeType(filename);

    var multipartFile = http.MultipartFile(
      filename,
      stream,
      lengths[filename]!,
      filename: filename,
      contentType: mimeType == null ? null : MediaType.parse(mimeType),
    );

    request.files.add(multipartFile);
  }

  final response = await request.send();

  if (response.statusCode != 200) {
    throw Exception('HTTP ${response.statusCode}');
  }

  final res = await response.stream.transform(utf8.decoder).join();

  final resData = json.decode(res);

  if (resData['cid'] == null) throw Exception('Directory upload failed');
  return CID.decode(resData['cid']);
}

Future<CID> updateResolver(S5 s5, String dir, CID staticCID) async {
  Box<dynamic> box = await Hive.openBox('s5_deploy');
  String seed = box.get('seed');
  String dataKey = "";
  try {
    dataKey = box.get('datakey');
  } catch (_) {
    dataKey = 'project-${Directory(dir).absolute.path}';
  }

  final resolverSeed = s5.api.crypto.hashBlake3Sync(
    Uint8List.fromList(
      validatePhrase(seed, crypto: s5.api.crypto) + utf8.encode(dataKey),
    ),
  );

  final s5User = await s5.api.crypto.newKeyPairEd25519(seed: resolverSeed);

  SignedRegistryEntry? existing;

  try {
    final res = await s5.api.registryGet(s5User.publicKey);
    existing = res;
    if (existing != null) {
      print(
        'Revision ${existing.revision} -> ${existing.revision + 1}',
      );
    }
  } catch (e) {
    existing = null;

    print('Revision 1');
  }

  final sre = await signRegistryEntry(
    kp: s5User,
    data: staticCID.toRegistryEntry(),
    revision: (existing?.revision ?? -1) + 1,
    crypto: s5.api.crypto,
  );

  await s5.api.registrySet(sre);

  final resolverCID = CID(
      cidTypeResolver,
      Multihash(
        Uint8List.fromList(
          s5User.publicKey,
        ),
      ));
  return resolverCID;
}
