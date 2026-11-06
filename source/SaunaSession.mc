import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Application;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.Sensor;
import Toybox.System;
import Toybox.Timer;

enum {
    STATE_IDLE,
    STATE_RECORDING,
    STATE_PAUSED
}

// The kind of session, picked when the app opens, and the phases it cycles through.
enum {
    TYPE_SAUNA,
    TYPE_SAUNA_PLUNGE,
    TYPE_PLUNGE
}

enum {
    PHASE_SWEAT,
    PHASE_PLUNGE,
    PHASE_REST
}

// 0 means the alert is off. Plunges are short, so they get shorter choices.
const MAX_TIME_OPTIONS_SAUNA = [0, 5, 10, 15, 20, 25, 30] as Array<Number>;
const MAX_TIME_OPTIONS_PLUNGE = [0, 1, 2, 3, 4, 5, 10] as Array<Number>;
const HR_LIMIT_OPTIONS = [0, 120, 130, 140, 150, 160, 170, 180] as Array<Number>;
const HR_ALERT_REPEAT_MS = 60000;

// What the post-save summary screens show.
class SessionSummary {
    var type as Number;
    var totalMs as Number;
    var kinds as Array<Number>;
    var times as Array<Number>;
    var avgHr as Number?;
    var maxHr as Number?;
    var calories as Number;

    // kinds[i] and times[i] are the kind and the length of the i-th phase, in order.
    function initialize(type as Number, totalMs as Number, kinds as Array<Number>, times as Array<Number>, avgHr as Number?, maxHr as Number?, calories as Number) {
        self.type = type;
        self.totalMs = totalMs;
        self.kinds = kinds;
        self.times = times;
        self.avgHr = avgHr;
        self.maxHr = maxHr;
        self.calories = calories;
    }

    function totalFor(kind as Number) as Number {
        var total = 0;
        for (var i = 0; i < kinds.size(); i += 1) {
            if (kinds[i] == kind) {
                total += times[i];
            }
        }
        return total;
    }

    function countFor(kind as Number) as Number {
        var count = 0;
        for (var i = 0; i < kinds.size(); i += 1) {
            if (kinds[i] == kind) {
                count += 1;
            }
        }
        return count;
    }

    // How many times the cycle was started: one per first-phase, in the type's order.
    function rounds() as Number {
        return countFor(SaunaTypes.sequence(type)[0]);
    }

    // How long each round's main phase lasted (the sweat, or the plunge in a plunge-only session).
    function mainTimes() as Array<Number> {
        var main = SaunaTypes.timedPhase(type);
        var result = [] as Array<Number>;
        for (var i = 0; i < kinds.size(); i += 1) {
            if (kinds[i] == main) {
                result.add(times[i]);
            }
        }
        return result;
    }
}

// Wraps the FIT recording session. Heart rate and calories are written to the
// FIT file by the device itself while the session is running; the getters here
// are only for the on-screen display, the alerts and the summary.
class SaunaSession {

    private var _session as ActivityRecording.Session?;
    private var _ticker as Timer.Timer;
    private var _state as Number;
    private var _type as Number;
    private var _phaseIndex as Number;
    private var _round as Number;
    private var _kinds as Array<Number>;
    private var _times as Array<Number>;
    private var _accumMs as Number;
    private var _resumedAt as Number;
    private var _phaseStartMs as Number;
    private var _lastResult as String;

    private var _maxTimeMin as Number;
    private var _hrLimit as Number;
    private var _timeAlerted as Boolean;
    private var _hrHigh as Boolean;
    private var _lastHrAlertAt as Number;

    private var _hrSum as Number;
    private var _hrCount as Number;
    private var _hrMax as Number;

    function initialize() {
        _session = null;
        _ticker = new Timer.Timer();
        _state = STATE_IDLE;
        _type = loadType();
        _phaseIndex = 0;
        _round = 1;
        _kinds = [] as Array<Number>;
        _times = [] as Array<Number>;
        _accumMs = 0;
        _resumedAt = 0;
        _phaseStartMs = 0;
        _lastResult = "";

        _maxTimeMin = loadMaxTime(_type);
        _hrLimit = loadSetting("hrLimit");
        _timeAlerted = false;
        _hrHigh = false;
        _lastHrAlertAt = -HR_ALERT_REPEAT_MS;

        _hrSum = 0;
        _hrCount = 0;
        _hrMax = 0;
    }

    function getState() as Number {
        return _state;
    }

    function getType() as Number {
        return _type;
    }

    function typeName() as String {
        return SaunaTypes.typeName(_type);
    }

