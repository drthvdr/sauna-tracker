# Connect IQ Store listing draft

Text to paste into the store's listing form, plus a checklist for submitting.
Nothing here is submitted yet. Items marked **[verify]** depend on how the app
behaves on a real watch.

## Name

Sauna Session Tracker

(Keep "Garmin" out of the name; the guidelines forbid implying an affiliation.
The app's own on-watch name is "Sauna".)

## One-line summary

Time every sauna heat and record heart rate and calories as a Garmin activity.

## Description

Sauna records your sauna sessions as their own activity, so you don't have to
start a yoga or cardio workout and rename it afterwards.

**What it does**

- Session timer with live heart rate (shown in the round subscreen) and calories.
- Press BACK to end a heat and start the next. Each heat is saved as a lap, so
  the time of every round shows up in Garmin Connect.
- Optional heat alert: the watch vibrates when the current heat reaches a time
  you choose, from 5 to 30 minutes.
- Optional heart-rate limit: from 120 to 180 bpm. While your heart rate is at or
  above it, the circle shows HIGH and the watch vibrates once a minute. This is
  a convenience only. It is not a safety or medical feature.
- Summary after you save: total time, average and max heart rate, calories, and
  the time of each heat.
- Stop at any time, then Resume, Save or Discard. Discard asks you to confirm.
  If you close the app mid-session, the session is saved.

**Buttons**

- GPS: start, or stop and open the menu
- BACK: end the current heat
- UP / DOWN (before you start): pick the heat alert and the heart-rate limit

**Works with**

Garmin Instinct 3 Solar (45mm and 50mm). Not tested on other devices.

**Heat warning**

Garmin lists the Instinct 3's operating temperature as up to 60 C (140 F), which
is lower than many saunas. Wearing the watch in a hot sauna is at your own risk
and could shorten its battery life or damage it. Wear it on a cooler bench, or
take it off for part of a session.

**Not a medical device.** The app times sessions and records data. It does not
diagnose, treat or monitor health conditions, and it does not tell you whether
it is safe to stay in the heat.

**Privacy.** The app records your session with the watch's normal activity
recording, so it syncs to Garmin Connect like any other activity. It has no
internet access, collects no personal data of its own, and stores only your two
alert settings on the watch.

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
| `icon-500.png` | Store app icon, 500x500, sRGB, no transparent background |
| `icon-128.png` | Optional 128x128 icon for the on-device store |
| `hero-1440x720.png` | Hero image, 1440x720 (about 930 KB) |
| `hero-1440x720.jpg` | Same image as a JPEG (about 98 KB), in case the upload rejects large files |
| `icon.svg`, `hero.svg` | Editable sources for the images |

Screenshots are not included: they should come from the simulator or the
watch, not be mocked up. Suggested set: the recording screen, the idle screen
with the alert settings, summary page 1, and the heats page.

To re-render after editing a source:

```bash
sips -s format png icon.svg --out icon-500.png
sips -z 128 128 icon-500.png --out icon-128.png
sips -s format png hero.svg --out hero-1440x720.png
sips -s format jpeg -s formatOptions 85 hero-1440x720.png --out hero-1440x720.jpg
```

## Before you submit

1. **Test on the watch.** Run a short session with at least one heat, save it,
   and sync. **[verify]** the activity shows in Garmin Connect with the name and
   type you want, with heart rate and calories, and the heats appear as laps.
   Check that the two alerts vibrate.
2. **Fix the description to match.** If Garmin Connect shows something different
   from what the description says (the lap claim, the activity type), change the
   text, not the other way round. Descriptions must be accurate.
3. **Export the package** (a release build with all supported devices):

   ```bash
   monkeyc -e -r -f monkey.jungle -o SaunaTracker.iq -y ~/.garmin/developer_key.der -w
   ```

   A dry run produced a package with builds for both Instinct 3 Solar part
   numbers (006-B4585-00 and 006-B4759-00).
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
