import 'package:dcli/dcli.dart';
import 'package:hive/hive.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';
import 'package:s5_deploy/definitons/logging.dart';
import 'package:s5/s5.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:s5_deploy/functions/filesystem.dart';

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
    await s5.recoverIdentityFromSeedPhrase(seed);
    await s5.registerOnNewStorageService(
      nodeURL,
    );
  }
  return s5;
}

// Future<CID> uploadDirectory(
//   Map<String, Stream<List<int>>> fileStreams,
//   Map<String, int> lengths,
//   String name, {
//   List<String>? tryFiles,
//   Map<String, String>? errorPages,
//   required Function lookupMimeType,
// }) async {
//   final params = {
//     'name': name,
//   };

//   if (tryFiles != null) {
//     params['tryfiles'] = json.encode(tryFiles);
//   }
//   if (errorPages != null) {
//     params['errorpages'] = json.encode(errorPages);
//   }

//   final uc = storageServiceConfigs.first;

//   var uri = uc.getAPIUrl('/s5/upload/directory').replace(
//         queryParameters: params,
//       );

//   var request = http.MultipartRequest("POST", uri);

//   request.headers.addAll(uc.headers);

//   for (final filename in fileStreams.keys) {
//     var stream = http.ByteStream(fileStreams[filename]!);

//     final mimeType = lookupMimeType(filename);

//     var multipartFile = http.MultipartFile(
//       filename,
//       stream,
//       lengths[filename]!,
//       filename: filename,
//       contentType: mimeType == null ? null : MediaType.parse(mimeType),
//     );

//     request.files.add(multipartFile);
//   }

//   final response = await HttpClient.send(request);

//   if (response.statusCode != 200) {
//     throw Exception('HTTP ${response.statusCode}');
//   }

//   final res = await response.stream.transform(utf8.decoder).join();

//   final resData = json.decode(res);

//   if (resData['cid'] == null) throw Exception('Directory upload failed');
//   return CID.decode(resData['cid']);
// }