    // Changes the session type. Only possible before a session starts; each type
    // remembers its own max time.
    function setType(type as Number) as Void {
        if (_state != STATE_IDLE) {
            return;
        }
        _type = type;
        _phaseIndex = 0;
        _round = 1;
        _maxTimeMin = loadMaxTime(type);
        Application.Storage.setValue("sessionType", type);
    }

    function getLastResult() as String {
        return _lastResult;
    }

    function getMaxTimeMin() as Number {
        return _maxTimeMin;
    }

    function getHrLimit() as Number {
        return _hrLimit;
    }

    function isHrHigh() as Boolean {
        return _hrHigh;
    }

    // The settings are picked on the idle screen with UP and DOWN (or by tapping).
    function cycleMaxTime() as Void {
        if (_state != STATE_IDLE) {
            return;
        }
        _maxTimeMin = nextOption(SaunaTypes.maxTimeOptions(_type), _maxTimeMin);
        Application.Storage.setValue("maxTime" + _type, _maxTimeMin);
    }

    function cycleHrLimit() as Void {
        if (_state != STATE_IDLE) {
            return;
        }
        _hrLimit = nextOption(HR_LIMIT_OPTIONS, _hrLimit);
        Application.Storage.setValue("hrLimit", _hrLimit);
    }

    // The phase in progress (or the one a session will start in).
    function currentPhase() as Number {
        return SaunaTypes.sequence(_type)[_phaseIndex];
    }

    function phaseName() as String {
        return SaunaTypes.phaseName(currentPhase());
    }

    function roundNumber() as Number {
        return _round;
    }

    // For example "Sweat 2".
    function phaseLabel() as String {
        return phaseName() + " " + _round;
    }

    // True while the max-time alert applies to the phase in progress.
    function showsMaxTime() as Boolean {
        return _maxTimeMin > 0 && currentPhase() == SaunaTypes.timedPhase(_type);
    }

    function start() as Void {
        // There is no sauna sport type. Training/Cardio records time + HR with no
        // distance; SPORT_GENERIC shows up in Garmin Connect as a distance activity.
        var session = ActivityRecording.createSession({
            :name => SaunaTypes.activityName(_type),
            :sport => Activity.SPORT_TRAINING,
            :subSport => Activity.SUB_SPORT_CARDIO_TRAINING
        });
        _session = session;
        session.start();

        _state = STATE_RECORDING;
        _phaseIndex = 0;
        _round = 1;
        _kinds = [] as Array<Number>;
        _times = [] as Array<Number>;
        _accumMs = 0;
        _phaseStartMs = 0;
        _resumedAt = System.getTimer();
        _lastResult = "";
        _timeAlerted = false;
        _hrHigh = false;
        _lastHrAlertAt = -HR_ALERT_REPEAT_MS;
        _hrSum = 0;
        _hrCount = 0;
        _hrMax = 0;
        _ticker.start(method(:tick), 1000, true);
        buzz(150);
    }

    function stop() as Void {
        if (_state != STATE_RECORDING) {
            return;
        }
        freeze();
        buzz(150);
    }

    function resume() as Void {
        var session = _session;
        if (session == null || _state != STATE_PAUSED) {
            return;
        }
        session.start();
        _resumedAt = System.getTimer();
        _state = STATE_RECORDING;
        _ticker.start(method(:tick), 1000, true);
        buzz(150);
    }

    // Ends the phase in progress and starts the next one, wrapping around after the last
    // (sweat, rest; or sweat, plunge, rest; or plunge, rest). In the FIT file it is a lap.
    function nextPhase() as Void {
        var session = _session;
        if (session == null || _state != STATE_RECORDING) {
            return;
        }
        session.addLap();
        _kinds.add(currentPhase());
        _times.add(phaseMs());
        _phaseIndex = (_phaseIndex + 1) % SaunaTypes.sequence(_type).size();
        if (_phaseIndex == 0) {
            _round += 1;
        }
        _phaseStartMs = timerMs();
        _timeAlerted = false;
        buzz(80);
    }

    // Returns the numbers for the summary screen, or null if nothing was recorded.
    function save() as SessionSummary? {
        var session = _session;
        if (session == null) {
            return null;
        }
        freeze();
        // Build the summary before saving, while the live activity data (calories)
        // is still available.
        var summary = buildSummary();
        session.save();
        reset("Saved");
        buzz(300);
        return summary;
    }

    function discard() as Void {
        var session = _session;
        if (session == null) {
            return;
        }
        freeze();
        session.discard();
        reset("Discarded");
    }

    function saveIfActive() as Void {
        if (_state != STATE_IDLE) {
            save();
        }
    }

