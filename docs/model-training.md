# Six sound classes: data and training workflow

Sonic's phone remains the microphone and sound classifier. The wristband/wearable receives BLE alert commands and drives haptic feedback. The classifier's six event labels are door knock, coughing, baby crying, dog bark, cat meow, and footsteps. Other detected sounds remain the internal `background`/reject class; the app can show `Normal` at the calibrated mic baseline or `Talking` when the level rises above baseline. `Talking` is an activity proxy, not speech recognition.

## Why the model and runtime need both changes

The bundled TFLite model was trained from ESC-50 alone and has only a small number of independent recordings per sound. A 70% score threshold cannot by itself prevent an overconfident wrong label. The runtime now refuses event guesses from its energy-only fallback and requires a target event to exceed 70% in at least two of three overlapping windows. Microphone auto-gain and echo cancellation are disabled for live capture so the OS is less likely to suppress or reshape sounds played through another device.

The TFLite file currently checked into `assets/models/` has **not** been retrained by this change. The expanded notebook prepares and evaluates a replacement; it must meet the validation and phone-recording criteria below before replacing the shipped model.

## Data sources

Put downloaded/extracted data under `datasets/` (ignored by Git). Set `SONIC_DATA_ROOT` to a different root if needed. The notebook will use a source only when its expected folder or manifest exists.

| Source | Use in training | Split / notes |
|---|---|---|
| [ESC-50](https://github.com/karolpiczak/ESC-50) | All six target sounds plus hard background examples | Official folds; only 40 source clips per class, so it is a starting point, not real-world validation. |
| [VocalSound (16 kHz)](https://github.com/YuanGongND/vocalsound) | Coughs are `coughing`; laughter, sighs, sneezes, sniffs, and throat-clearing are hard `background` examples | Grouped by speaker ID from filenames so one speaker cannot appear in multiple splits. CC BY-SA 4.0; retain attribution and share-alike terms. |
| [CatMeows](https://zenodo.org/records/4008297) | Additional cat-meow positives | Grouped by cat ID, not random clip, to avoid memorizing the same animal. Scientific/non-commercial research use only. |
| [DIL-DCASE26-Dev](https://dcase.community/challenge2026/task-domain-agnostic-incremental-learning-for-audio-classification) | Additional door-knock, dog-bark, baby-cry, and footsteps clips, plus hard negatives (speech, piano, alarm, engine, fire, telephone ringing) | D2/D3 dev-train clips are split by file for train/validation; official dev-test clips remain test-only. CC BY 4.0. |
| [InfantCry-DBL](https://data.mendeley.com/datasets/x493z8nmwc/2) | Additional baby-cry positives, including its in-the-wild tier | Training-only in this notebook because the released clips do not provide an independent infant-level holdout manifest. Do not use its score as real-world test accuracy. CC BY 4.0; cite the dataset. |
| [UrbanSound8K](https://urbansounddataset.weebly.com/urbansound8k.html) | Dog-bark positives and diverse background negatives | Uses official folds. Non-commercial research license; access is through the dataset download form. |
| [FSD50K](https://zenodo.org/records/4060432) selected manifest | Additional target and background clips | Existing notebook loader expects the selected WAVs and manifest; review each source clip's license. Uses its provided dev/eval split. |
| MUSAN | Optional speech, music, and noise hard negatives | Large download; optional. |
| Your phone recordings | Required for real-world validation and final field evaluation | Keep train/validation recordings in `phone_train_manifest.csv` and final, untouched test sessions in `realworld_test_manifest.csv`. Never place the same session/person/room recording in both. |

Dataset archives and raw audio are not committed to the repository. Add source attribution and follow each dataset's license if you share model weights, results, or a paper.

### Data currently available in this workspace

VocalSound (21,024 WAV files), CatMeows (440 WAV files from 21 cats), and DIL-DCASE26-Dev (D2/D3 train and test recordings) are stored under the ignored `datasets/` folder. ESC-50 is available in the existing Downloads folder and can be selected with `SONIC_ESC50_PATH`. UrbanSound8K, the FSD50K selection, InfantCry-DBL, and phone-recorded development/test manifests are not present yet. The DIL set adds independent source recordings for knocks, baby cries, barks, and footsteps, but phone recordings are still required before claiming real-world accuracy; adding loaders does not itself prove a real-world improvement.

## Phone recording manifests

Create `datasets/phone_train_manifest.csv` with columns `path,app_category,recording_id,split`. Use `split=train` or `split=val`; all clips from one recording session must have the same `recording_id` and split. Labels outside the six event classes, including ordinary speech and phone-played music, map to `background`.

```csv
path,app_category,recording_id,split
phone_clips/room1_knock_01.wav,door_knock,room1_session1,train
phone_clips/room2_dog_01.wav,dog_bark,room2_session1,val
phone_clips/room1_tv_music.wav,background,room1_session2,train
```

Create a separate `datasets/realworld_test_manifest.csv` with columns `path,app_category,recording_id`. Record fresh sessions with the intended phone, in different rooms/distances/noise conditions. Include all six classes and realistic negatives. Keep this test set untouched while selecting thresholds or training.

## Training and acceptance criteria

Open `ml/sonic_six_class_robust_training.ipynb` from the repository root. The notebook keeps Flutter's fixed 20-slot output order, trains exactly the six target classes plus an internal background/reject output, and exports model metadata and dataset counts. It fails rather than silently dropping a target class.

The alert threshold is selected on validation data with a minimum of 0.70 and a target background false-alarm rate of at most 2%. The app additionally requires the same class to qualify in two of three windows. Review per-class precision/recall/F1, macro-F1, confusion matrix, false alarms per hour, and the final phone-only test results. If validation cannot meet the false-alarm target even at the upper threshold, do not ship that checkpoint; collect harder negatives and more independent examples.

Do not claim a higher accuracy from dataset size or training settings alone. A replacement model should only be copied into `assets/models/` after it passes the separate phone-recorded test and its `model_info.json` confirms the exact six trained slots and unchanged output order.

See [model-training-results.md](model-training-results.md) for the measured first run, including its class-level errors and why its candidate weights were not deployed.
