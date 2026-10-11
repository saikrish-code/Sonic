# Sonic wearable hardware plan

## Recommended first prototype

Sonic's phone remains the microphone and sound classifier. It performs on-device sound classification and sends alert commands over BLE. The wearable only receives commands and drives haptic feedback; no wearable microphone or sound classification is part of this build.

| Component | Quantity | Estimated price (₹) | Status |
|---|---:|---:|---|
| Seeed XIAO ESP32C3 (built-in LiPo charging) | 1 | 700–900 | Primary wearable controller |
| ESP32-C3 SuperMini | 1 | 250–350 | Optional spare / firmware testing |
| DRV2605L haptic driver breakout | 1 | 350–600 | Initial haptic driver |
| 8–10 mm LRA coin motor | 1 initially; 1 spare optional | 300–500 for 2 | Primary actuator; select against motor specifications |
| 6–8 mm ERM coin motor | 1 initially; 1 spare optional | 60–120 for 2 | Optional/deferred fallback |
| Transistor, resistor and diode for ERM circuit | 1 set | 20–30 | Optional/deferred fallback circuit |
| 3.7 V LiPo, 150–200 mAh, with protection circuit | 1 initially; 1 spare optional | 250–400 for 2 | Protected cell; verify charge-rate rating |
| Small slide switch | 1 | 10–20 | Power isolation |
| Thin enamelled or silicone wire, heat-shrink, perfboard scrap | 1 set | 150–250 | Interconnect/build materials |
| Ear hook (reuse cheap earphones or 3D-print) | 1 | 150–400 | Mechanical mounting |
| **Planning total** | | **≈ ₹2,300–3,700** | Approximate budget envelope only; subject to actual prices, shipping, taxes and selected parts. Includes optional spares/fallback parts. |

The line-item ranges and total are procurement estimates, not live quotes or a fixed sum for every low/high combination. Verify local supplier prices before ordering.
## Optional or deferred parts

- SuperMini spare, second LRA, second battery, and ERM fallback circuit can be deferred until the first BLE-to-haptic bench test works.
- Do not include a Nordic nRF52840 board, separate TP4056 USB-C charger, 500 mAh battery, or wearable MEMS microphone in the recommended first build.
- The phone provides the microphone and classification. Keep audio capture and classification in the Flutter app.

## Power and haptic compatibility checks

The XIAO ESP32C3 vendor documentation specifies a 3.7 V lithium battery input and built-in battery charge/discharge circuitry. Use the board's designated BAT connection and charge through the board's USB input; do not add a TP4056 charger in parallel. The board's protection does not make an unprotected cell a safe choice: retain the specified protected LiPo and verify the exact board revision and battery wiring before assembly. Its published charge current is about 380 mA (±30 mA), which is relatively high for a 150–200 mAh cell (about 1.9–2.7 C). Check the cell maker's allowed charge rate before charging it on-board; select a cell rated for that charge current or use a properly engineered lower-current charger arrangement.

TI specifies the DRV2605L for ERM and LRA actuators, with a 2–5.2 V supply range. That establishes driver-family compatibility, not compatibility with every small LRA. Check the specific LRA's rated voltage/current and resonance and configure/calibrate the driver accordingly. A nominal 3.7 V LiPo sits inside the stated supply range, but account for battery voltage over its discharge range and motor current demand. Keep motor current out of GPIO pins. Test the selected breakout and motor on a current-limited bench supply before wearing it.

## BLE and app integration status

The Flutter app currently advertises its intended GATT values in `lib/core/ble/ble_service.dart`:

- Service UUID: `0000FEAA-0000-1000-8000-00805F9B34FB`
- Haptic characteristic UUID: `0000FEAB-0000-1000-8000-00805F9B34FB`
- Battery characteristic UUID: `00002A19-0000-1000-8000-00805F9B34FB`

The source describes physical characteristic writes as future work; the app currently has mock device support, and packet transmission is not implemented. The README also says production hardware UUIDs and proprietary GATT characteristics will be finalized later. Before firmware integration, define and test one peripheral GATT service and command format, then align the wearable firmware and Flutter app. UUID changes are not required solely because the controller changes to XIAO ESP32C3; they are required if the final firmware uses different UUIDs. The packet/protocol must be implemented on both sides. Do not change these placeholder UUIDs as part of the hardware-list update.

## References

- [Seeed XIAO ESP32C3 getting-started guide](https://wiki.seeedstudio.com/XIAO_ESP32C3_Getting_Started/)
- [Seeed XIAO series hardware manual (charge current and charger details)](https://files.seeedstudio.com/wiki/XIAO/Seeed-Studio-XIAO-Series-SOM-Datasheet.pdf)
- [TI DRV2605L product page and datasheet](https://www.ti.com/product/DRV2605L)
- [Adafruit DRV2605L breakout guide](https://learn.adafruit.com/adafruit-drv2605-haptic-controller-breakout)

