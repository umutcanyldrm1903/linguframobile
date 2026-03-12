class ApiResponseParser {
  const ApiResponseParser._();

  static Map<String, dynamic>? tryMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final inner = payload['data'];
      if (inner is Map) {
        return Map<String, dynamic>.from(inner);
      }
      return Map<String, dynamic>.from(payload);
    }

    if (payload is Map) {
      final inner = payload['data'];
      if (inner is Map) {
        return Map<String, dynamic>.from(inner);
      }
      return Map<String, dynamic>.from(payload);
    }

    return null;
  }

  static List<Map<String, dynamic>>? tryList(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final inner = payload['data'];
      if (inner is List) {
        return inner
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
      }
    }

    if (payload is Map) {
      final inner = payload['data'];
      if (inner is List) {
        return inner
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
      }
    }

    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }

    return null;
  }

  static Map<String, dynamic> requireMap(
    dynamic payload, {
    String? context,
  }) {
    final data = tryMap(payload);
    if (data != null) {
      return data;
    }
    throw FormatException(_message(context));
  }

  static List<Map<String, dynamic>> requireList(
    dynamic payload, {
    String? context,
  }) {
    final data = tryList(payload);
    if (data != null) {
      return data;
    }
    throw FormatException(_message(context));
  }

  static String _message(String? context) {
    if (context == null || context.trim().isEmpty) {
      return 'Unexpected API response';
    }
    return 'Unexpected API response: ${context.trim()}';
  }
}
