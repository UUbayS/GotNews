import 'package:flutter_test/flutter_test.dart';
import 'package:newsscroll/services/api_client.dart';

void main() {
  group('ApiClient', () {
    test('default baseUrl is localhost', () {
      expect(ApiClient.baseUrl, contains('localhost'));
    });

    test('getAvatarUrl returns empty for null', () {
      expect(ApiClient.getAvatarUrl(null), '');
    });

    test('getAvatarUrl returns empty for empty string', () {
      expect(ApiClient.getAvatarUrl(''), '');
    });

    test('getAvatarUrl returns full URL for http links', () {
      const url = 'https://example.com/image.jpg';
      expect(ApiClient.getAvatarUrl(url), url);
    });

    test('getAvatarUrl prefixes relative URLs', () {
      const url = '/uploads/avatars/test.jpg';
      expect(ApiClient.getAvatarUrl(url), contains(url));
    });
  });
}
