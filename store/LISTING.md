# Connect IQ Store listing draft

Text to paste into the store's listing form, plus a checklist for submitting.
Nothing here is submitted yet. Items marked **[verify]** depend on how the app
behaves on a real watch.

## Name

Sauna Session Tracker

(Keep "Garmin" out of the name; the guidelines forbid implying an affiliation.
The app's own on-watch name is "Sauna".)

## One-line summary

Time your sauna sweats and cold plunges, and record heart rate and calories as a Garmin activity.

## Description

Sauna records your sauna and cold plunge sessions as their own activity, so you don't
have to start a yoga or cardio workout and rename it afterwards.

**What it does**

- Pick a session type when the app opens: Sauna, Sauna + plunge or Plunge. A session is a
  cycle of phases. Sauna is sweat, then rest. Sauna + plunge is sweat, plunge, then rest.
  Plunge is plunge, then rest.
- Session timer with live heart rate (shown in the round subscreen on the Instinct) and calories.
- Press BACK to move to the next phase. Each phase is saved as a lap, so the time of every
  phase shows up in Garmin Connect.
- Optional max time: the watch vibrates when the sweat (or the plunge, in a plunge-only
  session) reaches a time you choose: 5 to 30 minutes for a sweat, 1 to 10 for a plunge.
- Optional max heart rate: from 120 to 180 bpm. While your heart rate is at or above it, the
  display shows HIGH and the watch vibrates once a minute. This is a convenience only. It is
  not a safety or medical feature.
- Summary after you save, in three pages: total time, average and max heart rate, calories and
  rounds; the time spent in each kind of phase; and the time of each round.
- Stop at any time, then Resume, Save or Discard. Discard asks you to confirm.
  If you close the app mid-session, the session is saved.

**Buttons**

- START/STOP (labeled GPS on the Instinct): start, or stop and open the menu
- BACK: next phase while recording; before you start, back to the session-type menu
- UP / DOWN (on the settings screen): pick the max time and the max heart rate. On the
  vivoactive 5, which has no UP or DOWN buttons, tap the setting on the screen instead.

**Works with**

Garmin Instinct 3 Solar (45mm and 50mm), Garmin Forerunner 965, Forerunner 265S, Forerunner 165
(and 165 Music) and Garmin vivoactive 5.
Not tested on other devices. On the touchscreen watches the screen is ignored while
recording, so sweat can't cause stray taps; use the buttons.

**Heat warning**

Garmin lists the Instinct 3's operating temperature as up to 60 C (140 F), which
is lower than many saunas; check your own watch's manual for its limit. Wearing
the watch in a hot sauna is at your own risk and could shorten its battery life
or damage it. Wear it on a cooler bench, or take it off for part of a session.

**Cold water.** Check your own watch's manual for its water rating and its low-temperature
limit before wearing it in a cold plunge.

**Not a medical device.** The app times sessions and records data. It does not
diagnose, treat or monitor health conditions, and it does not tell you whether
it is safe to stay in the heat.

**Privacy.** The app records your session with the watch's normal activity
recording, so it syncs to Garmin Connect like any other activity. It has no
internet access, collects no personal data of its own, and stores only your settings on
the watch: the session type, the max time for each type, and the max heart rate.

**Support and source.** Questions and bug reports:
https://github.com/drthvdr/sauna-tracker/issues. The source code is open under
the MIT license at https://github.com/drthvdr/sauna-tracker.

Garmin and Instinct are trademarks of Garmin Ltd. This app is not affiliated
with or endorsed by Garmin.

## What's new (version 1.0.0)

First release.

## Permissions to explain if asked

- Fit: records the sauna session as an activity.
- Sensor: reads heart rate for the on-screen display and the heart-rate limit.

## Assets in this folder

| File | Use |
|---|---|
| `icon-500.png` | Store app icon, 500x500, sRGB, no transparent background. Split along the diagonal from the top-right corner to the bottom-left: orange on the left, blue on the right |
| `icon-128-24bit.png` | On-device store icon for AMOLED watches: 128x128, 24-bit RGB, no transparency |
| `icon-128-64color.png` | On-device store icon for memory-in-pixel watches: 128x128, 8-bit palette holding Garmin's 64-color palette (flat colors, 16 used) |
| `hero-1440x720.png` | Hero image, 1440x720 (about 930 KB) |
| `hero-1440x720.jpg` | Same image as a JPEG (about 98 KB), in case the upload rejects large files |
| `icon.svg`, `icon-lowcolor.svg`, `icon-mono.svg`, `hero.svg` | Editable sources: full color, 64-color, one-bit (the Instinct's launcher icon) and the hero |
| `make_icons.sh` | Regenerates every icon, including the launcher icon in each `resources*/` folder |
| `device_icons.py` | Used by `make_icons.sh`: builds the two on-device icons and the one-bit launcher icon (plain Python) |
| `hero.svg` | Still the all-orange look and the tagline "Time every heat"; it has not been updated for the split icon or the sweat and plunge wording |

### Screenshots

In `screenshots/`, named `<watch>-<screen>-<source>.jpg`. Each is under 150 KB (a limit
mentioned on the Garmin developer forum, not confirmed by Garmin).

| File | Shows |
|---|---|
| `fr965-recording-simulator.jpg` | Forerunner 965 simulator, recording screen (1031x1400) |
| `fr965-summary-simulator.jpg` | Forerunner 965 simulator, summary, first page (1039x1400) |

**These two screenshots are out of date:** they were taken before the sweat, plunge and rest
phases and still show "Heat" and "heats" labels. Recapture them. They are also simulator
captures, so heart rate shows `--` and calories 0; recapture
them with simulated heart-rate data for a better listing. Screenshots should come from the
simulator or a watch, never be mocked up. There are no Instinct 3 Solar screenshots in this
folder yet: use simulator captures, or watch-only crops of photos (photos of a worn watch
show the wearer, so keep them out of this public repo). Still to capture, for each watch:
the session-type menu, the settings screen, and the summary pages.

To re-render after editing a source:

```bash
./make_icons.sh
sips -s format png hero.svg --out hero-1440x720.png
sips -s format jpeg -s formatOptions 85 hero-1440x720.png --out hero-1440x720.jpg
```

## Before you submit

1. **Test on the watch.** Run a short session of each type (Sauna, Sauna + plunge and
   Plunge) with a few phase changes, save it, and sync. **[verify]** the activity shows in Garmin Connect with the name and
   type you want, with heart rate and calories, and every phase appears as a lap
   (Garmin Connect shows laps by number, not by name).
   Check that the two alerts vibrate.
   **[verify]** Only the Instinct 3 Solar has run the current version on a real watch. The
   Forerunner 965, 265S, 165 and 165 Music and the vivoactive 5 (which uses touch for its
   settings and summary pages) have only been built, unit-tested and started in the
   simulator, with their layouts checked by measurement and not by eye. Test each on a real
   watch before listing it, or remove it from the manifest and from the "Works with" text
   above. The guidelines forbid claiming compatibility you haven't confirmed.
2. **Fix the description to match.** If Garmin Connect shows something different
   from what the description says (the lap claim, the activity type), change the
   text, not the other way round. Descriptions must be accurate.
3. **Export the package** (a release build with all supported devices):

   ```bash
   monkeyc -e -r -f monkey.jungle -o SaunaTracker.iq -y ~/.garmin/developer_key.der -w
   ```

   A dry run produced a package with seven builds: the two Instinct 3 Solar part
   numbers (006-B4585-00 and 006-B4759-00), the Forerunner 965 (006-B4315-00), 265S
   (006-B4258-00), 165 (006-B4432-00) and 165 Music (006-B4433-00), and the vivoactive 5
   (006-B4426-00).
4. **Back up `~/.garmin/developer_key.der`.** Every future update must be signed
   with the same key.
5. **Upload** the `.iq` file on Garmin's Connect IQ developer upload page (linked
   from https://developer.garmin.com/connect-iq/submit-an-app/), signed in with
   a Garmin developer account. You must be 18 or older.
6. **Fill in the listing** with the text above and the images in this folder,
   choose free, and add screenshots.
7. **Wait for review.** Garmin says up to three days. In October 2026
   developers reported waits of a week or more.

## Review risk

Garmin's guidelines say apps should not be "designed for use during activities
that will expose the device to harmful levels of heat." A free sauna timer
(Nordic, renamed EmberDip) already has a store listing, so sauna apps are not
refused outright. The heat warning above states the temperature rating honestly
rather than hiding the purpose. If the app is rejected for heat, Garmin
generally allows resubmitting with changes, and the sideload route in the
README still works.
