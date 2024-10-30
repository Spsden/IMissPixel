import 'dart:math';

class RandomNameGenerator {
  static final List<String> adjectives = [
    "adorable", "brave", "clever", "daring", "eager",
    "fancy", "graceful", "happy", "jolly", "kind"
  ];

  static final List<String> animals = [
    "aardvark", "bear", "cat", "dog", "elephant",
    "fox", "giraffe", "hamster", "iguana", "jaguar"
  ];

  static final Random _random = Random();

  static String generateRandomName() {
    final adjective = adjectives[_random.nextInt(adjectives.length)];
    final animal = animals[_random.nextInt(animals.length)];
    return "${capitalize(adjective)} ${capitalize(animal)}";
  }

  static String capitalize(String s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '';
}