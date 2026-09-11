import 'package:flutter/material.dart';
import '../theme/sonic_colors.dart';

enum AlertUrgency {
  critical, // Smoke, Fire, Danger (Continuous long intense pulse)
  urgent,   // Siren, Baby Crying, Glass Breaking (Rapid pulses)
  warning,  // Doorbell, Knock, Phone (Crisp multi-tap)
  info,     // Appliance beep, footsteps, etc. (Soft double-tap)
}

/// Metadata and definition for a sound classification category.
class SoundCategory {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final AlertUrgency urgency;
  final double defaultThreshold;
  final List<int> vibrationPattern; // in milliseconds [wait, vibrate, wait, vibrate...]
  final String description;

  const SoundCategory({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.urgency,
    this.defaultThreshold = 0.70,
    required this.vibrationPattern,
    required this.description,
  });
}

class SoundCategories {
  static const List<SoundCategory> all = [
    SoundCategory(
      key: 'smoke_alarm',
      label: 'Smoke Alarm',
      icon: Icons.local_fire_department,
      color: SonicColors.alertRed,
      urgency: AlertUrgency.critical,
      defaultThreshold: 0.65,
      vibrationPattern: [0, 800, 200, 800],
      description: 'Persistent high-pitched alarm signal indicating smoke.',
    ),
    SoundCategory(
      key: 'fire_alarm',
      label: 'Fire Alarm',
      icon: Icons.campaign,
      color: SonicColors.alertRed,
      urgency: AlertUrgency.critical,
      defaultThreshold: 0.65,
      vibrationPattern: [0, 900, 150, 900],
      description: 'Emergency building evacuation or fire alarm horn.',
    ),
    SoundCategory(
      key: 'siren',
      label: 'Emergency Siren',
      icon: Icons.emergency,
      color: SonicColors.alertOrange,
      urgency: AlertUrgency.urgent,
      defaultThreshold: 0.70,
      vibrationPattern: [0, 600, 150, 600, 150, 600],
      description: 'Police, ambulance, or emergency vehicle wailing siren.',
    ),
    SoundCategory(
      key: 'baby_crying',
      label: 'Baby Crying',
      icon: Icons.child_care,
      color: Color(0xFFFF6B6B),
      urgency: AlertUrgency.urgent,
      defaultThreshold: 0.72,
      vibrationPattern: [0, 250, 100, 250, 100, 250, 100, 250],
      description: 'Infant crying or distress vocalization.',
    ),
    SoundCategory(
      key: 'glass_breaking',
      label: 'Glass Breaking',
      icon: Icons.broken_image,
      color: Color(0xFFF72585),
      urgency: AlertUrgency.urgent,
      defaultThreshold: 0.75,
      vibrationPattern: [0, 400, 80, 200, 80, 400],
      description: 'Window or glass shatter impact.',
    ),
    SoundCategory(
      key: 'doorbell',
      label: 'Doorbell',
      icon: Icons.doorbell,
      color: SonicColors.alertAmber,
      urgency: AlertUrgency.warning,
      defaultThreshold: 0.70,
      vibrationPattern: [0, 150, 100, 150, 100, 150],
      description: 'Front door musical chime or electronic buzzer.',
    ),
    SoundCategory(
      key: 'door_knock',
      label: 'Door Knock',
      icon: Icons.front_hand,
      color: Color(0xFFFF9E00),
      urgency: AlertUrgency.warning,
      defaultThreshold: 0.70,
      vibrationPattern: [0, 120, 80, 120, 80, 120],
      description: 'Firm knocking on wooden or composite door.',
    ),
    SoundCategory(
      key: 'dog_bark',
      label: 'Dog Bark',
      icon: Icons.pets,
      color: Color(0xFFE07A5F),
      urgency: AlertUrgency.warning,
      defaultThreshold: 0.72,
      vibrationPattern: [0, 300, 100, 300],
      description: 'Canine vocalization or aggressive barking.',
    ),
    SoundCategory(
      key: 'phone_ringing',
      label: 'Phone Ringing',
      icon: Icons.ring_volume,
      color: SonicColors.alertBlue,
      urgency: AlertUrgency.warning,
      defaultThreshold: 0.70,
      vibrationPattern: [0, 350, 150, 350],
      description: 'Landline or smartphone incoming call ringtone.',
    ),
    SoundCategory(
      key: 'name_calling',
      label: 'Voice / Name Shout',
      icon: Icons.record_voice_over,
      color: SonicColors.primary,
      urgency: AlertUrgency.warning,
      defaultThreshold: 0.70,
      vibrationPattern: [0, 200, 100, 200, 100, 400],
      description: 'Nearby person calling out or shouting attention.',
    ),
    SoundCategory(
      key: 'car_horn',
      label: 'Car Horn',
      icon: Icons.directions_car,
      color: SonicColors.alertOrange,
      urgency: AlertUrgency.warning,
      defaultThreshold: 0.75,
      vibrationPattern: [0, 500, 100, 500],
      description: 'Vehicle warning horn blast.',
    ),
    SoundCategory(
      key: 'appliance_beep',
      label: 'Appliance Beep',
      icon: Icons.microwave,
      color: Color(0xFF4CC9F0),
      urgency: AlertUrgency.info,
      defaultThreshold: 0.70,
      vibrationPattern: [0, 200, 150, 200],
      description: 'Microwave, oven, or washing machine completion beep.',
    ),
    SoundCategory(
      key: 'water_running',
      label: 'Water Running',
      icon: Icons.water_drop,
      color: Color(0xFF00B4D8),
      urgency: AlertUrgency.info,
      defaultThreshold: 0.75,
      vibrationPattern: [0, 100, 100, 100, 100, 100],
      description: 'Faucet left running or overflowing sink.',
    ),
    SoundCategory(
      key: 'thunderstorm',
      label: 'Thunder',
      icon: Icons.thunderstorm,
      color: Color(0xFF7209B7),
      urgency: AlertUrgency.info,
      defaultThreshold: 0.78,
      vibrationPattern: [0, 500, 200, 700],
      description: 'Low-frequency rumble from lightning storm.',
    ),
    SoundCategory(
      key: 'alarm_clock',
      label: 'Alarm Clock',
      icon: Icons.alarm,
      color: SonicColors.alertAmber,
      urgency: AlertUrgency.warning,
      defaultThreshold: 0.70,
      vibrationPattern: [0, 200, 80, 200, 80, 200, 80, 200],
      description: 'Morning wake-up alarm or timer.',
    ),
    SoundCategory(
      key: 'cat_meow',
      label: 'Cat Meow',
      icon: Icons.cruelty_free,
      color: Color(0xFFF39A59),
      urgency: AlertUrgency.info,
      defaultThreshold: 0.75,
      vibrationPattern: [0, 180, 100, 180],
      description: 'Feline vocalization or persistent meowing.',
    ),
    SoundCategory(
      key: 'footsteps',
      label: 'Footsteps',
      icon: Icons.directions_walk,
      color: Color(0xFF8D99AE),
      urgency: AlertUrgency.info,
      defaultThreshold: 0.80,
      vibrationPattern: [0, 100, 150, 100],
      description: 'Approaching pacing or walking sounds nearby.',
    ),
    SoundCategory(
      key: 'coughing',
      label: 'Coughing',
      icon: Icons.sick,
      color: Color(0xFF90BE6D),
      urgency: AlertUrgency.info,
      defaultThreshold: 0.75,
      vibrationPattern: [0, 150, 80, 150],
      description: 'Sudden human coughing or choking sound.',
    ),
    SoundCategory(
      key: 'snoring',
      label: 'Snoring',
      icon: Icons.bedtime,
      color: Color(0xFF577590),
      urgency: AlertUrgency.info,
      defaultThreshold: 0.75,
      vibrationPattern: [0, 400, 300, 400],
      description: 'Rhythmic sleep breathing or heavy snoring.',
    ),
    SoundCategory(
      key: 'danger_explosion',
      label: 'Danger / Explosion',
      icon: Icons.warning_amber,
      color: SonicColors.alertRed,
      urgency: AlertUrgency.critical,
      defaultThreshold: 0.70,
      vibrationPattern: [0, 1000, 100, 1000],
      description: 'Sudden loud concussive blast or collision.',
    ),
  ];

  static SoundCategory getByKey(String key) {
    return all.firstWhere(
      (c) => c.key == key,
      orElse: () => all.first,
    );
  }

  /// Default vibration pattern for personalized taught sounds
  static const List<int> personalSoundVibrationPattern = [0, 200, 100, 400];
}
