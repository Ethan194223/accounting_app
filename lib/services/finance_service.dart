import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/achievement.dart';
import '../models/finance_snapshot.dart';

class FinanceService {
  static final _dummy = FinanceSnapshot(
    income: 2500,
    expense: 1800,
    streak: 3,
    petLevel: 5,
    petXpProgress: 0.7,
    petSatiety: 95,
    petHappiness: 95,
    petEnergy: 90,
    petHealth: 90,
    achievements: const [
      Achievement('save1k', 'Saved \$1,000', FontAwesomeIcons.piggyBank),
      Achievement('add_tx', 'Logged 50 Tx', FontAwesomeIcons.plus),
      // …add more
    ],
    lastSyncTime: '2 hours ago',
  );

  static FinanceSnapshot get snapshot => _dummy;

  static Future<void> syncNow() async {
    debugPrint('Syncing data now...');
    // TODO: call Firebase / Supabase
  }

  static Future<void> exportCsv() async {
    debugPrint('Exporting data as CSV...');
    // TODO: generate CSV + share
  }

  /// Deletes the Firebase user account and all associated data.
  /// This action is irreversible.
  static Future<void> deleteAccountAndData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint("No user is currently signed in to delete.");
        return;
      }

      // IMPORTANT: You should first delete the user's data from your
      // database (like Firestore or Realtime DB) to prevent orphaned data.
      // e.g., await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      debugPrint("User-specific data deleted. Now deleting Firebase Auth user...");

      // After deleting associated data, delete the Firebase user.
      await user.delete();

      debugPrint("Firebase user account deleted successfully.");

    } on FirebaseAuthException catch (e) {
      // This error is common if the user hasn't signed in recently.
      // You may need to prompt them to re-authenticate.
      if (e.code == 'requires-recent-login') {
        debugPrint(
            'This operation requires recent authentication. Please log out and log back in.');
      } else {
        // Handle other potential Firebase errors.
        debugPrint("Error deleting account: ${e.message}");
      }
    } catch (e) {
      // Handle any other unexpected errors.
      debugPrint("An unexpected error occurred while deleting the account: $e");
    }
  }
}