    // Runs once a second while recording: HR stats and the two alerts.
    function tick() as Void {
        if (_state != STATE_RECORDING) {
            return;
        }

        var hr = heartRate();
        _hrHigh = false;
        if (hr != null) {
            _hrSum += hr;
            _hrCount += 1;
            if (hr > _hrMax) {
                _hrMax = hr;
            }
            if (_hrLimit > 0 && hr >= _hrLimit) {
                _hrHigh = true;
                var now = System.getTimer();
                if (now - _lastHrAlertAt >= HR_ALERT_REPEAT_MS) {
                    _lastHrAlertAt = now;
                    playVibration([
                        new Attention.VibeProfile(100, 200),
                        new Attention.VibeProfile(0, 100),
                        new Attention.VibeProfile(100, 200)
                    ] as Array<Attention.VibeProfile>);
                }
            }
        }

        if (!_timeAlerted && showsMaxTime() && phaseMs() >= _maxTimeMin * 60000) {
            _timeAlerted = true;
            playVibration([
                new Attention.VibeProfile(100, 400),
                new Attention.VibeProfile(0, 150),
                new Attention.VibeProfile(100, 400),
                new Attention.VibeProfile(0, 150),
                new Attention.VibeProfile(100, 400)
            ] as Array<Attention.VibeProfile>);
        }
    }

    // Timer time excludes stopped time, like the built-in activities.
    function timerMs() as Number {
        if (_state == STATE_RECORDING) {
            return _accumMs + (System.getTimer() - _resumedAt);
        }
        return _accumMs;
    }

    function phaseMs() as Number {
        return timerMs() - _phaseStartMs;
    }

    function heartRate() as Number? {
        var info = Activity.getActivityInfo();
        if (info != null && info.currentHeartRate != null) {
            return info.currentHeartRate;
        }
        return Sensor.getInfo().heartRate;
    }

    function calories() as Number {
        if (_state == STATE_IDLE) {
            return 0;
        }
        var info = Activity.getActivityInfo();
        if (info != null && info.calories != null) {
            return info.calories;
        }
        return 0;
    }

    // Stops the FIT timer and our own clock. Does nothing unless recording.
    private function freeze() as Void {
        var session = _session;
        if (session == null || _state != STATE_RECORDING) {
            return;
        }
        session.stop();
        _ticker.stop();
        _accumMs = timerMs();
        _state = STATE_PAUSED;
        _hrHigh = false;
    }

    private function buildSummary() as SessionSummary {
        // The phase in progress counts, unless one was started a moment ago.
        var kinds = _kinds.slice(null, null);
        var times = _times.slice(null, null);
        if (kinds.size() == 0 || phaseMs() >= 1000) {
            kinds.add(currentPhase());
            times.add(phaseMs());
        }

        var avgHr = null as Number?;
        var maxHr = null as Number?;
        if (_hrCount > 0) {
            avgHr = _hrSum / _hrCount;
            maxHr = _hrMax;
        }
        return new SessionSummary(_type, timerMs(), kinds, times, avgHr, maxHr, calories());
    }

    private function reset(result as String) as Void {
        _session = null;
        _state = STATE_IDLE;
        _phaseIndex = 0;
        _round = 1;
        _kinds = [] as Array<Number>;
        _times = [] as Array<Number>;
        _accumMs = 0;
        _phaseStartMs = 0;
        _hrHigh = false;
        _lastResult = result;
    }

    private function loadType() as Number {
        var value = Application.Storage.getValue("sessionType");
        if (value instanceof Number && value >= TYPE_SAUNA && value <= TYPE_PLUNGE) {
            return value;
        }
        return TYPE_SAUNA;
    }

    // Each session type keeps its own max time. A saved value that is no longer one of the
    // choices counts as off.
    private function loadMaxTime(type as Number) as Number {
        var value = loadSetting("maxTime" + type);
        return SaunaTypes.maxTimeOptions(type).indexOf(value) >= 0 ? value : 0;
    }

    private function loadSetting(key as String) as Number {
        var value = Application.Storage.getValue(key);
        if (value instanceof Number) {
            return value;
        }
        return 0;
    }

    private function nextOption(options as Array<Number>, current as Number) as Number {
        var index = options.indexOf(current);
        return options[(index + 1) % options.size()];
    }

    private function buzz(ms as Number) as Void {
        playVibration([new Attention.VibeProfile(50, ms)] as Array<Attention.VibeProfile>);
    }

    private function playVibration(pattern as Array<Attention.VibeProfile>) as Void {
        if (Attention has :vibrate) {
            Attention.vibrate(pattern);
        }
    }
}
