import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

// Unit tests for the logic that doesn't need eyes: formatting, the alert settings, tap
// targets and the session lifecycle. Run them with ./test.sh. The compiler leaves
// (:test) code out of normal builds, so none of this ends up on a watch.

(:test)
function durationFormatsMinutesSecondsAndHours(logger as Logger) as Boolean {
    Test.assertEqualMessage(SaunaFormat.duration(0), "0:00", "zero");
    Test.assertEqualMessage(SaunaFormat.duration(59999), "0:59", "just under a minute");
    Test.assertEqualMessage(SaunaFormat.duration(61000), "1:01", "one minute and one second");
    Test.assertEqualMessage(SaunaFormat.duration(600000), "10:00", "ten minutes");
    Test.assertEqualMessage(SaunaFormat.duration(3600000), "1:00:00", "exactly an hour");
    Test.assertEqualMessage(SaunaFormat.duration(3725000), "1:02:05", "over an hour");
    return true;
}

(:test)
function tapOnARowPicksThatSetting(logger as Logger) as Boolean {
    var savedHeatRow = SaunaRound._heatRowY;
    var savedHrRow = SaunaRound._hrRowY;

    SaunaRound._heatRowY = 100;
    SaunaRound._hrRowY = 200;
    Test.assertEqualMessage(SaunaRound.settingAt(110), :heat, "near the first row");
    Test.assertEqualMessage(SaunaRound.settingAt(190), :hr, "near the second row");
    Test.assertMessage(SaunaRound.settingAt(10) == null, "above both rows");
    Test.assertMessage(SaunaRound.settingAt(400) == null, "below both rows");

    SaunaRound._heatRowY = -1;
    SaunaRound._hrRowY = -1;
    Test.assertMessage(SaunaRound.settingAt(110) == null, "no rows drawn yet");

    SaunaRound._heatRowY = savedHeatRow;
    SaunaRound._hrRowY = savedHrRow;
    return true;
}

(:test)
function visibleWidthAtTheMiddleOfTheScreenIsTheFullWidth(logger as Logger) as Boolean {
    // True for a round screen (the widest chord) and for a rectangular one (always full).
    Test.assertMessage((SaunaRound.chordWidth(400, 200) - 400).abs() < 0.01, "full width at the middle");
    return true;
}

(:test)
function pageHintMatchesTheButtonsTheWatchHas(logger as Logger) as Boolean {
    var hint = SaunaRound.pageHint("heats");
    if (SaunaLayout.hasPageButtons()) {
        Test.assertEqualMessage(hint, "DOWN: heats", "button watches name the DOWN button");
    } else {
        Test.assertEqualMessage(hint, "Tap: heats", "touch watches say tap");
    }
    return true;
}

(:test)
function heatAlertCyclesThroughEveryOptionAndWraps(logger as Logger) as Boolean {
    var session = new SaunaSession();
    var start = session.getHeatAlertMin();
    var seen = [start];
    for (var i = 0; i < HEAT_ALERT_OPTIONS.size() - 1; i += 1) {
        session.cycleHeatAlert();
        var value = session.getHeatAlertMin();
        Test.assertMessage(HEAT_ALERT_OPTIONS.indexOf(value) >= 0, "every value is one of the options");
        Test.assertMessage(seen.indexOf(value) < 0, "every step is a new value");
        seen.add(value);
    }
    session.cycleHeatAlert();
    Test.assertEqualMessage(session.getHeatAlertMin(), start, "wraps back to the start");
    return true;
}

(:test)
function hrLimitCyclesThroughEveryOptionAndWraps(logger as Logger) as Boolean {
    var session = new SaunaSession();
    var start = session.getHrLimit();
    var seen = [start];
    for (var i = 0; i < HR_LIMIT_OPTIONS.size() - 1; i += 1) {
        session.cycleHrLimit();
        var value = session.getHrLimit();
        Test.assertMessage(HR_LIMIT_OPTIONS.indexOf(value) >= 0, "every value is one of the options");
        Test.assertMessage(seen.indexOf(value) < 0, "every step is a new value");
        seen.add(value);
    }
    session.cycleHrLimit();
    Test.assertEqualMessage(session.getHrLimit(), start, "wraps back to the start");
    return true;
}

(:test)
function alertSettingsAreRememberedByTheNextSession(logger as Logger) as Boolean {
    var session = new SaunaSession();
    session.cycleHeatAlert();
    session.cycleHrLimit();
    var other = new SaunaSession();
    Test.assertEqualMessage(other.getHeatAlertMin(), session.getHeatAlertMin(), "heat alert is saved");
    Test.assertEqualMessage(other.getHrLimit(), session.getHrLimit(), "HR limit is saved");

    // Put both settings back the way they were.
    for (var i = 0; i < HEAT_ALERT_OPTIONS.size() - 1; i += 1) {
        session.cycleHeatAlert();
    }
    for (var i = 0; i < HR_LIMIT_OPTIONS.size() - 1; i += 1) {
        session.cycleHrLimit();
    }
    return true;
}

(:test)
function aFreshSessionIsIdleOnTheFirstHeat(logger as Logger) as Boolean {
    var session = new SaunaSession();
    Test.assertEqualMessage(session.getState(), STATE_IDLE, "starts idle");
    Test.assertEqualMessage(session.heatNumber(), 1, "first heat");
    Test.assertEqualMessage(session.timerMs(), 0, "timer at zero");
    Test.assertEqualMessage(session.calories(), 0, "no calories yet");
    return true;
}

(:test)
function markingAHeatDoesNothingBeforeTheSessionStarts(logger as Logger) as Boolean {
    var session = new SaunaSession();
    session.markHeat();
    Test.assertEqualMessage(session.heatNumber(), 1, "still the first heat");
    Test.assertEqualMessage(session.getState(), STATE_IDLE, "still idle");
    return true;
}

(:test)
function aSessionCanBeStartedMarkedStoppedResumedAndDiscarded(logger as Logger) as Boolean {
    var session = new SaunaSession();
    session.start();
    Test.assertEqualMessage(session.getState(), STATE_RECORDING, "recording after start");
    session.markHeat();
    Test.assertEqualMessage(session.heatNumber(), 2, "second heat after marking one");
    session.stop();
    Test.assertEqualMessage(session.getState(), STATE_PAUSED, "paused after stop");
    session.resume();
    Test.assertEqualMessage(session.getState(), STATE_RECORDING, "recording again after resume");
    session.discard();
    Test.assertEqualMessage(session.getState(), STATE_IDLE, "idle after discard");
    Test.assertEqualMessage(session.getLastResult(), "Discarded", "says it was discarded");
    Test.assertEqualMessage(session.heatNumber(), 1, "back to the first heat");
    return true;
}

(:test)
function savingGivesASummaryWithEveryMarkedHeat(logger as Logger) as Boolean {
    var session = new SaunaSession();
    session.start();
    session.markHeat();
    session.markHeat();
    var summary = session.save();
    if (summary == null) {
        return false;
    }
    // Two marks end two heats; the empty third heat is left out.
    Test.assertEqualMessage(summary.heatTimes.size(), 2, "two heats are listed");
    Test.assertMessage(summary.avgHr == null && summary.maxHr == null, "no heart-rate samples were taken");
    Test.assertEqualMessage(session.getState(), STATE_IDLE, "idle again");
    Test.assertEqualMessage(session.getLastResult(), "Saved", "says it was saved");
    return true;
}
