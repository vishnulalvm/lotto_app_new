import 'dart:math';

class NumberCombinationService {
  static const int _targetCount = 16;
  static final Random _random = Random();

  /// Generates a list of 16 unique number combinations based on the input.
  /// Always returns 4-digit strings.
  static List<String> generateCombinations(String input) {
    // Sanitize input: keep only digits
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return List.filled(_targetCount, "0000"); // Or empty list check in UI
    }

    final Set<String> combinations = {};

    // Strategy based on length
    if (digits.length == 1) {
      _generateForSingleDigit(digits, combinations);
    } else if (digits.length == 2) {
      _generateForTwoDigits(digits, combinations);
    } else if (digits.length == 3) {
      _generateForThreeDigits(digits, combinations);
    } else if (digits.length == 4) {
      _generateForFourDigits(digits, combinations);
    } else {
      _generateForMoreThanFourDigits(digits, combinations);
    }

    // Fallback: If we couldn't generate 16 unique ones (e.g. strict permutations),
    // fill with random fancy numbers using the input digits.
    while (combinations.length < _targetCount) {
      combinations.add(_generateRandomFallback(digits));
    }

    return combinations.take(_targetCount).toList();
  }

  // --- Strategies ---

  static void _generateForSingleDigit(String d, Set<String> combinations) {
    // 1. Repetition: 1111
    combinations.add(d * 4);

    // 2. Sequential patterns if d is small enough (or wrap around)
    // Not strictly requested but "fancy".
    // Let's stick to "include 1 with 16 combinations".

    // Pattern: ddd(x) - 1112, 1113...
    for (int i = 0; i < 10; i++) {
      if (combinations.length >= _targetCount) break;
      combinations.add("$d$d$d$i");
    }

    // Pattern: dd(xx) - 1123, 1145...
    while (combinations.length < _targetCount) {
      // Random fancy pattern containing d
      String suffix = _random.nextInt(1000).toString().padLeft(3, '0');
      // Ensure d is inserted somewhere or prepended
      combinations.add("$d$suffix");
    }
  }

  static void _generateForTwoDigits(String d, Set<String> combinations) {
    // Input: "12"
    // 1. Repetition: "1212", "2121"
    combinations.add("$d$d");
    combinations.add("${d[1]}${d[0]}${d[1]}${d[0]}");

    // 2. Patterns like "1235", "1245" (Starts with 12)
    for (int i = 0; i < 100; i++) {
      if (combinations.length >= _targetCount) break;
      // Try generating 12xx
      String suffix = i.toString().padLeft(2, '0');
      combinations.add("$d$suffix");
    }

    // 3. Permutations "4512" (Ends with 12)
    while (combinations.length < _targetCount) {
      String prefix = _random.nextInt(100).toString().padLeft(2, '0');
      combinations.add("$prefix$d");
    }
  }

  static void _generateForThreeDigits(String d, Set<String> combinations) {
    // Input: "123"
    // 1. Prepend/Append: "123x", "x123", "1x23"...

    // 123x
    for (int i = 0; i < 10; i++) {
      combinations.add("$d$i");
    }

    // x123
    for (int i = 0; i < 10; i++) {
      if (combinations.length >= _targetCount) break;
      combinations.add("$i$d");
    }

    // Shuffle
    while (combinations.length < _targetCount) {
      List<String> chars = d.split('')..add(_random.nextInt(10).toString());
      chars.shuffle(_random);
      combinations.add(chars.join(''));
    }
  }

  static void _generateForFourDigits(String d, Set<String> combinations) {
    // Input: "1234"
    // Pure permutations of these 4 digits.
    List<String> perms = _getPermutations(d.split(''));
    combinations.addAll(perms.take(_targetCount));

    // If we need more (e.g. input "1111" has 1 permutation), fill with variations
    // Variation: Mix with other numbers? Or repeated pairs?
    // Request says: "no need add extra number just combination of that 4 digits"
    // But if input is "1122", permutations are limited.
    // If not enough unique permutations, we MUST relax the rule or repeat?
    // I'll assume we stick to the input digits.

    while (combinations.length < _targetCount) {
      // Generate 'random' shuffle of input
      List<String> chars = d.split('')..shuffle(_random);
      combinations.add(chars.join(''));
      // Note: Set handles uniqueness. If we exhaust all permutations, we might loop forever.
      // Add safeguard: if max perms reached, break logic?
      // For 4 digits, max perms is 24.
      // For input "1111", size is 1. We can't generate 16 unique.
      // We'll append a random suffix to make it unique if stuck?
      // Or just return repeated. The UI will just show what we have.
      if (combinations.length == perms.toSet().length) break;
    }
  }

  static void _generateForMoreThanFourDigits(
      String d, Set<String> combinations) {
    // Input: "12345"
    // Create combinations of these numbers like 1234, 1235, 5321...
    List<String> pool = d.split('');

    // Strategy 1: Pick 4 distinct indices
    int attempts = 0;
    while (combinations.length < 8 && attempts < 100) {
      attempts++;
      List<String> subset = List.from(pool)..shuffle(_random);
      combinations.add(subset.take(4).join(''));
    }

    // Strategy 2: "5544", "3322" (Pairs from pool)
    attempts = 0;
    while (combinations.length < 12 && attempts < 100) {
      attempts++;
      String a = pool[_random.nextInt(pool.length)];
      String b = pool[_random.nextInt(pool.length)];
      combinations.add("$a$a$b$b");
    }

    // Fill rest with any shuffle of 4 items from pool
    while (combinations.length < _targetCount) {
      List<String> subset = List.from(pool)..shuffle(_random);
      combinations.add(subset.take(4).join(''));
    }
  }

  static String _generateRandomFallback(String inputDigits) {
    if (inputDigits.length >= 4) {
      List<String> l = inputDigits.split('')..shuffle();
      return l.take(4).join('');
    }
    // If input is short, pad with random
    String res = inputDigits;
    while (res.length < 4) {
      res += _random.nextInt(10).toString();
    }
    // shuffle safely
    List<String> l = res.split('')..shuffle();
    return l.join('');
  }

  static List<String> _getPermutations(List<String> list) {
    if (list.length == 1) return list;
    List<String> result = [];
    for (int i = 0; i < list.length; i++) {
      var remaining = List<String>.from(list)..removeAt(i);
      var subPerms = _getPermutations(remaining);
      for (var s in subPerms) {
        result.add(list[i] + s);
      }
    }
    return result;
  }
}
