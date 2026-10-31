import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// Layout: heart rate sits in the round subscreen at the top right, with the
// status and calories to its left. The session timer is the big number in the
// middle and the current heat is on the bottom line.
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
        var box = SaunaLayout.subscreenBox(w);

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
            drawHeatRow(dc, w, h);
        }
    }

    // Left of the heart-rate circle: what the app is doing, then calories (or the
    // start hint before a session).
    private function drawStatus(dc as Dc, w as Number, h as Number, box as Array<Number>, state as Number) as Void {
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var x = box[0] / 2;

        var text = "Sauna";
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

    // Current heat number and time, against the heat alert if one is set.
    private function drawHeatRow(dc as Dc, w as Number, h as Number) as Void {
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        var text = "Heat " + _session.heatNumber() + "  " + SaunaFormat.duration(_session.heatMs());
        var target = _session.getHeatAlertMin();
        if (target > 0) {
            text = text + " / " + target + "m";
        }
        var font = SaunaLayout.fitFont(dc, text, w * 0.92, [
            Graphics.FONT_SMALL,
            Graphics.FONT_XTINY
        ] as Array<Graphics.FontType>);
        dc.drawText(w / 2, h * 0.84, font, text, center);
    }

    // Idle: the two alert settings, changed with UP and DOWN.
    private function drawIdleRows(dc as Dc, w as Number, h as Number) as Void {
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        var heatMin = _session.getHeatAlertMin();
        var hrLimit = _session.getHrLimit();
        var heatText = "UP: heat " + (heatMin > 0 ? heatMin.toString() + " min" : "off");
        var hrText = "DN: HR max " + (hrLimit > 0 ? hrLimit.toString() : "off");

        dc.drawText(w / 2, h * 0.80, Graphics.FONT_XTINY, heatText, center);
        dc.drawText(w / 2, h * 0.91, Graphics.FONT_XTINY, hrText, center);
    }
}
