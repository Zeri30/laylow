import 'package:flutter_test/flutter_test.dart';
import 'package:laylow/services/youtube_service.dart';

void main() {
  group('youtubeSearchQuery', () {
    test('combines title and artist into a search query', () {
      expect(
        youtubeSearchQuery('Love The Way You Lie', 'Eminem'),
        'Love The Way You Lie Eminem',
      );
    });
  });
}
