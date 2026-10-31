# Sauna

A small Garmin Connect IQ watch app for the **Garmin Instinct 3 Solar** that records sauna
sessions as their own activity. Start it, mark each heat, and save: heart rate, calories and
a time-per-heat breakdown end up in Garmin Connect like any other activity, with no need to
record a yoga workout and rename it afterwards.

## Features

- **Session timer** with heart rate and calories, recorded to a normal FIT activity named "Sauna".
- **Heats:** press BACK to end one heat and start the next (stored as laps in the FIT file).
- **Heart rate in the Instinct's round subscreen**, so it stays in view.
- **Optional alerts**, set before you start and remembered between sessions:
  a vibration when a heat reaches a chosen time, and a heart-rate limit that shows "HIGH" and
  vibrates once a minute while you are over it.
- **Summary after saving:** total time, average and max heart rate, calories and the time of each heat.
- **Safe exits:** Discard asks for confirmation, and closing the app mid-session saves it.

## Status

Builds cleanly and has been run in the Connect IQ simulator. Behavior on a real watch, in
particular how Garmin Connect labels the saved activity, is still being checked (see
[How it is recorded](#how-it-is-recorded)).

## Using it

A **heat** is one stretch in the sauna between breaks.

| Button | Idle | Recording | Stopped menu |
|---|---|---|---|
| GPS (START/STOP) | Start session | Stop and open menu | Select menu item |
| BACK | Exit app | End the current heat | Reopen menu |
| UP | Cycle the heat alert | – | – |
| DOWN | Cycle the heart-rate limit | – | – |

The Stopped menu offers **Resume**, **Save** and **Discard**.

**Main screen**

- Circle (top right): live heart rate. It turns black with "HIGH" while over your limit.
- Top left: app state and calories.
- Big number: time of the whole session.
- Bottom line: current heat number and its time, plus the heat alert if one is set,
  for example `Heat 2  3:41 / 15m`.

**Alerts** (idle screen)

- **Heat alert:** Off, or 5 to 30 minutes in 5-minute steps. The watch vibrates once when the
  current heat reaches that time. Ending the heat with BACK re-arms it for the next one.
- **HR max:** Off, or 120 to 180 bpm in steps of 10. The HR alert is a convenience, not a
  safety device.

**Summary** (after Save): totals on the first page; UP or DOWN switches to the time of each
heat. GPS or BACK closes it.

## Requirements

- A Garmin **Instinct 3 Solar** (45mm / 50mm). The device ID in the manifest is
  `instinct3solar45mm`; other models need a different ID and a layout check.
- The [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) with the Instinct 3 Solar
  device installed. Built with SDK 9.3.0; the manifest asks for API level 3.2.7 or newer.
- A JDK (`java -version` must work). Temurin 27 worked: `brew install --cask temurin`.
- A Connect IQ developer key (below).
- `build.sh` is written for macOS. On another OS, run `monkeyc` directly (see [Build](#build)).

## Setup

1. Install the SDK Manager from Garmin, open it, and download the latest SDK plus the
   **Instinct 3 Solar 45mm / 50mm** device. Make that SDK the active one.
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
./build.sh        # compile to bin/SaunaTracker.prg
./build.sh run    # compile, then run in the Connect IQ simulator
```

Without `build.sh`:

```bash
monkeyc -d instinct3solar45mm -f monkey.jungle -o bin/SaunaTracker.prg -y /path/to/developer_key.der -w
```

## Install on the watch

The Instinct 3 transfers files over **MTP**, so on macOS it does not show up as a drive in
Finder. Copying the app means putting `bin/SaunaTracker.prg` into the watch's `Garmin/Apps`
folder with an MTP tool.

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
sub-sport and the name "Sauna". That gives a timed, heart-rate-based activity with no distance;
the generic sport type shows up as a distance activity with zero miles. Heart rate and calories
are written by the watch itself while the session runs. If Garmin Connect's label or training
effect isn't what you want, change the sport and sub-sport in `SaunaSession.start()`.

## Project layout

| Path | Purpose |
|---|---|
| `manifest.xml`, `monkey.jungle` | App id, device, permissions, build config |
| `build.sh` | Build and simulator helper (macOS) |
| `source/SaunaApp.mc` | App entry point; saves an in-progress session on exit |
| `source/SaunaSession.mc` | Recording, heats, heart-rate stats, alerts, saved settings |
| `source/SaunaView.mc` | Main screen |
| `source/SaunaDelegate.mc` | Button handling and the Stopped and Discard menus |
| `source/SaunaSummary.mc` | Post-save summary screens |
| `source/SaunaLayout.mc` | Heart-rate circle and font-fitting helpers |
| `source/SaunaFormat.mc` | Time formatting |
| `resources/` | App name and launcher icon |

## License

No license has been chosen yet.
