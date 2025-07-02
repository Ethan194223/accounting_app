// lib/Profile_page.dart
//
// Shows the signed‑in Firebase user’s profile instead of dummy data.
// Uses FirebaseAuth.userChanges() so the UI refreshes immediately after
// sign‑up, photo‑update or logout.
//

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../widgets/epet_widget.dart';
import '../models/finance_snapshot.dart';
import '../models/achievement.dart';

import '../services/finance_service.dart'; // Ensure this import is correct

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme     = Theme.of(context);
    final textTheme = theme.textTheme;

    // Financial & pet snapshot still come from your local service.
    final FinanceSnapshot f = FinanceService.snapshot;

    // ──────────────────────────────────────────────────────────────
    // StreamBuilder will rebuild the whole page whenever
    // FirebaseAuth emits a change (sign‑in, profile update, sign‑out).
    // ──────────────────────────────────────────────────────────────
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snap) {
        // While waiting for Firebase we can show a spinner.
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If there is *no* user, we are logged‑out – hand back to AuthWrapper.
        if (!snap.hasData) return const SizedBox.shrink();

        final user = snap.data!;
        final displayName =
        (user.displayName?.isNotEmpty == true) ? user.displayName! : 'User';
        final email       = user.email ?? '—';
        final avatarUrl   = user.photoURL ??
            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}';

        // Derive e‑pet sprite from your four pet metrics.
        final petState = PetStateHelper.fromStatus(
          satiety:  f.petSatiety,
          happiness:f.petHappiness,
          energy:   f.petEnergy,
          health:   f.petHealth,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Life Accounting'),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // 1. Header card -------------------------------------------------
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(avatarUrl),
                  ),
                  title: Text(displayName, style: textTheme.titleMedium),
                  subtitle: Text(email),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                ),
              ),
              const SizedBox(height: 16),

              // 2. E‑pet snapshot ---------------------------------------------
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      EPetWidget(state: petState, size: 96),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Level ${f.petLevel}',
                                style: textTheme.titleMedium),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: f.petXpProgress,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: [
                                _statusChip('Satiety',    f.petSatiety, theme),
                                _statusChip('Happiness', f.petHappiness, theme),
                                _statusChip('Energy',    f.petEnergy, theme),
                                _statusChip('Health',    f.petHealth, theme),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Financial overview -----------------------------------------
              _financialOverviewCard(f, theme, textTheme),
              const SizedBox(height: 16),

              // 4. Achievements -----------------------------------------------
              _achievementsCard(f.achievements, theme),
              const SizedBox(height: 16),

              // 5. Data, security & session -----------------------------------
              _dataSecurityCard(context, f, theme),
              const SizedBox(height: 24),

              // 6. About footer -----------------------------------------------
              const AboutListTile(
                icon: Icon(Icons.info_outline),
                applicationName: 'Life Accounting',
                applicationVersion: '1.0.0',
                dense: true,
              ),
            ],
          ),
        );
      },
    );
  }

  // ────────────────── helpers (unchanged) ──────────────────────────────────
  Widget _statusChip(String label, int value, ThemeData theme) => Chip(
    label: Text('$label $value'),
    backgroundColor: theme.colorScheme.surfaceContainerHighest,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  Widget _financialOverviewCard(
      FinanceSnapshot f, ThemeData theme, TextTheme textTheme) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Financial Overview', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text('Income:\n\$${f.income.toStringAsFixed(0)}',
                      style: textTheme.bodyMedium),
                ),
                Expanded(
                  child: Text('Expense:\n\$${f.expense.toStringAsFixed(0)}',
                      style: textTheme.bodyMedium),
                ),
                _streakBadge(f.streak, theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _streakBadge(int days, ThemeData theme) => Container(
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Column(
      children: [
        Text('Streak', style: theme.textTheme.labelMedium),
        Text('$days days',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _achievementsCard(List<Achievement> list, ThemeData theme) {
    // Return an empty container if the list is empty to avoid rendering an empty card
    if (list.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Achievements', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisExtent: 54,
                crossAxisSpacing: 12,
              ),
              itemCount: list.length,
              itemBuilder: (_, i) => Tooltip(
                message: list[i].title,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: FaIcon(
                      list[i].icon ?? FontAwesomeIcons.star,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dataSecurityCard(
      BuildContext ctx, FinanceSnapshot f, ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.cloud_done_outlined),
            title: const Text('Last backup'),
            subtitle: Text(f.lastSyncTime),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => FinanceService.syncNow(),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Export CSV'),
            onTap: () => FinanceService.exportCsv(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (!ctx.mounted) return;
              // After sign‑out AuthWrapper will drop you back to LoginPage.
              Navigator.popUntil(ctx, (r) => r.isFirst);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined,
                color: Colors.redAccent),
            title: const Text('Delete account',
                style: TextStyle(color: Colors.redAccent)),
            onTap: () => _confirmDelete(ctx),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This action is irreversible. All your data will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              FinanceService.deleteAccountAndData();
            },
            child:
            const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}



