// lib/widgets/epet_widget.dart
import 'package:flutter/material.dart';
// Optional animation helpers – comment out until you’re ready
// import 'package:lottie/lottie.dart';          // pubspec: lottie:^2.7.0
// import 'package:flame/game.dart';             // pubspec: flame:^1.17.0

/// Visual states for the e‑pet.
/// Add more (e.g. sleepy, dirty) as your game grows.
enum PetState { perfect, hungry, tired, sick }

extension PetStateHelper on PetState {
  /* --------------------------------------------------------------
   * 1.  Map four integer metrics (0‑100) into a PetState
   * ------------------------------------------------------------ */
  static PetState fromStatus({
    required int satiety,
    required int happiness,
    required int energy,
    required int health,
  }) {
    // (1) Perfect – every metric is maxed out
    if (satiety == 100 &&
        happiness == 100 &&
        energy == 100 &&
        health == 100) {
      return PetState.perfect;
    }

    // (2) Sick takes priority when health is really low
    if (health < 60) return PetState.sick;

    // (3) Otherwise, whichever metric is the lowest decides
    if (satiety < energy) return PetState.hungry;
    return PetState.tired;
  }

  /* --------------------------------------------------------------
   * 2.  Static PNG file for each state
   * ------------------------------------------------------------ */
  String get assetPath {
    switch (this) {
      case PetState.perfect:
        return 'assets/pet_states/perfect.png';
      case PetState.hungry:
        return 'assets/pet_states/hungry.png';
      case PetState.tired:
        return 'assets/pet_states/tired.png';
      case PetState.sick:
        return 'assets/pet_states/sick.png';
    }
  }

  /* --------------------------------------------------------------
   * 3.  (Optional) Lottie JSON file for each state
   * ------------------------------------------------------------ */
  String get lottiePath {
    switch (this) {
      case PetState.perfect:
        return 'assets/pet_ani/perfect.json';
      case PetState.hungry:
        return 'assets/pet_ani/hungry.json';
      case PetState.tired:
        return 'assets/pet_ani/tired.json';
      case PetState.sick:
        return 'assets/pet_ani/sick.json';
    }
  }
}

/// ----------------------------------------------------------------
/// ‼  EPetWidget  –  drop anywhere you need the sprite/animation  ‼
/// ----------------------------------------------------------------
class EPetWidget extends StatelessWidget {
  final PetState state;
  final double size;          // makes the widget reusable at any scale

  const EPetWidget({
    super.key,
    required this.state,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    /* ============================================================
     * OPTION A — simple PNG (always works, zero extra packages)
     * ========================================================== */
    return Image.asset(
      state.assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      // Safety‑net in case the asset is missing
      errorBuilder: (_, __, ___) => _placeholder(state),
    );

    /* ============================================================
     * OPTION B — Lottie animation (comment A, uncomment B)
     *            1) add lottie: ^2.7.0 to pubspec
     *            2) ensure JSON files exist at state.lottiePath
     * ==========================================================
    return Lottie.asset(
      state.lottiePath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _placeholder(state),
    );
    */

    /* ============================================================
     * OPTION C — Flame sprite (advanced) – pseudo‑code stub
     * ==========================================================
    return SizedBox(
      width: size,
      height: size,
      child: GameWidget(
        game: MyPetGame(spritePath: state.assetPath),
      ),
    );
    */
  }

  /// Grey box fallback so the UI does not blow up if an asset is missing.
  Widget _placeholder(PetState state) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      state.name.toUpperCase(),
      style: const TextStyle(fontSize: 10),
      textAlign: TextAlign.center,
    ),
  );
}



