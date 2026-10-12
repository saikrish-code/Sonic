# Expanded sound model: first evaluation (before DIL-DCASE26)

## Data used

The first training run combined 2,000 ESC-50 recordings, 21,024 VocalSound recordings, and 440 CatMeows recordings. Audio was divided by source recording or speaker/cat group; windows from one recording were not spread across splits. The run used 20 epochs and evaluated on recordings held out from training.

This is a source-held-out evaluation, not a phone or real-world evaluation. The test set contains many background windows, so overall accuracy does not describe event detection quality on its own.

## Results

| Metric | Result |
|---|---:|
| Window accuracy | 84.7% |
| Recording-level accuracy | 90.6% |
| Macro-F1 across six targets and background | 0.653 |
| Recommended event threshold selected on validation | 0.90 |
| Background false-alarm rate at 0.90 | 1.3% validation; 1.0% test |
| Correct target event recall at 0.90 | 41.5% |

Per-class scores at the unthresholded window-level argmax operating point:

| Class | Precision | Recall | F1 | Support windows |
|---|---:|---:|---:|---:|
| Door knock | 0.52 | 0.79 | 0.62 | 38 |
| Coughing | 0.66 | 0.67 | 0.67 | 788 |
| Baby crying | 0.64 | 0.38 | 0.47 | 48 |
| Dog bark | 0.64 | 0.71 | 0.67 | 45 |
| Cat meow | 0.71 | 0.96 | 0.82 | 325 |
| Footsteps | 0.33 | 0.57 | 0.41 | 46 |
| Background/reject | 0.92 | 0.88 | 0.90 | 4,000 |

The conservative 0.90 alert threshold lowers target recall to 41.5%; at that threshold, recall was 52.6% for knocks, 34.3% for coughs, 2.1% for baby cries, 22.2% for barks, 72.0% for meows, and 0% for footsteps. This checkpoint is therefore **not suitable to replace the shipped model**. High overall accuracy is largely explained by background examples and should not be presented as 90% event accuracy.

## What this means

The expanded data and training workflow are useful, but this first model did not meet the real-world goal. In particular, the evaluation still has only 38–48 held-out clips for four event classes, and it has no held-out phone recordings. Additional independent positives are needed for knocks, baby crying, barks, and footsteps, along with hard negatives and phone recordings captured at realistic distances, rooms, and playback levels. The phone test must remain untouched while selecting thresholds.

The app changes in this repository reduce false alarms by limiting live alerts to the six requested classes, requiring the same class to pass the confidence gate in two of three overlapping windows, and disabling the untrained acoustic fallback's event guesses. These measures cannot make the existing bundled weights more accurate. A false cough can still occur if the existing model repeatedly assigns it high confidence; replacement weights should only be shipped after a separate phone-recorded test supports the change.

## DIL-DCASE26 integration attempt

The notebook now also loads DIL-DCASE26-Dev D2/D3 recordings. The integrated data pass found 4,857 files from that dataset and produced 27,075 windows across the four sources. Its dev-test clips remain test-only; non-target sounds such as speech, piano, alarms, engines, and fire are treated as hard background examples.

A full 20-epoch run reached a best validation macro-F1 of 0.573 at epoch 9, then stalled at epoch 10 for about 99 minutes. A retry capped at five epochs stalled after epoch 3 (validation macro-F1 0.338). Both were stopped before held-out test metrics and TFLite export, so **there is no completed DIL-integrated model evaluation and no DIL candidate was deployed**. The figures above describe only the earlier ESC-50, VocalSound, and CatMeows checkpoint. The DIL source adds useful coverage, but it has not yet demonstrated a better model.

The DIL-DCASE26-Dev data is available from [Zenodo](https://zenodo.org/records/19335184) under CC BY 4.0. Cite the dataset authors if its recordings or results are shared.

## Reproduction outputs

Generated weights, feature caches, and downloaded audio stay outside Git under ignored training folders. The first candidate's metadata and TFLite file were retained locally for analysis and were not copied to `assets/models/`.
