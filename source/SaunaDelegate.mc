import Toybox.Lang;
import Toybox.WatchUi;

// START/STOP starts the session, then stops it and opens the Resume/Save/Discard
// menu. BACK ends the current heat while recording.
class SaunaDelegate extends WatchUi.BehaviorDelegate {

    private var _session as SaunaSession;

    function initialize(session as SaunaSession) {
        BehaviorDelegate.initialize();
        _session = session;
    }

    function onSelect() as Boolean {
        var state = _session.getState();
        if (state == STATE_IDLE) {
            _session.start();
        } else if (state == STATE_RECORDING) {
            _session.stop();
            showStopMenu();
        } else {
            showStopMenu();
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onBack() as Boolean {
        var state = _session.getState();
        if (state == STATE_RECORDING) {
            _session.markHeat();
            WatchUi.requestUpdate();
            return true;
        }
        if (state == STATE_PAUSED) {
            showStopMenu();
            return true;
        }
        return false;
    }

    // UP and DOWN pick the heat alert and the heart-rate limit before starting.
    function onPreviousPage() as Boolean {
        if (_session.getState() == STATE_IDLE) {
            _session.cycleHeatAlert();
            WatchUi.requestUpdate();
        }
        return true;
    }

    function onNextPage() as Boolean {
        if (_session.getState() == STATE_IDLE) {
            _session.cycleHrLimit();
            WatchUi.requestUpdate();
        }
        return true;
    }

    private function showStopMenu() as Void {
        WatchUi.pushView(SaunaMenus.buildStopMenu(), new SaunaMenuDelegate(_session), WatchUi.SLIDE_UP);
    }
}

module SaunaMenus {

    function buildStopMenu() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title => "Stopped"});
        menu.addItem(new WatchUi.MenuItem("Resume", null, :resume, {}));
        menu.addItem(new WatchUi.MenuItem("Save", null, :save, {}));
        menu.addItem(new WatchUi.MenuItem("Discard", null, :discard, {}));
        return menu;
    }

    // "Keep session" is first, so it is the item selected when the menu opens.
    function buildDiscardMenu() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title => "Discard?"});
        menu.addItem(new WatchUi.MenuItem("Keep session", null, :keep, {}));
        menu.addItem(new WatchUi.MenuItem("Discard", null, :discard, {}));
        return menu;
    }
}

class SaunaMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _session as SaunaSession;

    function initialize(session as SaunaSession) {
        Menu2InputDelegate.initialize();
        _session = session;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :resume) {
            _session.resume();
        } else if (id == :save) {
            var summary = _session.save();
            if (summary != null) {
                // Replace the menu with the summary; closing it returns to the main screen.
                var view = new SaunaSummaryView(summary);
                WatchUi.switchToView(view, new SaunaSummaryDelegate(view), WatchUi.SLIDE_IMMEDIATE);
                return;
            }
        } else if (id == :discard) {
            // Ask first: swap this menu for the confirmation.
            WatchUi.switchToView(SaunaMenus.buildDiscardMenu(), new SaunaDiscardDelegate(_session), WatchUi.SLIDE_IMMEDIATE);
            return;
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

// "Keep session" or BACK returns to the Stopped menu; only "Discard" deletes.
class SaunaDiscardDelegate extends WatchUi.Menu2InputDelegate {

    private var _session as SaunaSession;

    function initialize(session as SaunaSession) {
        Menu2InputDelegate.initialize();
        _session = session;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        if (item.getId() == :discard) {
            _session.discard();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else {
            showStopMenu();
        }
    }

    function onBack() as Void {
        showStopMenu();
    }

    private function showStopMenu() as Void {
        WatchUi.switchToView(SaunaMenus.buildStopMenu(), new SaunaMenuDelegate(_session), WatchUi.SLIDE_IMMEDIATE);
    }
}
