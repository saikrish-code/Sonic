import 'package:flutter/material.dart';
import '../audio/audio_recorder_service.dart';
import 'sound_classifier.dart';
import 'sound_labels.dart';

enum LiveSoundKind {
  listening,
  paused,
  permissionDenied,
  microphoneError,
  simulationMode,
  normal,
  talking,
  event,
}

/// Single derived live status shared by every dashboard card, status label,
/// and general sound alert. Exactly one state is active at a time.
class LiveSoundStatus {
  final LiveSoundKind kind;
  final String label;
  final String detail;
  final SoundCategory? category;
  final double confidence;
  final bool isAlert;

  const LiveSoundStatus._({
    required this.kind,
    required this.label,
    required this.detail,
    this.category,
    this.confidence = 0.0,
    this.isAlert = false,
  });

  factory LiveSoundStatus.listening() => const LiveSoundStatus._(
        kind: LiveSoundKind.listening,
        label: 'Listening',
        detail: 'Calibrating ambient baseline',
      );

  factory LiveSoundStatus.paused() => const LiveSoundStatus._(
        kind: LiveSoundKind.paused,
        label: 'Paused',
        detail: 'Sound monitoring is paused',
      );

  factory LiveSoundStatus.permissionDenied() => const LiveSoundStatus._(
        kind: LiveSoundKind.permissionDenied,
        label: 'Microphone Blocked',
        detail: 'Enable microphone access in settings to listen',
      );

  factory LiveSoundStatus.microphoneError() => const LiveSoundStatus._(
        kind: LiveSoundKind.microphoneError,
        label: 'Microphone Error',
        detail: 'Audio input unavailable. Check your microphone.',
      );

  factory LiveSoundStatus.simulationMode() => const LiveSoundStatus._(
        kind: LiveSoundKind.simulationMode,
        label: 'Demo Mode',
        detail: 'Simulated audio. Not real microphone input.',
      );

  factory LiveSoundStatus.normal() => const LiveSoundStatus._(
        kind: LiveSoundKind.normal,
        label: 'Normal',
        detail: 'Ambient level at calibrated baseline',
      );

  factory LiveSoundStatus.talking() => const LiveSoundStatus._(
        kind: LiveSoundKind.talking,
        label: 'Talking',
        detail: 'Sound level above ambient baseline',
      );

  factory LiveSoundStatus.event(SoundCategory category, double confidence) =>
      LiveSoundStatus._(
        kind: LiveSoundKind.event,
        label: category.label,
        detail: '${(confidence * 100).toInt()}% confidence',
        category: category,
        confidence: confidence,
        isAlert: true,
      );

  bool get showsNormal => kind == LiveSoundKind.normal;
  bool get showsTalking => kind == LiveSoundKind.talking;
  bool get showsEvent => kind == LiveSoundKind.event;
}

/// Resolves the single shared live status from microphone state, listening
/// toggle, classifier output, and smoothed decibel level.
///
/// "Talking" is a decibel-departure label (not proof of speech): when no
/// target event class qualifies, show Normal if the smoothed level sits at
/// the calibrated baseline, otherwise show Talking. Hysteresis prevents flicker.
class LiveStatusResolver {
  static const double baselineAlpha = 0.02;
  static const double talkingEnterDb = 8.0;
  static const double talkingExitDb = 4.0;

  double? baselineDb;
  double? smoothedDb;
  bool _wasTalking = false;

  LiveSoundKind? lastKind;

  LiveSoundStatus resolve({
    required MicrophoneState micState,
    required bool isListening,
    required ClassificationResult? detection,
    required double? decibels,
  }) {
    if (!isListening) {
      lastKind = LiveSoundKind.paused;
      return LiveSoundStatus.paused();
    }

    switch (micState) {
      case MicrophoneState.permissionDenied:
        lastKind = LiveSoundKind.permissionDenied;
        return LiveSoundStatus.permissionDenied();
      case MicrophoneState.microphoneError:
        lastKind = LiveSoundKind.microphoneError;
        return LiveSoundStatus.microphoneError();
      case MicrophoneState.simulationMode:
        lastKind = LiveSoundKind.simulationMode;
        return LiveSoundStatus.simulationMode();
      case MicrophoneState.idle:
        lastKind = LiveSoundKind.listening;
        return LiveSoundStatus.listening();
      case MicrophoneState.paused:
        lastKind = LiveSoundKind.paused;
        return LiveSoundStatus.paused();
      case MicrophoneState.listening:
        break;
    }

    if (detection != null &&
        SoundClassifier.targetEventKeys.contains(detection.topCategoryKey) &&
        detection.confidence >= SoundClassifier.eventThreshold) {
      try {
        final cat = SoundCategories.getByKey(detection.topCategoryKey);
        lastKind = LiveSoundKind.event;
        return LiveSoundStatus.event(cat, detection.confidence);
      } catch (_) {
        lastKind = LiveSoundKind.normal;
        return LiveSoundStatus.normal();
      }
    }

    if (decibels == null) {
      lastKind = LiveSoundKind.listening;
      return LiveSoundStatus.listening();
    }

    final db = decibels;
    smoothedDb = smoothedDb == null ? db : smoothedDb! + 0.15 * (db - smoothedDb!);
    baselineDb = baselineDb == null ? smoothedDb : baselineDb! + baselineAlpha * (smoothedDb! - baselineDb!);

    final departure = smoothedDb! - baselineDb!;
    if (_wasTalking) {
      _wasTalking = departure > talkingExitDb;
    } else {
      _wasTalking = departure > talkingEnterDb;
    }

    if (_wasTalking) {
      lastKind = LiveSoundKind.talking;
      return LiveSoundStatus.talking();
    }
    lastKind = LiveSoundKind.normal;
    return LiveSoundStatus.normal();
  }

  Color iconColor(BuildContext context) {
    switch (lastKind) {
      case LiveSoundKind.event:
        return Colors.white;
      case LiveSoundKind.talking:
        return const Color(0xFF90BE6D);
      default:
        return Colors.white70;
    }
  }
}
