import 'dart:convert';

import '../navigator/prism_page.dart';

class EncodedRouteSegment {
  EncodedRouteSegment(this.name, this.arguments);

  final String name;
  final Map<String, Object?> arguments;
}

String encodeLocation(List<PrismPage> pages) {
  if (pages.isEmpty) return '/';
  final segments = pages.map(_encodeSegment).join('/');
  return '/$segments';
}

List<EncodedRouteSegment> decodeUri(Uri uri) {
  // Support both direct-path URLs:
  //   /home/profile/details
  // and hash-based URLs:
  //   http://localhost:1234/#/home/profile/details
  //
  // In the latter case, [uri.pathSegments] is empty and the actual segments
  // live inside [uri.fragment].
  var segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

  // If path is empty, check fragment (hash routing)
  if (segments.isEmpty && uri.fragment.isNotEmpty) {
    // Fragment can be: "/home/profile" or "home/profile" or "#/home/profile"
    var fragment = uri.fragment;

    // Remove leading '#' if present
    if (fragment.startsWith('#')) {
      fragment = fragment.substring(1);
    }

    // Ensure it starts with '/'
    if (!fragment.startsWith('/')) {
      fragment = '/$fragment';
    }

    // Parse fragment as URI to extract path segments
    try {
      final fragUri = Uri.parse(fragment);
      segments = fragUri.pathSegments.where((s) => s.isNotEmpty).toList();
    } on Object {
      // If parsing fails, try splitting by '/'
      segments = fragment.split('/').where((s) => s.isNotEmpty).toList();
    }
  }

  segments =
      segments
          .map((segment) => segment.trim())
          .where((segment) => segment.isNotEmpty && segment != '#')
          .toList();

  if (segments.isEmpty) return const [];
  return segments.map(_decodeSegment).toList();
}

String _encodeSegment(PrismPage page) {
  if (page.arguments.isEmpty) return page.name;
  final encodedArgs = base64Url.encode(utf8.encode(jsonEncode(page.arguments)));
  return '${page.name}~$encodedArgs';
}

EncodedRouteSegment _decodeSegment(String raw) {
  final parts = raw.split('~');
  final name = parts.first;
  if (parts.length == 1) {
    return EncodedRouteSegment(name, const <String, Object?>{});
  }
  final encodedArgs = parts.sublist(1).join('~');
  try {
    final decoded = utf8.decode(base64Url.decode(encodedArgs));
    final map = jsonDecode(decoded);
    if (map is Map<String, dynamic>) {
      return EncodedRouteSegment(name, map);
    }
  } on Object {
    // Fall through to empty arguments on parse errors.
  }
  return EncodedRouteSegment(name, const <String, Object?>{});
}
