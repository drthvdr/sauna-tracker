import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

// Unit tests for the logic that doesn't need eyes: formatting, the session types and their
// phases, the settings, tap targets and the session lifecycle. Run them with ./test.sh. The
// compiler leaves (:test) code out of normal builds, so none of this ends up on a watch.

// Steps a setting around until it reads target again, to leave the saved settings as found.
(:debug)
function putMaxTimeBack(session as SaunaSession, target as Number) as Void {
    for (var i = 0; i < 10 && session.getMaxTimeMin() != target; i += 1) {
        session.cycleMaxTime();
    }
}

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
    var savedTimeRow = SaunaRound._timeRowY;
    var savedHrRow = SaunaRound._hrRowY;

    SaunaRound._timeRowY = 100;
    SaunaRound._hrRowY = 200;
    Test.assertEqualMessage(SaunaRound.settingAt(110), :time, "near the first row");
    Test.assertEqualMessage(SaunaRound.settingAt(190), :hr, "near the second row");
    Test.assertMessage(SaunaRound.settingAt(10) == null, "above both rows");
    Test.assertMessage(SaunaRound.settingAt(400) == null, "below both rows");

    SaunaRound._timeRowY = -1;
    SaunaRound._hrRowY = -1;
    Test.assertMessage(SaunaRound.settingAt(110) == null, "no rows drawn yet");

    SaunaRound._timeRowY = savedTimeRow;
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
    var hint = SaunaRound.pageHint("rounds");
    if (SaunaLayout.hasPageButtons()) {
        Test.assertEqualMessage(hint, "DOWN: rounds", "button watches name the DOWN button");
    } else {
        Test.assertEqualMessage(hint, "Tap: rounds", "touch watches say tap");
    }
    return true;
}

(:test)
function eachSessionTypeHasItsPhasesInOrder(logger as Logger) as Boolean {
    var sauna = SaunaTypes.sequence(TYPE_SAUNA);
    Test.assertEqualMessage(sauna.size(), 2, "sauna has two phases");
    Test.assertMessage(sauna[0] == PHASE_SWEAT && sauna[1] == PHASE_REST, "sauna: sweat, rest");

    var both = SaunaTypes.sequence(TYPE_SAUNA_PLUNGE);
    Test.assertEqualMessage(both.size(), 3, "sauna + plunge has three phases");
    Test.assertMessage(both[0] == PHASE_SWEAT && both[1] == PHASE_PLUNGE && both[2] == PHASE_REST, "sauna + plunge: sweat, plunge, rest");

    var plunge = SaunaTypes.sequence(TYPE_PLUNGE);
    Test.assertEqualMessage(plunge.size(), 2, "plunge has two phases");
    Test.assertMessage(plunge[0] == PHASE_PLUNGE && plunge[1] == PHASE_REST, "plunge: plunge, rest");

    Test.assertEqualMessage(SaunaTypes.timedPhase(TYPE_SAUNA), PHASE_SWEAT, "sauna times the sweat");
    Test.assertEqualMessage(SaunaTypes.timedPhase(TYPE_SAUNA_PLUNGE), PHASE_SWEAT, "sauna + plunge times the sweat");
    Test.assertEqualMessage(SaunaTypes.timedPhase(TYPE_PLUNGE), PHASE_PLUNGE, "plunge times the plunge");
    return true;
}

(:test)
function phasesAndSessionTypesHaveTheirOnScreenNames(logger as Logger) as Boolean {
    Test.assertEqualMessage(SaunaTypes.phaseName(PHASE_SWEAT), "Sweat", "sweat");
    Test.assertEqualMessage(SaunaTypes.phaseName(PHASE_PLUNGE), "Plunge", "plunge");
    Test.assertEqualMessage(SaunaTypes.phaseName(PHASE_REST), "Rest", "rest");
    Test.assertEqualMessage(SaunaTypes.typeName(TYPE_SAUNA), "Sauna", "sauna");
    Test.assertEqualMessage(SaunaTypes.typeName(TYPE_SAUNA_PLUNGE), "Sauna + plunge", "sauna + plunge");
    Test.assertEqualMessage(SaunaTypes.typeName(TYPE_PLUNGE), "Plunge", "plunge");
    // The watch allows about 15 characters in an activity name.
    for (var type = TYPE_SAUNA; type <= TYPE_PLUNGE; type += 1) {
        Test.assertMessage(SaunaTypes.activityName(type).length() <= 15, "the activity name is short enough");
    }
    return true;
}

