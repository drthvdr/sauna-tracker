# Sauna

A small Garmin Connect IQ watch app that records sauna and cold plunge sessions as their own
activity. It runs on the **Instinct 3 Solar**, the **Forerunner 965**, **265S** and **165**
(including the 165 Music), and the **vivoactive 5**. Pick the kind of session, step through its
phases with BACK, and save: heart rate, calories and a time-per-phase breakdown end up in
Garmin Connect like any other activity, with no need to record a yoga workout and rename it
afterwards.

## Features

- **Three session types**, picked when the app opens: **Sauna**, **Sauna + plunge** and **Plunge**.
- **Phases:** BACK moves to the next phase and starts over after the last one. Each phase is a lap
  in the FIT file.
- **Heart rate always in view:** in the Instinct's round subscreen, or large and centered on
  the round-screen watches.
- **Optional alerts**, set before you start and remembered between sessions: a vibration when the
  timed phase reaches a **max time**, and a **max HR** that shows "HIGH" and vibrates once a
  minute while you are over it.
- **Summary after saving**, in three pages: total time, average and max heart rate, calories and
  rounds; the time spent in each kind of phase; and the time of each round.
- **Safe exits:** Discard asks for confirmation, and closing the app mid-session saves it.

## Status

Builds cleanly for all six watch models and passes the unit tests on each. Before the cold
plunge session types were added, the app was run on an Instinct 3 Solar. The current version
has been run in the Connect IQ simulator on every watch, and the layout was checked by measuring
the screen on each round watch, but only the Instinct has the new version on a real wrist, and
the Forerunners and the vivoactive 5 have not been tried on real watches at all. How Garmin
Connect labels the saved activity and its laps is still being checked (see
[How it is recorded](#how-it-is-recorded)).

## Using it

When the app opens you pick the **session type**; the next screen holds the two settings, and
START/STOP begins the session. A session is a cycle of phases: a **sweat** is time in the sauna,
a **plunge** is time in the cold water, and **rest** is the time in between.

| Session type | Phases, in order |
|---|---|
| Sauna | sweat, rest |
| Sauna + plunge | sweat, plunge, rest |
| Plunge | plunge, rest |

| Button | Settings screen | Recording | Stopped menu |
|---|---|---|---|
| START/STOP (GPS) | Start session | Stop and open menu | Select menu item |
| BACK | Back to the session-type menu | Next phase | Reopen menu |
| UP | Cycle the max time | – | – |
| DOWN | Cycle the max HR | – | – |

In the session-type menu BACK leaves the app. The Stopped menu offers **Resume**, **Save** and
**Discard**; Discard asks for confirmation first ("Keep session" is selected by default). The
top-right button is labeled GPS on the Instinct 3 and START/STOP on the Forerunners and the
vivoactive 5. Touchscreens are ignored while the app is open, so sweat can't cause stray taps;
use the buttons.

The vivoactive 5 has only START/STOP and BACK, no UP or DOWN. There, on the settings screen, tap
the "Max time" or "Max HR" row to change it, and on the summary a tap or an up swipe goes to the
next page and a down swipe to the previous one. While recording nothing responds to touch. The
watch's touchscreen has to be enabled in its settings for this.

**Main screen (Instinct 3 Solar)**

- Circle (top right): live heart rate. It turns black with "HIGH" while over your max HR.
- Top left: the session type and calories.
- Big number: time of the whole session.
- Bottom line: the phase in progress, its round and its time, plus the max time while it applies,
  for example `Sweat 2  3:41 / 15m` or `Rest 2  1:05`.

**Main screen (the round-screen watches)**: white and colored text on black. From the top:
the session type, heart rate with its unit (on a red band while over your max HR), the session
timer, the phase in progress with its time (sweat orange, plunge blue, rest gray), then calories.
The settings screen has no timer: below the session type and live heart rate it shows the max
time and max HR and a "START to begin" hint. Fonts are picked from the screen's measurements so
the rows fit the 360, 390 and 454 pixel screens without overlapping.

**Alerts** (settings screen)

- **Max time:** Off, or 5 to 30 minutes in 5-minute steps for the two sauna types, where it times
  the sweat. For a plunge-only session it times the plunge instead, in 1 to 5 minute steps and 10.
  The watch vibrates once when the timed phase reaches that time, and moving to the next phase
  re-arms it. A plunge inside a sauna + plunge session, and every rest, are not timed. Each
  session type remembers its own max time.
- **Max HR:** Off, or 120 to 180 bpm in steps of 10, in every phase. The HR alert is a
  convenience, not a safety device.

**Summary** (after Save), three pages turned with DOWN and UP (a tap or swipe on the vivoactive 5):

1. Total time, average and max heart rate, calories, and the number of rounds.
2. Total time in each kind of phase this session type has.
3. The time of each round's main phase: the sweat, or the plunge in a plunge-only session.

START/STOP (GPS) or BACK closes it.

## Requirements

- One of these watches. Other models need their ID added to the manifest and a layout check:
  watches with the Instinct's round subscreen use that layout, all others use the centered one,
  and watches without UP/DOWN buttons use touch for the settings and summary pages.

  | Watch | Device ID | Screen | Layout | Controls |
  |---|---|---|---|---|
  | Instinct 3 Solar 45mm / 50mm | `instinct3solar45mm` | 176x176, two colors, with the round subscreen | Instinct | five buttons |
  | Forerunner 965 | `fr965` | 454x454 round AMOLED | round | five buttons |
  | Forerunner 265S | `fr265s` | 360x360 round AMOLED | round | five buttons |
  | Forerunner 165 | `fr165` | 390x390 round AMOLED | round | five buttons |
  | Forerunner 165 Music | `fr165m` | 390x390 round AMOLED | round | five buttons |
  | vivoactive 5 | `vivoactive5` | 390x390 round AMOLED | round | START/STOP, BACK and touch |
- The [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) with those devices
  installed. Built with SDK 9.3.0; the manifest asks for API level 3.2.7 or newer.
- A JDK (`java -version` must work). Temurin 27 worked: `brew install --cask temurin`.
- A Connect IQ developer key (below).
- `build.sh` is written for macOS. On another OS, run `monkeyc` directly (see [Build](#build)).

## Setup

1. Install the SDK Manager from Garmin, open it, and download the latest SDK plus the
   **Instinct 3 Solar 45mm / 50mm**, **Forerunner 965**, **265S**, **165**, **165 Music** and
   **vívoactive 5** devices. Make that SDK the active one.
2. Create a developer key. It signs your builds; keep it private and never commit it.

   ```bash
   mkdir -p ~/.garmin
   openssl genrsa -out ~/.garmin/developer_key.pem 4096
   openssl pkcs8 -topk8 -inform PEM -outform DER \
     -in ~/.garmin/developer_key.pem -out ~/.garmin/developer_key.der -nocrypt
   ```

   `build.sh` looks for `~/.garmin/developer_key.der`; set `CIQ_KEY` to use another path.
   If you ever publish to the Connect IQ Store you must keep using the same key.

## Build

```bash
./build.sh                   # Instinct 3 Solar: bin/SaunaTracker.prg
./build.sh run               # compile, then run in the Connect IQ simulator
DEVICE=fr965 ./build.sh      # Forerunner 965: bin/SaunaTracker-fr965.prg
DEVICE=fr965 ./build.sh run  # compile and run that one in the simulator
DEVICE=vivoactive5 ./build.sh  # vivoactive 5: bin/SaunaTracker-vivoactive5.prg
```

`DEVICE=` takes any device ID from the table above (`fr265s`, `fr165`, `fr165m`, and so on) and
writes `bin/SaunaTracker-<device>.prg`.

The simulator shows one watch at a time, so running a second device switches it.

### Simulating heart rate

The simulator has no heart rate until you start simulated data, so the screens show `--`.
With the simulator running, start it with:

```bash
"$(cat "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")/bin/shell" fit_parse --simulate
```

Heart rate then shows up even before a session starts. Use `--stop` instead of `--simulate` to
end it. The simulator's Simulation > FIT Data menu should do the same.

## Tests

Unit tests are in `source/SaunaTests.mc` and run in the Connect IQ simulator with the SDK's
built-in test runner. They cover time formatting, the three session types and their phases, the
settings and how they are saved, the tap targets, and the session lifecycle (start, next phase,
stop, resume, save, discard) including the summary maths. Test
code is left out of normal builds.

```bash
./test.sh            # every watch in the manifest
./test.sh fr965      # only the watches named
```

The script builds a test version for each watch, runs it in the simulator, and exits with 1 if
anything fails. It reads the result from the runner's output, because `monkeydo` exits with 1
even when every test passes. The tests use the simulator window, so don't leave another app
running in it. Screen layouts are not covered; check those by eye.

There is no GitHub Action yet. A CI run would need the SDK's device files, which Garmin only
gives to logged-in accounts, so it would mean storing Garmin credentials as repository secrets.

Without `build.sh`:

```bash
monkeyc -d instinct3solar45mm -f monkey.jungle -o bin/SaunaTracker.prg -y /path/to/developer_key.der -w
```

## Install on the watch

The Instinct 3 transfers files over **MTP**, so on macOS it does not show up as a drive in
Finder. Copying the app means putting `bin/SaunaTracker.prg` into the watch's `Garmin/Apps`
folder with an MTP tool. For the other watches the file is `bin/SaunaTracker-<device>.prg`; the
steps should be the same, but they have only been tried on the Instinct. To update an app already
on the watch, copy the new build over in the same way. The watch installs a sideloaded program
when it is unplugged and removes the file from `Apps`, so there is no old copy left there to
delete; the app's saved settings are kept in a separate folder.

1. **Quit Garmin Express and its background service.** Garmin Express takes exclusive hold of
   the watch, and while it does no other tool can see it. Quit the app, then quit the
   "Garmin Express Service" process too (Activity Monitor, or `pkill -f "Garmin Express Service"`).
   To check that the watch is free:

   ```bash
   ioreg -p IOUSB -l -w0 | grep UsbExclusiveOwner   # no output means nothing is holding it
   ```

2. **Plug the watch in** over USB.
3. **Copy the file** to `Garmin/Apps` with either:
   - a GUI MTP tool such as [OpenMTP](https://openmtp.ganeshrvel.com/) (not tried here), or
   - the command line with libmtp, below.
4. **Unplug the watch.** Then look for **Sauna** in the watch's activity or apps list.
5. **Start Garmin Express again** so normal syncing to Garmin Connect works.

### Command line with libmtp

```bash
brew install libmtp
mtp-detect | grep -E "Manufacturer|Model"   # should list the Instinct 3
mtp-folders | grep -v association           # find the ID of the Apps folder under Garmin
```

`mtp-folders` prints one folder per line as `ID`, then the name indented by depth. Note the ID
of `Apps` directly under `Garmin` (it was `16777221` on the watch this was written on; yours may
differ).

The obvious `mtp-sendfile bin/SaunaTracker.prg Garmin/Apps/SaunaTracker.prg` fails on the
Instinct 3 with `get_suggested_storage_id(): could not get storage id from parent id`, because
libmtp cannot look up the storage from the parent folder. Naming the storage yourself avoids
it. Save this as `sendmtp.c`:

<details>
<summary>sendmtp.c</summary>

```c
#include <libmtp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

/* usage: sendmtp <local file> <name on watch> <parent folder id> */
int main(int argc, char **argv) {
    struct stat st;
    if (argc != 4 || stat(argv[1], &st) != 0) {
        fprintf(stderr, "usage: sendmtp <file> <name> <folder id>\n");
        return 2;
    }
    LIBMTP_Init();
    LIBMTP_mtpdevice_t *dev = LIBMTP_Get_First_Device();
    if (!dev || LIBMTP_Get_Storage(dev, LIBMTP_STORAGE_SORTBY_NOTSORTED) != 0 || !dev->storage) {
        fprintf(stderr, "no MTP device found\n");
        return 1;
    }
    LIBMTP_file_t *f = LIBMTP_new_file_t();
    f->filename = strdup(argv[2]);
    f->filesize = st.st_size;
    f->filetype = LIBMTP_FILETYPE_UNKNOWN;
    f->parent_id = strtoul(argv[3], NULL, 10);
    f->storage_id = dev->storage->id; /* naming the storage avoids the failing lookup */
    int rc = LIBMTP_Send_File_From_File(dev, argv[1], f, NULL, NULL);
    if (rc) LIBMTP_Dump_Errorstack(dev); else printf("sent, object id %u\n", f->item_id);
    LIBMTP_destroy_file_t(f);
    LIBMTP_Release_Device(dev);
    return rc != 0;
}
```

</details>

Then build and run it, using your Apps folder ID:

```bash
cc -I/opt/homebrew/include -L/opt/homebrew/lib -lmtp -o sendmtp sendmtp.c
./sendmtp bin/SaunaTracker.prg SaunaTracker.prg 16777221
```

To check the copy, `mtp-files` lists it with its parent ID, and `mtp-getfile <file id> copy.prg`
followed by `shasum -a 256` on both files confirms it is identical to the build.

### If the watch is not found

- Anything else holding the USB device blocks every tool. Garmin Express is the usual cause.
- On macOS, `mtp-detect` may print "Device ... is UNKNOWN in libmtp". That warning is harmless;
  the watch is detected as an MTP device anyway.

Sessions sync to Garmin Connect through the normal watch sync.

## How it is recorded

Connect IQ has no sauna sport type, so the app records a Training activity with the Cardio
sub-sport, named "Sauna", "Sauna + plunge" or "Cold plunge" after the session type you picked.
Every phase change is a lap, so a session shows up in Garmin Connect as a run of laps in the
type's order (sweat, rest, sweat, rest, and so on). The laps carry no names there, only their
order and times. The Training sport type gives the activity no distance, whereas the generic
sport type would show up as a distance activity with zero miles. Heart rate and calories
are written by the watch itself while the session runs. If Garmin Connect's label or training
effect isn't what you want, change the sport and sub-sport in `SaunaSession.start()`.

## Project layout

| Path | Purpose |
|---|---|
| `manifest.xml`, `monkey.jungle` | App id, devices, permissions, build config |
| `build.sh` | Build and simulator helper (macOS); `DEVICE=` picks the watch |
| `test.sh` | Runs the unit tests in the simulator, one watch at a time |
| `source/SaunaApp.mc` | App entry point; saves an in-progress session on exit |
| `source/SaunaSession.mc` | Recording, session types and phases, heart-rate stats, alerts, saved settings |
| `source/SaunaTypes.mc` | The phases of each session type and the names shown on screen |
| `source/SaunaView.mc` | Main screen for watches with the Instinct subscreen |
| `source/SaunaSummary.mc` | Post-save summary screens (Instinct layout) |
| `source/SaunaRound.mc` | Main and summary screens for the watches without a subscreen (the Forerunners and the vivoactive 5) |
| `source/SaunaDelegate.mc` | Button handling, touch guard, and the Stopped and Discard menus |
| `source/SaunaLayout.mc` | Subscreen lookup, heart-rate circle and font-fitting helpers |
| `source/SaunaFormat.mc` | Time formatting |
| `source/SaunaTests.mc` | Unit tests (left out of normal builds) |
| `resources/` | App name and launcher icon |
| `resources-<device>/` | One launcher icon per watch, sized to what it asks for: 62 px Instinct (in `resources/`), 65 px 965, 60 px 265S, 54 px 165, 56 px vivoactive 5. The 165 Music borrows the 165's through `monkey.jungle` |
| `store/` | Connect IQ Store listing text and images |

## License

[MIT](LICENSE).
