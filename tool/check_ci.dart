// Tant'in post-push CI gate.
//
// `dart run tool/verify.dart` proves the tree is green LOCALLY. This proves it
// is green in GitHub Actions too — the gap that bit both S0 and S1, where a
// sprint was declared done while CI was red. After pushing, run:
//
//   dart run tool/check_ci.dart
//
// It finds the Actions run for the current HEAD commit, waits for it to finish,
// and exits 0 only if the conclusion is `success`. A sprint is NOT done until
// this prints `CI: GREEN`.
//
// Auth & rate limits: uses the public GitHub REST API. Unauthenticated calls
// are capped at 60/hour per IP — fine for one sprint check at a 30s cadence,
// but if you poll a lot (or the repo is private) set GITHUB_TOKEN in the
// environment; it is sent as a bearer token and raises the limit to 5000/hour.
// On HTTP 403 (rate limited) the script keeps polling until the window resets
// or it times out.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _pollInterval = Duration(seconds: 30);
const _timeout = Duration(minutes: 20);

Future<void> main() async {
  final sha = _run('git', ['rev-parse', 'HEAD']);
  final (owner, repo) = _parseOriginSlug(
    _run('git', ['remote', 'get-url', 'origin']),
  );
  final shortSha = sha.substring(0, 7);

  stdout
    ..writeln('═══════════════════════════════════════════════')
    ..writeln(' CI gate — $owner/$repo @ $shortSha')
    ..writeln('═══════════════════════════════════════════════');

  final deadline = DateTime.now().add(_timeout);
  while (DateTime.now().isBefore(deadline)) {
    final run = await _fetchRunForSha(owner, repo, sha);
    if (run == null) {
      stdout.writeln('· no Actions run for $shortSha yet — waiting…');
    } else {
      final status = run['status'] as String?;
      final conclusion = run['conclusion'] as String?;
      if (status != 'completed') {
        stdout.writeln('· run ${run['id']} status=$status — waiting…');
      } else {
        stdout
          ..writeln('═══════════════════════════════════════════════')
          ..writeln(' conclusion: $conclusion')
          ..writeln(' ${run['html_url']}')
          ..writeln('═══════════════════════════════════════════════');
        if (conclusion == 'success') {
          stdout.writeln('CI: GREEN ✅');
          exit(0);
        }
        stdout.writeln(
          'CI: $conclusion ❌  — sprint is NOT done. Fix and re-push.',
        );
        exit(1);
      }
    }
    await Future<void>.delayed(_pollInterval);
  }
  stderr.writeln(
    'CI: TIMEOUT ⏱  — no completed run for $shortSha within '
    '${_timeout.inMinutes}m. Check Actions manually.',
  );
  exit(2);
}

Future<Map<String, dynamic>?> _fetchRunForSha(
  String owner,
  String repo,
  String sha,
) async {
  final uri = Uri.parse(
    'https://api.github.com/repos/$owner/$repo/actions/runs'
    '?head_sha=$sha&per_page=1',
  );
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    request.headers
      ..set(HttpHeaders.userAgentHeader, 'tantin-ci-gate')
      ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    final token = Platform.environment['GITHUB_TOKEN'];
    if (token != null && token.isNotEmpty) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      stderr.writeln('GitHub API ${response.statusCode}: ${body.trim()}');
      if (response.statusCode == 403 || response.statusCode == 401) {
        stderr.writeln('Set GITHUB_TOKEN if this repo is private.');
      }
      return null;
    }
    final json = jsonDecode(body) as Map<String, dynamic>;
    final runs = json['workflow_runs'] as List<dynamic>;
    if (runs.isEmpty) return null;
    return runs.first as Map<String, dynamic>;
  } finally {
    client.close();
  }
}

(String, String) _parseOriginSlug(String url) {
  // Handles https://github.com/owner/repo(.git) and git@github.com:owner/repo.
  var slug = url.trim();
  slug = slug.replaceFirst(RegExp('^https?://[^/]+/'), '');
  slug = slug.replaceFirst(RegExp('^git@[^:]+:'), '');
  slug = slug.replaceFirst(RegExp(r'\.git$'), '');
  final parts = slug.split('/');
  if (parts.length < 2) {
    stderr.writeln('Could not parse owner/repo from origin: $url');
    exit(2);
  }
  return (parts[parts.length - 2], parts[parts.length - 1]);
}

String _run(String cmd, List<String> args) {
  final result = Process.runSync(cmd, args, runInShell: true);
  if (result.exitCode != 0) {
    stderr.writeln('`$cmd ${args.join(' ')}` failed: ${result.stderr}');
    exit(2);
  }
  return (result.stdout as String).trim();
}
