import 'package:flutter_test/flutter_test.dart';
import 'package:laylow/models/mood_option.dart';
import 'package:laylow/services/mood_music_mapping.dart';

void main() {
  group('deezerSearchTermsFor', () {
    test('returns non-empty terms for every mood at every intensity', () {
      for (final mood in moodOptions) {
        for (var intensity = 1; intensity <= 5; intensity++) {
          final terms = deezerSearchTermsFor(mood.id, intensity);
          expect(terms, isNotEmpty, reason: '${mood.id} @ $intensity');
        }
      }
    });

    test('different intensities produce different terms for the same mood', () {
      final low = deezerSearchTermsFor('happy', 1);
      final high = deezerSearchTermsFor('happy', 5);
      expect(low, isNot(equals(high)));
    });

    test('different moods at the same intensity produce different terms', () {
      final happy = deezerSearchTermsFor('happy', 3);
      final sad = deezerSearchTermsFor('sad', 3);
      expect(happy, isNot(equals(sad)));
    });

    test('clamps out-of-range intensity instead of throwing', () {
      expect(() => deezerSearchTermsFor('calm', 0), returnsNormally);
      expect(() => deezerSearchTermsFor('calm', 99), returnsNormally);
      expect(deezerSearchTermsFor('calm', 0), equals(deezerSearchTermsFor('calm', 1)));
      expect(deezerSearchTermsFor('calm', 99), equals(deezerSearchTermsFor('calm', 5)));
    });

    test('falls back to a generic term for an unrecognized mood', () {
      expect(deezerSearchTermsFor('unknown', 3), equals(['Ed Sheeran']));
    });

    test('always returns 4 terms with no duplicates, sliding across intensity', () {
      for (final mood in moodOptions) {
        final seenAcrossIntensities = <String>{};
        for (var intensity = 1; intensity <= 5; intensity++) {
          final terms = deezerSearchTermsFor(mood.id, intensity);
          expect(terms, hasLength(4), reason: '${mood.id} @ $intensity');
          expect(
            terms.toSet().length,
            4,
            reason: '${mood.id} @ $intensity should have no repeated artist',
          );
          seenAcrossIntensities.addAll(terms);
        }
        // The pool is 8 artists wide a 4-artist window slides across, so
        // every mood should surface its full pool across all 5 intensities.
        expect(seenAcrossIntensities, hasLength(8), reason: mood.id);
      }
    });

    test('the extremes of intensity are fully disjoint', () {
      final mildest = deezerSearchTermsFor('sad', 1);
      final most = deezerSearchTermsFor('sad', 5);
      expect(mildest.toSet().intersection(most.toSet()), isEmpty);
    });
  });
}
