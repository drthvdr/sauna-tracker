import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

// Screens for watches without a subscreen, such as the Forerunner 965: dark
// background, everything centered, fonts picked to fit. Rows are spread evenly down
// the screen and kept inside the visible circle.
module SaunaRound {

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

    function statusText(session as SaunaSession, state as Number) as String {
        if (state == STATE_PAUSED) {
            return "Stopped";
        }
        if (state == STATE_IDLE && !session.getLastResult().equals("")) {
            return session.getLastResult();
        }
        return "Sauna";
    }

    // The recording screen: status, heart rate, session timer, then the current heat
    // and calories. Before starting, the detail rows show the alert settings instead.
    function drawMain(dc as Dc, session as SaunaSession) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var state = session.getState();
        var idle = state == STATE_IDLE;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var rows = (idle ? [0, 1, 2, 3, 3, 3] : [0, 1, 2, 3, 3]) as Array<Number>;
        var top = h * 0.08;
        var bottom = h * 0.92;
        var fonts = pickFonts(dc, rows, bottom - top);
        var ys = rowCenters(dc, fonts, rows, top, bottom);

        drawCentered(dc, w / 2, ys[0], fonts[0], statusText(session, state), Graphics.COLOR_LT_GRAY);
        drawHeartRate(dc, w, ys[1], fonts[1], fonts[3], session.heartRate(), session.isHrHigh());

        var timerText = SaunaFormat.duration(session.timerMs());
        var timerFont = SaunaLayout.fitFont(dc, timerText, chordWidth(w, ys[2]) * 0.85, [
            fonts[2],
            Graphics.FONT_NUMBER_HOT,
            Graphics.FONT_NUMBER_MEDIUM,
            Graphics.FONT_NUMBER_MILD
        ] as Array<Graphics.FontType>);
        drawCentered(dc, w / 2, ys[2], timerFont, timerText, Graphics.COLOR_WHITE);

        var detailFonts = [fonts[3], Graphics.FONT_XTINY] as Array<Graphics.FontType>;
        if (idle) {
            var heatMin = session.getHeatAlertMin();
            var hrLimit = session.getHrLimit();
            drawFitted(dc, w, ys[3], detailFonts, "UP: heat alert " + (heatMin > 0 ? heatMin.toString() + " min" : "off"), Graphics.COLOR_ORANGE);
            drawFitted(dc, w, ys[4], detailFonts, "DOWN: HR limit " + (hrLimit > 0 ? hrLimit.toString() : "off"), Graphics.COLOR_LT_GRAY);
            drawFitted(dc, w, ys[5], detailFonts, "START to begin", Graphics.COLOR_LT_GRAY);
        } else {
            var heatText = "Heat " + session.heatNumber() + "  " + SaunaFormat.duration(session.heatMs());
            var target = session.getHeatAlertMin();
            if (target > 0) {
                heatText = heatText + " / " + target + "m";
            }
            drawFitted(dc, w, ys[3], detailFonts, heatText, Graphics.COLOR_ORANGE);
            drawFitted(dc, w, ys[4], detailFonts, session.calories().toString() + " kcal", Graphics.COLOR_LT_GRAY);
        }
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

    // Post-save summary. Page 0 has the totals, page 1 the time of each heat.
    function drawSummary(dc as Dc, summary as SessionSummary, page as Number) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        if (page == 0) {
            drawTotals(dc, w, h, summary);
        } else {
            drawHeats(dc, w, h, summary);
        }
    }

    function drawTotals(dc as Dc, w as Number, h as Number, summary as SessionSummary) as Void {
        var rows = [0, 2, 3, 3, 0] as Array<Number>;
        var top = h * 0.08;
        var bottom = h * 0.92;
        var fonts = pickFonts(dc, rows, bottom - top);
        var ys = rowCenters(dc, fonts, rows, top, bottom);
        var count = summary.heatTimes.size();
        var avgHr = summary.avgHr;
        var maxHr = summary.maxHr;

        drawCentered(dc, w / 2, ys[0], fonts[0], "Saved", Graphics.COLOR_LT_GRAY);

        var totalText = SaunaFormat.duration(summary.totalMs);
        var totalFont = SaunaLayout.fitFont(dc, totalText, chordWidth(w, ys[1]) * 0.85, [
            fonts[2],
            Graphics.FONT_NUMBER_HOT,
            Graphics.FONT_NUMBER_MEDIUM,
            Graphics.FONT_NUMBER_MILD
        ] as Array<Graphics.FontType>);
        drawCentered(dc, w / 2, ys[1], totalFont, totalText, Graphics.COLOR_WHITE);

        drawPair(dc, w, ys[2], fonts[3], "avg " + (avgHr != null ? avgHr.toString() : "--"), "max " + (maxHr != null ? maxHr.toString() : "--"), Graphics.COLOR_RED);
        drawPair(dc, w, ys[3], fonts[3], count + (count == 1 ? " heat" : " heats"), summary.calories + " kcal", Graphics.COLOR_ORANGE);

        drawFitted(dc, w, ys[4], [fonts[0], Graphics.FONT_XTINY] as Array<Graphics.FontType>, "DOWN: heats", Graphics.COLOR_LT_GRAY);
    }

    function drawHeats(dc as Dc, w as Number, h as Number, summary as SessionSummary) as Void {
        var heats = summary.heatTimes;
        var maxRows = 5;
        // With more heats than rows, the last row says how many are not shown.
        var shown = heats.size() > maxRows ? maxRows - 1 : heats.size();
        var hasMore = shown < heats.size();

        var rows = [0] as Array<Number>;
        for (var i = 0; i < shown + (hasMore ? 1 : 0); i += 1) {
            rows.add(3);
        }
        rows.add(0);

        var top = h * 0.08;
        var bottom = h * 0.92;
        var fonts = pickFonts(dc, rows, bottom - top);
        var ys = rowCenters(dc, fonts, rows, top, bottom);
        var listFonts = [fonts[3], Graphics.FONT_XTINY] as Array<Graphics.FontType>;

        drawCentered(dc, w / 2, ys[0], fonts[0], "Heats", Graphics.COLOR_LT_GRAY);
        for (var i = 0; i < shown; i += 1) {
            drawFitted(dc, w, ys[1 + i], listFonts, (i + 1).toString() + "   " + SaunaFormat.duration(heats[i]), Graphics.COLOR_WHITE);
        }
        if (hasMore) {
            drawFitted(dc, w, ys[1 + shown], listFonts, "+" + (heats.size() - shown) + " more", Graphics.COLOR_ORANGE);
        }
        drawFitted(dc, w, ys[ys.size() - 1], [fonts[0], Graphics.FONT_XTINY] as Array<Graphics.FontType>, "DOWN: totals", Graphics.COLOR_LT_GRAY);
    }

    // Two short texts side by side on one row.
    function drawPair(dc as Dc, w as Number, y as Numeric, font as Graphics.FontType, left as String, right as String, color as Number) as Void {
        var longer = left.length() > right.length() ? left : right;
        var fitted = SaunaLayout.fitFont(dc, longer, w * 0.36, [font, Graphics.FONT_XTINY] as Array<Graphics.FontType>);
        drawCentered(dc, w * 0.30, y, fitted, left, color);
        drawCentered(dc, w * 0.70, y, fitted, right, color);
    }
}
