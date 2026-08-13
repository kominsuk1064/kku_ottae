import 'dart:convert';
import 'dart:io';

final class _ContentRule {
  const _ContentRule(this.description, this.pattern);

  final String description;
  final RegExp pattern;
}

final _contentRules = [
  _ContentRule(
    'non-placeholder TAGO key',
    RegExp(
      r'''TAGO_KEY\s*=\s*(?!YOUR_TAGO_KEY\b|CHANGE_ME\b|\.{3}(?=\s)|\$\{|\$env:|\$)[^\s"',]+''',
    ),
  ),
  _ContentRule(
    'Google API key-shaped value',
    RegExp(r'AIza[0-9A-Za-z_-]{20,}'),
  ),
  _ContentRule(
    'private key header',
    RegExp(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
  ),
];

const _forbiddenFiles = {
  'android/app/google-services.json',
  'android/key.properties',
  'ios/Runner/GoogleService-Info.plist',
};

Future<void> main() async {
  final gitResult = await Process.run('git', [
    'ls-files',
    '--cached',
    '--others',
    '--exclude-standard',
  ], runInShell: Platform.isWindows);
  if (gitResult.exitCode != 0) {
    stderr.writeln('Unable to read tracked files from Git.');
    exitCode = gitResult.exitCode;
    return;
  }

  final trackedPaths = const LineSplitter()
      .convert(gitResult.stdout as String)
      .where((path) => path.isNotEmpty)
      .toList(growable: false);
  final violations = <String>{};
  var scannedFileCount = 0;

  for (final path in trackedPaths) {
    final file = File(path);
    if (!file.existsSync()) {
      continue;
    }
    scannedFileCount += 1;

    final normalizedPath = path.replaceAll('\\', '/');
    final pathViolation = _pathViolation(normalizedPath);
    if (pathViolation != null) {
      violations.add('$normalizedPath: $pathViolation');
    }

    final bytes = await file.readAsBytes();
    if (bytes.contains(0)) {
      continue;
    }

    final contents = utf8.decode(bytes, allowMalformed: true);
    for (final rule in _contentRules) {
      if (rule.pattern.hasMatch(contents)) {
        violations.add('$normalizedPath: ${rule.description}');
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln('Repository hygiene check failed:');
    for (final violation in violations.toList()..sort()) {
      stderr.writeln('- $violation');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Repository hygiene check passed ($scannedFileCount repository files).',
  );
}

String? _pathViolation(String path) {
  final segments = path.split('/');
  final fileName = segments.last;

  if (path.startsWith('.vscode/')) {
    return 'local VS Code configuration is tracked';
  }
  if (segments.contains('node_modules')) {
    return 'generated node_modules dependency is tracked';
  }
  if (_forbiddenFiles.contains(path)) {
    return 'platform credential file is tracked';
  }
  if ((fileName == '.env' || fileName.startsWith('.env.')) &&
      fileName != '.env.example') {
    return 'environment file is tracked';
  }
  if (fileName.endsWith('.jks') || fileName.endsWith('.keystore')) {
    return 'signing keystore is tracked';
  }

  return null;
}
