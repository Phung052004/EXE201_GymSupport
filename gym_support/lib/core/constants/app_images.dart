/// Network image URLs (Pexels CDN — no API key needed for direct links)
/// Local asset fallbacks kept in assets/images/ for offline use
class AppImages {
  AppImages._();

  // Hero backgrounds
  static const gymHero =
      'https://images.pexels.com/photos/1552249/pexels-photo-1552249.jpeg?auto=compress&cs=tinysrgb&w=800';
  static const workoutBanner =
      'https://images.pexels.com/photos/841130/pexels-photo-841130.jpeg?auto=compress&cs=tinysrgb&w=600';
  static const aiBanner =
      'https://images.pexels.com/photos/8436587/pexels-photo-8436587.jpeg?auto=compress&cs=tinysrgb&w=600';

  // Muscle group images
  static const muscleChest =
      'https://images.pexels.com/photos/3837781/pexels-photo-3837781.jpeg?auto=compress&cs=tinysrgb&w=400';
  static const muscleBack =
      'https://images.pexels.com/photos/4162487/pexels-photo-4162487.jpeg?auto=compress&cs=tinysrgb&w=400';
  static const muscleLegs =
      'https://images.pexels.com/photos/4397833/pexels-photo-4397833.jpeg?auto=compress&cs=tinysrgb&w=400';
  static const muscleShoulders =
      'https://images.pexels.com/photos/4164766/pexels-photo-4164766.jpeg?auto=compress&cs=tinysrgb&w=400';
  static const muscleArms =
      'https://images.pexels.com/photos/3757954/pexels-photo-3757954.jpeg?auto=compress&cs=tinysrgb&w=400';
  static const muscleAbs =
      'https://images.pexels.com/photos/4162534/pexels-photo-4162534.jpeg?auto=compress&cs=tinysrgb&w=400';

  // Local fallbacks
  static const gymHeroLocal = 'assets/images/gym_hero.jpg';
  static const workoutBannerLocal = 'assets/images/workout_banner.jpg';

  static String muscleUrl(String muscle) {
    final m = muscle.toLowerCase();
    if (m.contains('ngực') || m.contains('chest')) return muscleChest;
    if (m.contains('chân') || m.contains('leg') || m.contains('quad') || m.contains('hamstring')) return muscleLegs;
    if (m.contains('lưng') || m.contains('back') || m.contains('lat')) return muscleBack;
    if (m.contains('vai') || m.contains('shoulder')) return muscleShoulders;
    if (m.contains('tay') || m.contains('arm') || m.contains('bicep') || m.contains('tricep')) return muscleArms;
    if (m.contains('bụng') || m.contains('abs') || m.contains('core')) return muscleAbs;
    return workoutBanner;
  }
}
