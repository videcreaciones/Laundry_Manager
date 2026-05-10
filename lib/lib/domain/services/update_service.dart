library;

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

const String _kGithubOwner    = 'videcreaciones';
const String _kGithubRepo     = 'Laundry_Manager';
const String _kCurrentVersion = '1.3.0';

class ReleaseInfo {
  final String version;
  final String body;
  final String downloadUrl;

  const ReleaseInfo({
    required this.version,
    required this.body,
    required this.downloadUrl,
  });
}

final class UpdateService {
  const UpdateService();

  Future<ReleaseInfo?> checkForUpdate() async {
    try {
      final url = Uri.parse(
        'https://api.github.com/repos/$_kGithubOwner/$_kGithubRepo/releases/latest',
      );
      final response = await http.get(url, headers: {
        'Accept': 'application/vnd.github.v3+json',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data    = jsonDecode(response.body) as Map<String, dynamic>;
      final latest  = (data['tag_name'] as String).replaceAll('v', '');
      final body    = data['body'] as String? ?? '';
      final assets  = data['assets'] as List<dynamic>;

      final apkAsset = assets.firstWhere(
        (a) => (a['name'] as String).endsWith('.apk'),
        orElse: () => null,
      );
      if (apkAsset == null) return null;

      final downloadUrl = apkAsset['browser_download_url'] as String;

      return _isNewer(latest, _kCurrentVersion)
          ? ReleaseInfo(version: latest, body: body, downloadUrl: downloadUrl)
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> downloadAndInstall(
    String downloadUrl, {
    required void Function(double progress) onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final apkPath = '${tempDir.path}/laundry_manager_update.apk';
      final file    = File(apkPath);

      final client   = http.Client();
      final request  = http.Request('GET', Uri.parse(downloadUrl));
      final response = await client.send(request);
      final total    = response.contentLength ?? 0;
      var received   = 0;

      final sink = file.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress(received / total);
      }
      await sink.close();
      client.close();

      final result = await OpenFile.open(apkPath);
      return result.type == ResultType.done;
    } catch (_) {
      return false;
    }
  }

  bool _isNewer(String latest, String current) {
    final l = latest.split('.').map(int.tryParse).toList();
    final c = current.split('.').map(int.tryParse).toList();
    for (var i = 0; i < 3; i++) {
      final lv = (i < l.length ? l[i] : 0) ?? 0;
      final cv = (i < c.length ? c[i] : 0) ?? 0;
      if (lv > cv) return true;
      if (lv < cv) return false;
    }
    return false;
  }
}
