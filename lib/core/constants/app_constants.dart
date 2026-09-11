/// Application-wide constants for Sonic
class AppConstants {
  // Audio configuration
  static const int sampleRate = 16000;              // 16 kHz mono
  static const double windowDurationSeconds = 1.0;  // 1-second rolling analysis window
  static const int windowSizeSamples = 16000;       // 16,000 samples per window
  static const int fftSize = 512;                   // Power-of-2 FFT length
  static const int hopSize = 256;                   // 16 ms hop (50% overlap)
  static const int melBins = 64;                    // 64 triangular mel filter banks
  static const double minFrequencyHz = 50.0;
  static const double maxFrequencyHz = 8000.0;

  // ML & Embeddings
  static const int embeddingDimension = 128;        // 128-dim embedding vector
  static const double defaultSimilarityThreshold = 0.85; // Cosine similarity cutoff
  static const double minSensitivityThreshold = 0.50;
  static const double maxSensitivityThreshold = 0.98;

  // Alert System & Debounce
  static const int debounceDurationSeconds = 10;    // 10s debounce per sound
  static const int maxConsecutiveThumbsDown = 3;    // Auto-raise threshold on 3 thumbs-down
  static const double thresholdAdjustmentStep = 0.04;

  // Teach Sound Requirements
  static const int minSamplesToTeach = 2;
  static const int maxSamplesToTeach = 5;
  static const int sampleRecordingDurationSeconds = 3;

  // Storage Keys
  static const String keyOnboardingCompleted = 'sonic_onboarding_completed';
  static const String keyBackgroundListening = 'sonic_background_listening';
  static const String keyFlashScreenOnAlert = 'sonic_flash_screen_alert';
}
