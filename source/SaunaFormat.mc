import Toybox.Lang;

module SaunaFormat {

    // m:ss, or h:mm:ss once past an hour.
    function duration(ms as Number) as String {
        var totalSec = ms / 1000;
        var hours = totalSec / 3600;
        var minutes = (totalSec % 3600) / 60;
        var seconds = totalSec % 60;
        if (hours > 0) {
            return hours.toString() + ":" + minutes.format("%02d") + ":" + seconds.format("%02d");
        }
        return minutes.toString() + ":" + seconds.format("%02d");
    }
}
