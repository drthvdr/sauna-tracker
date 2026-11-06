import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// Layout on the Instinct: heart rate sits in the round subscreen at the top right,
// with the status and calories to its left. The session timer is the big number in
// the middle and the current phase (sweat, plunge or rest) is on the bottom line.
// Watches without a subscreen use SaunaRound instead.
class SaunaView extends WatchUi.View {

    private var _session as SaunaSession;
    private var _timer as Timer.Timer;

    function initialize(session as SaunaSession) {
        View.initialize();
        _session = session;
        _timer = new Timer.Timer();
    }

    function onShow() as Void {
        _timer.start(method(:onTick), 1000, true);
    }

    function onHide() as Void {
        _timer.stop();
    }

    function onTick() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var state = _session.getState();
        var box = SaunaLayout.subscreenBox();
        if (box == null) {
            SaunaRound.drawMain(dc, _session);
            return;
        }

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.clear();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);

        SaunaLayout.drawHeartRate(dc, box, _session.heartRate(), _session.isHrHigh(), "bpm");
        drawStatus(dc, w, h, box, state);

        var timerText = SaunaFormat.duration(_session.timerMs());
        var timerFont = SaunaLayout.fitFont(dc, timerText, w * 0.9, [
            Graphics.FONT_NUMBER_THAI_HOT,
            Graphics.FONT_NUMBER_MEDIUM,
            Graphics.FONT_NUMBER_MILD
        ] as Array<Graphics.FontType>);
        dc.drawText(w / 2, h * 0.57, timerFont, timerText, center);

        if (state == STATE_IDLE) {
            drawIdleRows(dc, w, h);
        } else {
            drawPhaseRow(dc, w, h);
        }
    }

    // Left of the heart-rate circle: the session type (or what just happened), then
    // calories (or the start hint before a session).
    private function drawStatus(dc as Dc, w as Number, h as Number, box as Array<Number>, state as Number) as Void {
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var x = box[0] / 2;

        var text = _session.typeName();
        if (state == STATE_PAUSED) {
            text = "Stopped";
        } else if (state == STATE_IDLE && !_session.getLastResult().equals("")) {
            text = _session.getLastResult();
        }
        dc.drawText(x, h * 0.09, Graphics.FONT_XTINY, text, center);

        if (state == STATE_IDLE) {
            dc.drawText(x, h * 0.23, Graphics.FONT_XTINY, "GPS: start", center);
        } else {
            dc.drawText(x, h * 0.23, Graphics.FONT_SMALL, _session.calories().toString() + " kcal", center);
        }
    }

    // The phase in progress with its time, against the max time while that applies,
    // for example "Sweat 2  3:41 / 15m" or "Rest 2  1:05".
    private function drawPhaseRow(dc as Dc, w as Number, h as Number) as Void {
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        var text = _session.phaseLabel() + "  " + SaunaFormat.duration(_session.phaseMs());
        if (_session.showsMaxTime()) {
            text = text + " / " + _session.getMaxTimeMin() + "m";
        }
        var font = SaunaLayout.fitFont(dc, text, w * 0.92, [
            Graphics.FONT_SMALL,
            Graphics.FONT_XTINY
        ] as Array<Graphics.FontType>);
        dc.drawText(w / 2, h * 0.84, font, text, center);
    }

    // Idle: the two settings, changed with UP and DOWN.
    private function drawIdleRows(dc as Dc, w as Number, h as Number) as Void {
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        var minutes = _session.getMaxTimeMin();
        var hrLimit = _session.getHrLimit();
        var timeText = "UP: max time " + (minutes > 0 ? minutes.toString() + "m" : "off");
        var hrText = "DN: max HR " + (hrLimit > 0 ? hrLimit.toString() : "off");

        dc.drawText(w / 2, h * 0.80, Graphics.FONT_XTINY, timeText, center);
        dc.drawText(w / 2, h * 0.91, Graphics.FONT_XTINY, hrText, center);
    }
}