(:test)
function maxTimeCyclesThroughEveryOptionForEachSessionType(logger as Logger) as Boolean {
    var session = new SaunaSession();
    var savedType = session.getType();
    for (var type = TYPE_SAUNA; type <= TYPE_PLUNGE; type += 1) {
        session.setType(type);
        var options = SaunaTypes.maxTimeOptions(type);
        var start = session.getMaxTimeMin();
        var seen = [start];
        for (var i = 0; i < options.size() - 1; i += 1) {
            session.cycleMaxTime();
            var value = session.getMaxTimeMin();
            Test.assertMessage(options.indexOf(value) >= 0, "every value is one of the options");
            Test.assertMessage(seen.indexOf(value) < 0, "every step is a new value");
            seen.add(value);
        }
        session.cycleMaxTime();
        Test.assertEqualMessage(session.getMaxTimeMin(), start, "wraps back to the start");
    }
    session.setType(savedType);
    return true;
}

(:test)
function plungesGetShorterMaxTimeChoicesThanSweats(logger as Logger) as Boolean {
    Test.assertMessage(SaunaTypes.maxTimeOptions(TYPE_PLUNGE).indexOf(2) >= 0, "a plunge can be limited to 2 minutes");
    Test.assertMessage(SaunaTypes.maxTimeOptions(TYPE_SAUNA).indexOf(2) < 0, "a sauna sweat can't");
    Test.assertMessage(SaunaTypes.maxTimeOptions(TYPE_SAUNA).indexOf(15) >= 0, "a sauna sweat can be limited to 15 minutes");
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
function settingsAreRememberedAndEachSessionTypeKeepsItsOwnMaxTime(logger as Logger) as Boolean {
    var session = new SaunaSession();
    var savedType = session.getType();

    session.setType(TYPE_SAUNA);
    var saunaBefore = session.getMaxTimeMin();
    session.cycleMaxTime();
    var saunaAfter = session.getMaxTimeMin();

    session.setType(TYPE_PLUNGE);
    var plungeBefore = session.getMaxTimeMin();
    session.cycleMaxTime();
    var plungeAfter = session.getMaxTimeMin();

    // A new session starts on the type last chosen and loads that type's setting.
    Test.assertEqualMessage(new SaunaSession().getType(), TYPE_PLUNGE, "the last type is remembered");
    Test.assertEqualMessage(new SaunaSession().getMaxTimeMin(), plungeAfter, "its max time is remembered");

    // Going back to the sauna finds its own setting, untouched by the plunge change.
    session.setType(TYPE_SAUNA);
    Test.assertEqualMessage(session.getMaxTimeMin(), saunaAfter, "the sauna's max time is its own");

    // Put everything back the way it was.
    putMaxTimeBack(session, saunaBefore);
    session.setType(TYPE_PLUNGE);
    putMaxTimeBack(session, plungeBefore);
    session.setType(savedType);
    return true;
}

(:test)
function hrLimitIsRememberedByTheNextSession(logger as Logger) as Boolean {
    var session = new SaunaSession();
    var before = session.getHrLimit();
    session.cycleHrLimit();
    Test.assertEqualMessage(new SaunaSession().getHrLimit(), session.getHrLimit(), "HR limit is saved");
    for (var i = 0; i < HR_LIMIT_OPTIONS.size() - 1 && session.getHrLimit() != before; i += 1) {
        session.cycleHrLimit();
    }
    return true;
}

(:test)
function aFreshSessionIsIdleOnTheFirstPhaseOfItsType(logger as Logger) as Boolean {
    var session = new SaunaSession();
    Test.assertEqualMessage(session.getState(), STATE_IDLE, "starts idle");
    Test.assertEqualMessage(session.currentPhase(), SaunaTypes.sequence(session.getType())[0], "first phase of its type");
    Test.assertEqualMessage(session.roundNumber(), 1, "first round");
    Test.assertEqualMessage(session.timerMs(), 0, "timer at zero");
    Test.assertEqualMessage(session.calories(), 0, "no calories yet");
    return true;
}

(:test)
function movingToTheNextPhaseDoesNothingBeforeTheSessionStarts(logger as Logger) as Boolean {
    var session = new SaunaSession();
    var phase = session.currentPhase();
    session.nextPhase();
    Test.assertEqualMessage(session.currentPhase(), phase, "same phase");
    Test.assertEqualMessage(session.roundNumber(), 1, "still the first round");
    Test.assertEqualMessage(session.getState(), STATE_IDLE, "still idle");
    return true;
}

(:test)
function backStepsThroughThePhasesOfEachTypeAndStartsAnotherRound(logger as Logger) as Boolean {
    var session = new SaunaSession();
    var savedType = session.getType();
    for (var type = TYPE_SAUNA; type <= TYPE_PLUNGE; type += 1) {
        session.setType(type);
        var sequence = SaunaTypes.sequence(type);
        session.start();
        Test.assertEqualMessage(session.currentPhase(), sequence[0], "starts on the first phase");
        Test.assertEqualMessage(session.roundNumber(), 1, "round one");

        // Two full rounds: each step lands on the next phase, and the round count goes up
        // each time the sequence starts over.
        for (var step = 1; step <= sequence.size() * 2; step += 1) {
            session.nextPhase();
            Test.assertEqualMessage(session.currentPhase(), sequence[step % sequence.size()], "the next phase in order");
            Test.assertEqualMessage(session.roundNumber(), 1 + step / sequence.size(), "round number");
        }
        session.discard();
    }
    session.setType(savedType);
    return true;
}

(:test)
function phaseLabelsNameThePhaseAndTheRound(logger as Logger) as Boolean {
    var session = new SaunaSession();
    var savedType = session.getType();
    session.setType(TYPE_SAUNA_PLUNGE);
    session.start();
    Test.assertEqualMessage(session.phaseLabel(), "Sweat 1", "first sweat");
    session.nextPhase();
    Test.assertEqualMessage(session.phaseLabel(), "Plunge 1", "first plunge");
    session.nextPhase();
    Test.assertEqualMessage(session.phaseLabel(), "Rest 1", "first rest");
    session.nextPhase();
    Test.assertEqualMessage(session.phaseLabel(), "Sweat 2", "second sweat");
    session.discard();
    session.setType(savedType);
    return true;
}

(:test)
function theMaxTimeAlertAppliesOnlyToTheTimedPhase(logger as Logger) as Boolean {
    var session = new SaunaSession();
    var savedType = session.getType();

    // Sauna + plunge: only the sweat is timed.
    session.setType(TYPE_SAUNA_PLUNGE);
    var savedTime = session.getMaxTimeMin();
    if (savedTime == 0) {
        session.cycleMaxTime();
    }
    session.start();
    Test.assertMessage(session.showsMaxTime(), "the sweat is timed");
    session.nextPhase();
    Test.assertMessage(!session.showsMaxTime(), "the plunge is not");
    session.nextPhase();
    Test.assertMessage(!session.showsMaxTime(), "the rest is not");
    session.nextPhase();
    Test.assertMessage(session.showsMaxTime(), "the next sweat is timed again");
    session.discard();
    putMaxTimeBack(session, savedTime);

    // Plunge only: the plunge is the timed phase.
    session.setType(TYPE_PLUNGE);
    savedTime = session.getMaxTimeMin();
    if (savedTime == 0) {
        session.cycleMaxTime();
    }
    session.start();
    Test.assertMessage(session.showsMaxTime(), "the plunge is timed");
    session.nextPhase();
    Test.assertMessage(!session.showsMaxTime(), "the rest is not");
    session.discard();
    putMaxTimeBack(session, savedTime);

    session.setType(savedType);
    return true;
}

(:test)
function aSessionCanBeStartedAdvancedStoppedResumedAndDiscarded(logger as Logger) as Boolean {
    var session = new SaunaSession();
    var savedType = session.getType();
    session.setType(TYPE_SAUNA);
    session.start();
    Test.assertEqualMessage(session.getState(), STATE_RECORDING, "recording after start");
    session.nextPhase();
    Test.assertEqualMessage(session.currentPhase(), PHASE_REST, "rest after the sweat");
    session.stop();
    Test.assertEqualMessage(session.getState(), STATE_PAUSED, "paused after stop");
    session.resume();
    Test.assertEqualMessage(session.getState(), STATE_RECORDING, "recording again after resume");
    session.discard();
    Test.assertEqualMessage(session.getState(), STATE_IDLE, "idle after discard");
    Test.assertEqualMessage(session.getLastResult(), "Discarded", "says it was discarded");
    Test.assertEqualMessage(session.currentPhase(), PHASE_SWEAT, "back to the first phase");
    Test.assertEqualMessage(session.roundNumber(), 1, "back to the first round");
    session.setType(savedType);
    return true;
}

(:test)
function typeCanOnlyBeChangedBeforeASessionStarts(logger as Logger) as Boolean {
    var session = new SaunaSession();
    var savedType = session.getType();
    session.setType(TYPE_SAUNA);
    session.start();
    session.setType(TYPE_PLUNGE);
    Test.assertEqualMessage(session.getType(), TYPE_SAUNA, "the type is locked while recording");
    session.discard();
    session.setType(savedType);
    return true;
}

(:test)
function savingGivesASummaryWithEveryPhaseThatRan(logger as Logger) as Boolean {
    var session = new SaunaSession();
    var savedType = session.getType();
    session.setType(TYPE_SAUNA_PLUNGE);
    session.start();
    session.nextPhase();
    session.nextPhase();
    session.nextPhase();
    var summary = session.save();
    if (summary == null) {
        return false;
    }
    // Three moves end sweat, plunge and rest; the empty second sweat is left out.
    Test.assertEqualMessage(summary.kinds.size(), 3, "three phases are listed");
    Test.assertEqualMessage(summary.kinds[0], PHASE_SWEAT, "sweat first");
    Test.assertEqualMessage(summary.kinds[1], PHASE_PLUNGE, "then the plunge");
    Test.assertEqualMessage(summary.kinds[2], PHASE_REST, "then the rest");
    Test.assertEqualMessage(summary.type, TYPE_SAUNA_PLUNGE, "the type travels with the summary");
    Test.assertEqualMessage(summary.rounds(), 1, "one round");
    Test.assertMessage(summary.avgHr == null && summary.maxHr == null, "no heart-rate samples were taken");
    Test.assertEqualMessage(session.getState(), STATE_IDLE, "idle again");
    Test.assertEqualMessage(session.getLastResult(), "Saved", "says it was saved");
    session.setType(savedType);
    return true;
}

(:test)
function summaryTotalsAndRoundsAddUpCorrectly(logger as Logger) as Boolean {
    var summary = new SessionSummary(
        TYPE_SAUNA_PLUNGE,
        600000,
        [PHASE_SWEAT, PHASE_PLUNGE, PHASE_REST, PHASE_SWEAT] as Array<Number>,
        [300000, 60000, 120000, 120000] as Array<Number>,
        null,
        null,
        0
    );
    Test.assertEqualMessage(summary.totalFor(PHASE_SWEAT), 420000, "total sweat");
    Test.assertEqualMessage(summary.totalFor(PHASE_PLUNGE), 60000, "total plunge");
    Test.assertEqualMessage(summary.totalFor(PHASE_REST), 120000, "total rest");
    Test.assertEqualMessage(summary.countFor(PHASE_SWEAT), 2, "two sweats");
    Test.assertEqualMessage(summary.rounds(), 2, "two rounds");
    Test.assertEqualMessage(summary.mainTimes().size(), 2, "one main time per round");
    Test.assertEqualMessage(summary.mainTimes()[1], 120000, "the second sweat");

    var plunges = new SessionSummary(
        TYPE_PLUNGE,
        200000,
        [PHASE_PLUNGE, PHASE_REST, PHASE_PLUNGE] as Array<Number>,
        [90000, 60000, 50000] as Array<Number>,
        null,
        null,
        0
    );
    Test.assertEqualMessage(plunges.rounds(), 2, "plunge rounds count the plunges");
    Test.assertEqualMessage(plunges.mainTimes()[0], 90000, "the first plunge");
    return true;
}
