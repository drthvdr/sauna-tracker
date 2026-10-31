# Sauna – Connect IQ watch app for the Garmin Instinct 3 Solar

A single-purpose activity app: it records a FIT activity named **Sauna** with
heart rate and calories, and syncs to Garmin Connect like any other activity.

## Controls

A **heat** is one stretch in the sauna; BACK ends the current heat and starts the next
(a lap in the FIT file).

| Button | Idle | Recording | Stopped (menu) |
|---|---|---|---|
| GPS (START/STOP) | Start session | Stop and open menu | Select menu item |
| BACK | Exit app | End the current heat | Reopen menu |
| UP | Cycle the heat alert | – | – |
| DOWN | Cycle the heart-rate limit | – | – |

The menu offers Resume, Save and Discard; Discard asks for confirmation first ("Keep session"
is selected by default). Closing the app mid-session saves it.

## Screen

- **Circle (top right):** live heart rate. It turns black with "HIGH" while over the limit.
- **Top left:** the app state and calories.
- **Big number:** time of the whole session.
- **Bottom line:** current heat number and its time, plus the heat alert if one is set.

After Save, a summary shows total time, average heart rate (in the circle), max heart rate,
heats and calories. UP or DOWN flips to the time of each heat; GPS or BACK closes it.

## Alerts

Both are picked on the idle screen and remembered between sessions.

- **Heat alert** (Off, 5 to 30 min): the watch vibrates once when the current heat
  reaches that time. Ending a heat with BACK re-arms it for the next one.
- **HR max** (Off, 120 to 180 bpm): while heart rate is at or above the limit the circle
  shows "HIGH" and the watch vibrates once a minute. It is a convenience alert, not a
  safety device.

## One-time setup

1. Install the Connect IQ SDK Manager from https://developer.garmin.com/connect-iq/sdk/,
   open it, and download the latest SDK plus the **Instinct 3 Solar 45mm / 50mm** device.
   Make that SDK the active one.
2. The compiler needs Java. If `java -version` fails, install a JDK
   (`brew install --cask temurin`).
3. A signing key is already at `~/.garmin/developer_key.der`. Back it up: you need the
   same key for every later build you publish to the Connect IQ Store.

## Build and run

```bash
./build.sh        # produces bin/SaunaTracker.prg
./build.sh run    # builds, then runs in the Connect IQ simulator
```

## Put it on the watch

Plug the watch in over USB and copy `bin/SaunaTracker.prg` to `GARMIN/Apps/`. If the
watch doesn't mount as a drive in Finder, it uses MTP and needs a transfer tool such as
OpenMTP. Eject, then find **Sauna** in the watch's app list.

## Things to check on the real watch

- **Activity type in Garmin Connect.** Connect IQ has no sauna sport, so the app records
  `SPORT_TRAINING` / `SUB_SPORT_CARDIO_TRAINING` (see `SaunaSession.start()`). Change
  those two constants if the label or training-load effect isn't what you want.
- **Device ID.** `instinct3solar45mm` is what the SDK lists for the Instinct 3 Solar. The
  SDK has no separate 50mm entry, so a sideloaded build should cover both sizes (untested).
