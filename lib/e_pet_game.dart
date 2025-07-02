import 'dart:math'; // Needed for random selection
import 'package:flame/components.dart';
import 'package:flame/game.dart';

class EPetGame extends FlameGame {
  // Initial values provided when creating the game.
  final double initialSatiety;
  final double initialHappiness;

  late SpriteAnimationComponent pet;
  late SpriteComponent background;

  // Animations for idle, hungry, and cry states.
  late SpriteAnimation idleAnimation;
  late SpriteAnimation hungryAnimation;
  late SpriteAnimation cryAnimation;

  // Current state variables.
  double _satiety = 100;
  double _happiness = 100;

  bool _isShowingHungry = false;
  bool _isCrying = false;

  EPetGame({required this.initialSatiety, required this.initialHappiness});

  double get satiety => _satiety;
  double get happiness => _happiness;

  /// Updates satiety and then refreshes the pet's animation.
  void updateSatiety(double value) {
    _satiety = value;
    _updatePetAnimation();
  }

  /// Updates happiness and then refreshes the pet's animation.
  void updateHappiness(double value) {
    _happiness = value;
    _updatePetAnimation();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Load the background.
    background = SpriteComponent()
      ..sprite = await loadSprite('bg_room.png')
      ..size = size;
    add(background);

    // Load all animations.
    await _loadAnimations();

    // Create the pet component with the idle animation by default.
    // Note: pet.size is set to the same value for all states.
    pet = SpriteAnimationComponent()
      ..animation = idleAnimation
      ..size = Vector2(512, 512) * 0.6  // Adjust multiplier as needed.
      ..anchor = Anchor.center
      ..position = size / 2;
    add(pet);

    // Set initial state values.
    _satiety = initialSatiety;
    _happiness = initialHappiness;
    _updatePetAnimation();
  }

  Future<void> _loadAnimations() async {
    // Load idle animation. Ensure this image is a 4-frame horizontal sprite sheet (each frame 512x512).
    idleAnimation = await loadSpriteAnimation(
      'e_pet_idle_sheet_horizontal.png',
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.2,
        textureSize: Vector2(512, 512),
      ),
    );

    // Load hungry animation. Ensure this image is formatted similarly.
    hungryAnimation = await loadSpriteAnimation(
      'e_pet_hungry.png',
      SpriteAnimationData.sequenced(
        amount: 2,
        stepTime: 0.2,
        textureSize: Vector2(512, 512),
      ),
    );

    // Load cry animation. For best results, the image should have the same layout:
    // a 4-frame horizontal sprite sheet, each frame 512x512.
    cryAnimation = await loadSpriteAnimation(
      'e_pet_cry.png',
      SpriteAnimationData.sequenced(
        amount: 2,
        stepTime: 0.2,
        textureSize: Vector2(512, 512),
      ),
    );
  }

  /// Selects the pet's animation based on current satiety and happiness.
  /// - If both are below 50, randomly choose between cry and hungry.
  /// - Else if only happiness is below 50, show cry.
  /// - Else if only satiety is below 50, show hungry.
  /// - Otherwise, show idle.
  void _updatePetAnimation() {
    if (_satiety < 50 && _happiness < 50) {
      if (Random().nextBool()) {
        pet.animation = cryAnimation;
        _isCrying = true;
        _isShowingHungry = false;
      } else {
        pet.animation = hungryAnimation;
        _isShowingHungry = true;
        _isCrying = false;
      }
    } else if (_happiness < 50) {
      pet.animation = cryAnimation;
      _isCrying = true;
      _isShowingHungry = false;
    } else if (_satiety < 50) {
      pet.animation = hungryAnimation;
      _isShowingHungry = true;
      _isCrying = false;
    } else {
      pet.animation = idleAnimation;
      _isCrying = false;
      _isShowingHungry = false;
    }
  }
}











