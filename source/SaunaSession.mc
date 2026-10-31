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

// 0 means the alert is off.
const HEAT_ALERT_OPTIONS = [0, 5, 10, 15, 20, 25, 30] as Array<Number>;
const HR_LIMIT_OPTIONS = [0, 120, 130, 140, 150, 160, 170, 180] as Array<Number>;
const HR_ALERT_REPEAT_MS = 60000;

// What the post-save summary screens show.
class SessionSummary {
    var totalMs as Number;
    var heatTimes as Array<Number>;
    var avgHr as Number?;
    var maxHr as Number?;
    var calories as Number;

    function initialize(totalMs as Number, heatTimes as Array<Number>, avgHr as Number?, maxHr as Number?, calories as Number) {
        self.totalMs = totalMs;
        self.heatTimes = heatTimes;
        self.avgHr = avgHr;
        self.maxHr = maxHr;
        self.calories = calories;
    }
}

// Wraps the FIT recording session. Heart rate and calories are written to the
// FIT file by the device itself while the session is running; the getters here
// are only for the on-screen display, the alerts and the summary.
class SaunaSession {

    private var _session as ActivityRecording.Session?;
    private var _ticker as Timer.Timer;
    private var _state as Number;
    private var _heatTimes as Array<Number>;
    private var _accumMs as Number;
    private var _resumedAt as Number;
    private var _heatStartMs as Number;
    private var _lastResult as String;

    private var _heatAlertMin as Number;
    private var _hrLimit as Number;
    private var _heatAlerted as Boolean;
    private var _hrHigh as Boolean;
    private var _lastHrAlertAt as Number;

    private var _hrSum as Number;
    private var _hrCount as Number;
    private var _hrMax as Number;

    function initialize() {
        _session = null;
        _ticker = new Timer.Timer();
        _state = STATE_IDLE;
        _heatTimes = [] as Array<Number>;
        _accumMs = 0;
        _resumedAt = 0;
        _heatStartMs = 0;
        _lastResult = "";

        _heatAlertMin = loadSetting("heatAlertMin");
        _hrLimit = loadSetting("hrLimit");
        _heatAlerted = false;
        _hrHigh = false;
        _lastHrAlertAt = -HR_ALERT_REPEAT_MS;

        _hrSum = 0;
        _hrCount = 0;
        _hrMax = 0;
    }

    function getState() as Number {
        return _state;
    }

    function getLastResult() as String {
        return _lastResult;
    }

    function getHeatAlertMin() as Number {
        return _heatAlertMin;
    }

    function getHrLimit() as Number {
        return _hrLimit;
    }

    function isHrHigh() as Boolean {
        return _hrHigh;
    }

    // Alert settings are picked on the idle screen with UP and DOWN.
    function cycleHeatAlert() as Void {
        if (_state != STATE_IDLE) {
            return;
        }
        _heatAlertMin = nextOption(HEAT_ALERT_OPTIONS, _heatAlertMin);
        Application.Storage.setValue("heatAlertMin", _heatAlertMin);
    }

    function cycleHrLimit() as Void {
        if (_state != STATE_IDLE) {
            return;
        }
        _hrLimit = nextOption(HR_LIMIT_OPTIONS, _hrLimit);
        Application.Storage.setValue("hrLimit", _hrLimit);
    }

    function start() as Void {
        // There is no sauna sport type. Training/Cardio records time + HR with no
        // distance; SPORT_GENERIC shows up in Garmin Connect as a distance activity.
        var session = ActivityRecording.createSession({
            :name => "Sauna",
            :sport => Activity.SPORT_TRAINING,
            :subSport => Activity.SUB_SPORT_CARDIO_TRAINING
        });
        _session = session;
        session.start();

        _state = STATE_RECORDING;
        _heatTimes = [] as Array<Number>;
        _accumMs = 0;
        _heatStartMs = 0;
        _resumedAt = System.getTimer();
        _lastResult = "";
        _heatAlerted = false;
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

    // Ends the current heat and starts the next one. In the FIT file it is a lap.
    function markHeat() as Void {
        var session = _session;
        if (session == null || _state != STATE_RECORDING) {
            return;
        }
        session.addLap();
        _heatTimes.add(heatMs());
        _heatStartMs = timerMs();
        _heatAlerted = false;
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

        if (_heatAlertMin > 0 && !_heatAlerted && heatMs() >= _heatAlertMin * 60000) {
            _heatAlerted = true;
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

    function heatMs() as Number {
        return timerMs() - _heatStartMs;
    }

    function heatNumber() as Number {
        return _heatTimes.size() + 1;
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
        // The heat in progress counts, unless one was marked a moment ago.
        var heats = _heatTimes.slice(null, null);
        if (heats.size() == 0 || heatMs() >= 1000) {
            heats.add(heatMs());
        }

        var avgHr = null as Number?;
        var maxHr = null as Number?;
        if (_hrCount > 0) {
            avgHr = _hrSum / _hrCount;
            maxHr = _hrMax;
        }
        return new SessionSummary(timerMs(), heats, avgHr, maxHr, calories());
    }

    private function reset(result as String) as Void {
        _session = null;
        _state = STATE_IDLE;
        _heatTimes = [] as Array<Number>;
        _accumMs = 0;
        _heatStartMs = 0;
        _hrHigh = false;
        _lastResult = result;
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
