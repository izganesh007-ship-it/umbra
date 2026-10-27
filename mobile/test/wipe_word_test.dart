// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:umbra/wipe_word.dart';

void main() {
  test('matches the wipe word however it is typed', () {
    expect(isWipeWord('xÃ³a', 'xÃ³a'), isTrue);
    expect(isWipeWord('xoa', 'xÃ³a'), isTrue);
    expect(isWipeWord('xoaÌ', 'xÃ³a'), isTrue); // a + combining acute
    expect(isWipeWord(' XÃ“A ', 'xoa'), isTrue);
    expect(isWipeWord('lÃ¶schen', 'lÃ¶schen'), isTrue);
    expect(isWipeWord('SIL', 'sil'), isTrue);
    expect(isWipeWord('ÑÑ‚ÐµÑ€ÐµÑ‚ÑŒ', 'ÑÑ‚ÐµÑ€ÐµÑ‚ÑŒ'), isTrue);
    expect(isWipeWord('æŠ¹æŽ‰', 'æŠ¹æŽ‰'), isTrue);
    expect(isWipeWord('wipe', 'ÑÑ‚ÐµÑ€ÐµÑ‚ÑŒ'), isTrue);
    expect(isWipeWord('Ù¾Ø§Ùƒ', 'Ù¾Ø§Ú©'), isTrue); // arabic kaf for persian
    expect(isWipeWord('Ø§ÙÙ…Ø³ÙŽØ­', 'Ø§Ù…Ø³Ø­'), isTrue); // with vowel marks
    expect(isWipeWord('Ø¥Ù…Ø³Ø­', 'Ø§Ù…Ø³Ø­'), isTrue); // hamza under the alef
  });

  test('rejects anything else', () {
    expect(isWipeWord('xo', 'xÃ³a'), isFalse);
    expect(isWipeWord('', 'xÃ³a'), isFalse);
    expect(isWipeWord(null, 'xÃ³a'), isFalse);
    expect(isWipeWord('ÑÑ‚ÐµÑ€Ñ‚Ð¸', 'ÑÑ‚ÐµÑ€ÐµÑ‚ÑŒ'), isFalse);
    expect(isWipeWord('wip', 'wipe'), isFalse);
  });
}

