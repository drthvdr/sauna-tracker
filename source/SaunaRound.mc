import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

// Screens for watches without a subscreen, such as the Forerunner 965: dark
// background, everything centered, fonts picked to fit. Rows are spread evenly down
// the screen and kept inside the visible circle.
module SaunaRound {

    // Where the two setting rows were last drawn, so a tap can be matched to one.
    var _timeRowY = -1;
    var _hrRowY = -1;

    // Font sets from largest to smallest. Index 0 status, 1 heart rate, 2 timer, 3 detail rows.
    function fontSets() as Array {
        return [
            [Graphics.FONT_TINY, Graphics.FONT_NUMBER_HOT, Graphics.FONT_NUMBER_THAI_HOT, Graphics.FONT_SMALL],
            [Graphics.FONT_XTINY, Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_NUMBER_HOT, Graphics.FONT_TINY],
            [Graphics.FONT_XTINY, Graphics.FONT_NUMBER_MILD, Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_XTINY]
        ];
    }

    // The largest font set whose rows fit in the available height. rowIdx lists, top
    // to bottom, which font (0 to 3) each row uses.
    function pickFonts(dc as Dc, rowIdx as Array<Number>, available as Numeric) as Array {
        var sets = fontSets();
        for (var s = 0; s < sets.size() - 1; s += 1) {
            if (sumHeights(dc, sets[s], rowIdx) <= available * 0.92) {
                return sets[s];
            }
        }
        return sets[sets.size() - 1];
    }

    function sumHeights(dc as Dc, fonts as Array, rowIdx as Array<Number>) as Number {
        var total = 0;
        for (var i = 0; i < rowIdx.size(); i += 1) {
            total += dc.getFontHeight(fonts[rowIdx[i]]);
        }
        return total;
    }

    // Vertical center of each row, spread evenly between top and bottom.
    function rowCenters(dc as Dc, fonts as Array, rowIdx as Array<Number>, top as Numeric, bottom as Numeric) as Array {
        var gap = (bottom - top - sumHeights(dc, fonts, rowIdx)) / (rowIdx.size() + 1);
        if (gap < 0) {
            gap = 0;
        }
        var centers = [];
        var y = top + gap;
        for (var i = 0; i < rowIdx.size(); i += 1) {
            var rowHeight = dc.getFontHeight(fonts[rowIdx[i]]);
            centers.add(y + rowHeight / 2);
            y += rowHeight + gap;
        }
        return centers;
    }

    // Width of the visible screen at height y: the full width on a rectangular
    // screen, the chord of the circle on a round one.
    function chordWidth(w as Number, y as Numeric) as Numeric {
        if (System.getDeviceSettings().screenShape != System.SCREEN_SHAPE_ROUND) {
            return w;
        }
        var r = w / 2.0;
        var dy = y - r;
        var half = r * r - dy * dy;
        return half > 0 ? 2 * Math.sqrt(half) : 0;
    }

