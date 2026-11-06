import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Shown after Save, in three pages: the totals, the time spent in each kind of phase, and the
// time of each round. Average heart rate goes in the round subscreen on every page.
const SUMMARY_PAGES = 3;

class SaunaSummaryView extends WatchUi.View {

    private const MAX_ROWS = 5;

    private var _summary as SessionSummary;
    private var _page as Number;

    function initialize(summary as SessionSummary) {
        View.initialize();
        _summary = summary;
        _page = 0;
    }

    // delta is 1 for the next page and -1 for the previous one; the pages wrap around.
    function turnPage(delta as Number) as Void {
        _page = (_page + delta + SUMMARY_PAGES) % SUMMARY_PAGES;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var box = SaunaLayout.subscreenBox();
        if (box == null) {
            SaunaRound.drawSummary(dc, _summary, _page);
            return;
        }

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.clear();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);

        SaunaLayout.drawHeartRate(dc, box, _summary.avgHr, false, "avg");

        if (_page == 0) {
            drawTotals(dc, w, h, box);
        } else if (_page == 1) {
            drawPhases(dc, w, h, box);
        } else {
            drawRounds(dc, w, h, box);
        }
    }

    // Title and a second line in the space left of the heart-rate circle.
    private function drawTitle(dc as Dc, box as Array<Number>, h as Number, title as String, second as String) as Void {
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.drawText(box[0] / 2, h * 0.09, Graphics.FONT_XTINY, title + " " + (_page + 1) + "/" + SUMMARY_PAGES, center);
        dc.drawText(box[0] / 2, h * 0.23, Graphics.FONT_XTINY, second, center);
    }

    private function drawTotals(dc as Dc, w as Number, h as Number, box as Array<Number>) as Void {
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var rounds = _summary.rounds();
        var maxHr = _summary.maxHr;

        drawTitle(dc, box, h, "Saved", rounds + (rounds == 1 ? " round" : " rounds"));

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

    // Total time in each kind of phase this session type has, for example "Plunge  6:30".
    private function drawPhases(dc as Dc, w as Number, h as Number, box as Array<Number>) as Void {
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var kinds = SaunaTypes.sequence(_summary.type);

        drawTitle(dc, box, h, "Phases", SaunaTypes.typeName(_summary.type));

        for (var i = 0; i < kinds.size(); i += 1) {
            var line = SaunaTypes.phaseName(kinds[i]) + "  " + SaunaFormat.duration(_summary.totalFor(kinds[i]));
            dc.drawText(w / 2, h * (0.46 + 0.14 * i), Graphics.FONT_TINY, line, center);
        }
    }

    // The main phase (sweat, or plunge in a plunge-only session) of each round.
    private function drawRounds(dc as Dc, w as Number, h as Number, box as Array<Number>) as Void {
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var times = _summary.mainTimes();

        drawTitle(dc, box, h, "Rounds", SaunaTypes.phaseName(SaunaTypes.timedPhase(_summary.type)) + " times");

        // With more rounds than rows, the last row says how many are not shown.
        var shown = times.size() > MAX_ROWS ? MAX_ROWS - 1 : times.size();
        for (var i = 0; i < shown; i += 1) {
            var line = (i + 1).toString() + "   " + SaunaFormat.duration(times[i]);
            dc.drawText(w / 2, h * (0.42 + 0.12 * i), Graphics.FONT_TINY, line, center);
        }
        if (shown < times.size()) {
            var more = times.size() - shown;
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

    // A stray tap or swipe must not close the summary, so touch never closes it. On a watch
    // with no UP/DOWN buttons (vivoactive 5) a tap or an up swipe turns to the next page and
    // a down swipe to the previous one.
    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        if (!SaunaLayout.hasPageButtons()) {
            _view.turnPage(1);
        }
        return true;
    }

    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        if (!SaunaLayout.hasPageButtons()) {
            var direction = evt.getDirection();
            if (direction == WatchUi.SWIPE_UP) {
                _view.turnPage(1);
            } else if (direction == WatchUi.SWIPE_DOWN) {
                _view.turnPage(-1);
            }
        }
        return true;
    }

    // DOWN turns to the next page, UP to the previous one.
    function onNextPage() as Boolean {
        _view.turnPage(1);
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.turnPage(-1);
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
