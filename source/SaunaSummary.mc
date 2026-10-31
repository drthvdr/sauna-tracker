import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Shown after Save. Page 1 has the totals, page 2 the time of each heat. Average
// heart rate goes in the round subscreen on both pages.
class SaunaSummaryView extends WatchUi.View {

    private const MAX_HEAT_ROWS = 5;

    private var _summary as SessionSummary;
    private var _page as Number;

    function initialize(summary as SessionSummary) {
        View.initialize();
        _summary = summary;
        _page = 0;
    }

    function togglePage() as Void {
        _page = 1 - _page;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var box = SaunaLayout.subscreenBox(w);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.clear();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);

        SaunaLayout.drawHeartRate(dc, box, _summary.avgHr, false, "avg");

        if (_page == 0) {
            drawTotals(dc, w, h, box);
        } else {
            drawHeats(dc, w, h, box);
        }
    }

    private function drawTotals(dc as Dc, w as Number, h as Number, box as Array<Number>) as Void {
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var x = box[0] / 2;
        var count = _summary.heatTimes.size();
        var maxHr = _summary.maxHr;

        dc.drawText(x, h * 0.09, Graphics.FONT_XTINY, "Saved", center);
        dc.drawText(x, h * 0.23, Graphics.FONT_XTINY, "DN: " + count + (count == 1 ? " heat" : " heats"), center);

        var totalText = SaunaFormat.duration(_summary.totalMs);
        var totalFont = SaunaLayout.fitFont(dc, totalText, w * 0.9, [
            Graphics.FONT_NUMBER_THAI_HOT,
            Graphics.FONT_NUMBER_MEDIUM,
            Graphics.FONT_NUMBER_MILD
        ] as Array<Graphics.FontType>);
        dc.drawText(w / 2, h * 0.57, totalFont, totalText, center);

        dc.drawText(w * 0.27, h * 0.78, Graphics.FONT_NUMBER_MILD, maxHr != null ? maxHr.toString() : "--", center);
        dc.drawText(w * 0.27, h * 0.90, Graphics.FONT_XTINY, "max HR", center);
        dc.drawText(w * 0.73, h * 0.78, Graphics.FONT_NUMBER_MILD, _summary.calories.toString(), center);
        dc.drawText(w * 0.73, h * 0.90, Graphics.FONT_XTINY, "kcal", center);
    }

    private function drawHeats(dc as Dc, w as Number, h as Number, box as Array<Number>) as Void {
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var x = box[0] / 2;
        var heats = _summary.heatTimes;

        dc.drawText(x, h * 0.09, Graphics.FONT_XTINY, "Heats", center);
        dc.drawText(x, h * 0.23, Graphics.FONT_XTINY, "DN: totals", center);

        // With more heats than rows, the last row says how many are not shown.
        var shown = heats.size() > MAX_HEAT_ROWS ? MAX_HEAT_ROWS - 1 : heats.size();
        for (var i = 0; i < shown; i += 1) {
            var line = (i + 1).toString() + "   " + SaunaFormat.duration(heats[i]);
            dc.drawText(w / 2, h * (0.42 + 0.12 * i), Graphics.FONT_TINY, line, center);
        }
        if (shown < heats.size()) {
            var more = heats.size() - shown;
            dc.drawText(w / 2, h * (0.42 + 0.12 * shown), Graphics.FONT_XTINY, "+" + more + " more", center);
        }
    }
}

class SaunaSummaryDelegate extends WatchUi.BehaviorDelegate {

    private var _view as SaunaSummaryView;

    function initialize(view as SaunaSummaryView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onNextPage() as Boolean {
        _view.togglePage();
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.togglePage();
        return true;
    }

    function onSelect() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}