    function drawCentered(dc as Dc, x as Numeric, y as Numeric, font as Graphics.FontType, text as String, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Draws text in the largest of the fonts that fits the screen width at height y.
    function drawFitted(dc as Dc, w as Number, y as Numeric, fonts as Array<Graphics.FontType>, text as String, color as Number) as Void {
        var font = SaunaLayout.fitFont(dc, text, chordWidth(w, y) * 0.9, fonts);
        drawCentered(dc, w / 2, y, font, text, color);
    }

    // Which setting row a tap at height y landed on, if any. Each row's touch target
    // runs halfway to the next one.
    function settingAt(y as Numeric) as Symbol? {
        if (_timeRowY < 0 || _hrRowY <= _timeRowY) {
            return null;
        }
        var half = (_hrRowY - _timeRowY) / 2.0;
        if ((y - _timeRowY).abs() <= half) {
            return :time;
        }
        if ((y - _hrRowY).abs() <= half) {
            return :hr;
        }
        return null;
    }

    // Hint for flipping summary pages: a button on watches that have one, else a tap.
    function pageHint(what as String) as String {
        return (SaunaLayout.hasPageButtons() ? "DOWN: " : "Tap: ") + what;
    }

    // Sweat is orange, a cold plunge blue, rest gray.
    function phaseColor(kind as Number) as Number {
        if (kind == PHASE_PLUNGE) {
            return Graphics.COLOR_BLUE;
        }
        return kind == PHASE_REST ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_ORANGE;
    }

    function statusText(session as SaunaSession, state as Number) as String {
        if (state == STATE_PAUSED) {
            return "Stopped";
        }
        if (state == STATE_IDLE && !session.getLastResult().equals("")) {
            return session.getLastResult();
        }
        return session.typeName();
    }

    // The recording screen: status, heart rate, session timer, then the phase in progress
    // and calories. Before starting, the detail rows show the two settings instead.
    function drawMain(dc as Dc, session as SaunaSession) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var state = session.getState();
        var idle = state == STATE_IDLE;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        // The settings screen has no timer: a 0:00 there says nothing and takes the room
        // the settings rows need on the smaller screens.
        var rows = (idle ? [0, 1, 3, 3, 3] : [0, 1, 2, 3, 3]) as Array<Number>;
        var top = h * 0.08;
        var bottom = h * 0.92;
        var fonts = pickFonts(dc, rows, bottom - top);
        var ys = rowCenters(dc, fonts, rows, top, bottom);
        var detailFonts = [fonts[3], Graphics.FONT_XTINY] as Array<Graphics.FontType>;
        _timeRowY = -1;
        _hrRowY = -1;

        drawCentered(dc, w / 2, ys[0], fonts[0], statusText(session, state), Graphics.COLOR_LT_GRAY);
        drawHeartRate(dc, w, ys[1], fonts[1], fonts[3], session.heartRate(), session.isHrHigh());

        if (idle) {
            var minutes = session.getMaxTimeMin();
            var hrLimit = session.getHrLimit();
            var buttons = SaunaLayout.hasPageButtons();
            var timeValue = minutes > 0 ? minutes.toString() + " min" : "off";
            var hrValue = hrLimit > 0 ? hrLimit.toString() : "off";
            drawFitted(dc, w, ys[2], detailFonts, (buttons ? "UP: max time " : "Max time: ") + timeValue, Graphics.COLOR_ORANGE);
            drawFitted(dc, w, ys[3], detailFonts, (buttons ? "DOWN: max HR " : "Max HR: ") + hrValue, Graphics.COLOR_LT_GRAY);
            drawFitted(dc, w, ys[4], detailFonts, buttons ? "START to begin" : "Tap a setting. START to begin", Graphics.COLOR_LT_GRAY);
            _timeRowY = ys[2];
            _hrRowY = ys[3];
            return;
        }

        var timerText = SaunaFormat.duration(session.timerMs());
        var timerFont = SaunaLayout.fitFont(dc, timerText, chordWidth(w, ys[2]) * 0.85, [
            fonts[2],
            Graphics.FONT_NUMBER_HOT,
            Graphics.FONT_NUMBER_MEDIUM,
            Graphics.FONT_NUMBER_MILD
        ] as Array<Graphics.FontType>);
        drawCentered(dc, w / 2, ys[2], timerFont, timerText, Graphics.COLOR_WHITE);

        var phaseText = session.phaseLabel() + "  " + SaunaFormat.duration(session.phaseMs());
        if (session.showsMaxTime()) {
            phaseText = phaseText + " / " + session.getMaxTimeMin() + "m";
        }
        drawFitted(dc, w, ys[3], detailFonts, phaseText, phaseColor(session.currentPhase()));
        drawFitted(dc, w, ys[4], detailFonts, session.calories().toString() + " kcal", Graphics.COLOR_LT_GRAY);
    }

    // Heart rate with its unit beside it, on a red band while over the limit.
    function drawHeartRate(dc as Dc, w as Number, y as Numeric, numFont as Graphics.FontType, labelFont as Graphics.FontType, hr as Number?, high as Boolean) as Void {
        var num = hr != null ? hr.toString() : "--";
        var label = high ? "HIGH" : "bpm";
        var numW = dc.getTextWidthInPixels(num, numFont);
        var labelW = dc.getTextWidthInPixels(label, labelFont);
        var gap = w * 0.02;
        var total = numW + gap + labelW;
        var x = (w - total) / 2;
        var rowH = dc.getFontHeight(numFont);
        var numColor = Graphics.COLOR_RED;
        var labelColor = Graphics.COLOR_LT_GRAY;

        if (high) {
            var pad = w * 0.04;
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
            dc.fillRoundedRectangle(x - pad, y - rowH / 2, total + 2 * pad, rowH, rowH / 4);
            numColor = Graphics.COLOR_WHITE;
            labelColor = Graphics.COLOR_WHITE;
        }

        var left = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.setColor(numColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, numFont, num, left);
        dc.setColor(labelColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + numW + gap, y + rowH * 0.12, labelFont, label, left);
    }

