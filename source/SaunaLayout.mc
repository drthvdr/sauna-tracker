import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Drawing helpers shared by the main and summary screens.
module SaunaLayout {

    // [x, y, width, height] of the round subscreen in the top-right corner of the
    // Instinct display. Falls back to the Instinct 3 Solar's position if the
    // device doesn't report one.
    function subscreenBox(screenWidth as Number) as Array<Number> {
        var sub = WatchUi.getSubscreen();
        if (sub != null) {
            return [sub.x, sub.y, sub.width, sub.height] as Array<Number>;
        }
        return [screenWidth - 63, 0, 62, 62] as Array<Number>;
    }

    // The first font whose text fits in maxWidth, or the last font if none do.
    function fitFont(dc as Dc, text as String, maxWidth as Numeric, fonts as Array<Graphics.FontType>) as Graphics.FontType {
        for (var i = 0; i < fonts.size() - 1; i += 1) {
            if (dc.getTextWidthInPixels(text, fonts[i]) <= maxWidth) {
                return fonts[i];
            }
        }
        return fonts[fonts.size() - 1];
    }

    // Heart rate inside the subscreen circle, white on black while over the limit.
    function drawHeartRate(dc as Dc, box as Array<Number>, hr as Number?, high as Boolean, label as String) as Void {
        var cx = box[0] + box[2] / 2;
        var cy = box[1] + box[3] / 2;
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var text = hr != null ? hr.toString() : "--";

        if (high) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.fillCircle(cx, cy, box[2] / 2);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        }

        var font = fitFont(dc, text, box[2] * 0.8, [Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_NUMBER_MILD] as Array<Graphics.FontType>);
        dc.drawText(cx, cy - box[3] * 0.10, font, text, center);
        dc.drawText(cx, cy + box[3] * 0.26, Graphics.FONT_XTINY, high ? "HIGH" : label, center);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    }
}
