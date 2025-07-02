import 'achievement.dart';

class FinanceSnapshot {
  // basic numbers ­– replace with your own fields
  final double income;
  final double expense;
  final int streak;

  // e-pet
  final int petLevel;
  final double petXpProgress; // 0-1
  final int petSatiety;
  final int petHappiness;
  final int petEnergy;
  final int petHealth;

  // extras
  final List<Achievement> achievements;
  final String lastSyncTime;

  const FinanceSnapshot({
    this.income = 0,
    this.expense = 0,
    this.streak = 0,
    this.petLevel = 1,
    this.petXpProgress = 0,
    this.petSatiety = 100,
    this.petHappiness = 100,
    this.petEnergy = 100,
    this.petHealth = 100,
    this.achievements = const [],
    this.lastSyncTime = 'never',
  });
}