    // Post-save summary, three pages: the totals, the time in each kind of phase, and the
    // main phase (sweat, or plunge) of each round.
    function drawSummary(dc as Dc, summary as SessionSummary, page as Number) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        if (page == 0) {
            drawTotals(dc, w, h, summary);
        } else if (page == 1) {
            drawPhases(dc, w, h, summary, page);
        } else {
            drawRounds(dc, w, h, summary, page);
        }
    }

    function drawTotals(dc as Dc, w as Number, h as Number, summary as SessionSummary) as Void {
        var rows = [0, 2, 3, 3, 0] as Array<Number>;
        var top = h * 0.08;
        var bottom = h * 0.92;
        var fonts = pickFonts(dc, rows, bottom - top);
        var ys = rowCenters(dc, fonts, rows, top, bottom);
        var rounds = summary.rounds();
        var avgHr = summary.avgHr;
        var maxHr = summary.maxHr;

        drawCentered(dc, w / 2, ys[0], fonts[0], "Saved 1/" + SUMMARY_PAGES, Graphics.COLOR_LT_GRAY);

        var totalText = SaunaFormat.duration(summary.totalMs);
        var totalFont = SaunaLayout.fitFont(dc, totalText, chordWidth(w, ys[1]) * 0.85, [
            fonts[2],
            Graphics.FONT_NUMBER_HOT,
            Graphics.FONT_NUMBER_MEDIUM,
            Graphics.FONT_NUMBER_MILD
        ] as Array<Graphics.FontType>);
        drawCentered(dc, w / 2, ys[1], totalFont, totalText, Graphics.COLOR_WHITE);

        drawPair(dc, w, ys[2], fonts[3], "avg " + (avgHr != null ? avgHr.toString() : "--"), "max " + (maxHr != null ? maxHr.toString() : "--"), Graphics.COLOR_RED);
        drawPair(dc, w, ys[3], fonts[3], rounds + (rounds == 1 ? " round" : " rounds"), summary.calories + " kcal", Graphics.COLOR_ORANGE);

        drawFitted(dc, w, ys[4], [fonts[0], Graphics.FONT_XTINY] as Array<Graphics.FontType>, pageHint("phases"), Graphics.COLOR_LT_GRAY);
    }

    // Total time in each kind of phase this session type has, in that phase's color.
    function drawPhases(dc as Dc, w as Number, h as Number, summary as SessionSummary, page as Number) as Void {
        var kinds = SaunaTypes.sequence(summary.type);
        var lines = [] as Array<String>;
        var colors = [] as Array<Number>;
        for (var i = 0; i < kinds.size(); i += 1) {
            lines.add(SaunaTypes.phaseName(kinds[i]) + "  " + SaunaFormat.duration(summary.totalFor(kinds[i])));
            colors.add(phaseColor(kinds[i]));
        }
        drawList(dc, w, h, "Phases " + (page + 1) + "/" + SUMMARY_PAGES, lines, colors, null, pageHint("rounds"));
    }

    // The main phase (sweat, or plunge in a plunge-only session) of each round.
    function drawRounds(dc as Dc, w as Number, h as Number, summary as SessionSummary, page as Number) as Void {
        var times = summary.mainTimes();
        var maxRows = 5;
        // With more rounds than rows, the last row says how many are not shown.
        var shown = times.size() > maxRows ? maxRows - 1 : times.size();
        var color = phaseColor(SaunaTypes.timedPhase(summary.type));

        var lines = [] as Array<String>;
        var colors = [] as Array<Number>;
        for (var i = 0; i < shown; i += 1) {
            lines.add((i + 1).toString() + "   " + SaunaFormat.duration(times[i]));
            colors.add(color);
        }
        var more = shown < times.size() ? "+" + (times.size() - shown) + " more" : null;
        drawList(dc, w, h, "Rounds " + (page + 1) + "/" + SUMMARY_PAGES, lines, colors, more, pageHint("totals"));
    }

    // A title, a list of centered lines (each in its own color), an optional last line,
    // and a hint at the bottom.
    function drawList(dc as Dc, w as Number, h as Number, title as String, lines as Array<String>, colors as Array<Number>, more as String?, hint as String) as Void {
        var rows = [0] as Array<Number>;
        for (var i = 0; i < lines.size() + (more != null ? 1 : 0); i += 1) {
            rows.add(3);
        }
        rows.add(0);

        var top = h * 0.08;
        var bottom = h * 0.92;
        var fonts = pickFonts(dc, rows, bottom - top);
        var ys = rowCenters(dc, fonts, rows, top, bottom);
        var listFonts = [fonts[3], Graphics.FONT_XTINY] as Array<Graphics.FontType>;
        var smallFonts = [fonts[0], Graphics.FONT_XTINY] as Array<Graphics.FontType>;

        drawCentered(dc, w / 2, ys[0], fonts[0], title, Graphics.COLOR_LT_GRAY);
        for (var i = 0; i < lines.size(); i += 1) {
            drawFitted(dc, w, ys[1 + i], listFonts, lines[i], colors[i]);
        }
        if (more != null) {
            drawFitted(dc, w, ys[1 + lines.size()], listFonts, more, Graphics.COLOR_LT_GRAY);
        }
        drawFitted(dc, w, ys[ys.size() - 1], smallFonts, hint, Graphics.COLOR_LT_GRAY);
    }

    // Two short texts side by side on one row.
    function drawPair(dc as Dc, w as Number, y as Numeric, font as Graphics.FontType, left as String, right as String, color as Number) as Void {
        var longer = left.length() > right.length() ? left : right;
        var fitted = SaunaLayout.fitFont(dc, longer, w * 0.36, [font, Graphics.FONT_XTINY] as Array<Graphics.FontType>);
        drawCentered(dc, w * 0.30, y, fitted, left, color);
        drawCentered(dc, w * 0.70, y, fitted, right, color);
    }
}
