import Toybox.Lang;
import Toybox.WatchUi;

// START/STOP starts the session, then stops it and opens the Resume/Save/Discard menu.
// BACK moves to the next phase while recording (sweat, rest, and so on); before a session
// starts it goes back to the session-type menu.
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
            _session.nextPhase();
            WatchUi.requestUpdate();
            return true;
        }
        if (state == STATE_PAUSED) {
            showStopMenu();
            return true;
        }
        // Idle: back to the session-type menu, where BACK leaves the app.
        WatchUi.switchToView(SaunaMenus.buildTypeMenu(_session.getType()), new SaunaTypeDelegate(_session), WatchUi.SLIDE_RIGHT);
        return true;
    }

    // Touch screens: sweat causes stray taps and swipes, and a tap would otherwise act
    // like START, so touches are ignored. The one exception is a watch with no UP/DOWN
    // buttons (vivoactive 5): before a session starts, tapping a setting row changes it.
    // Nothing responds to touch while recording.
    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        if (!SaunaLayout.hasPageButtons() && _session.getState() == STATE_IDLE) {
            var which = SaunaRound.settingAt(evt.getCoordinates()[1]);
            if (which == :time) {
                _session.cycleMaxTime();
                WatchUi.requestUpdate();
            } else if (which == :hr) {
                _session.cycleHrLimit();
                WatchUi.requestUpdate();
            }
        }
        return true;
    }

    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        return true;
    }

    // UP and DOWN pick the max time and the max heart rate before starting.
    function onPreviousPage() as Boolean {
        if (_session.getState() == STATE_IDLE) {
            _session.cycleMaxTime();
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

    // The first screen: what kind of session this is. It opens on the type used last time.
    function buildTypeMenu(current as Number) as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title => "Session"});
        menu.addItem(new WatchUi.MenuItem("Sauna", "sweat, rest", :sauna, {}));
        menu.addItem(new WatchUi.MenuItem("Sauna + plunge", "sweat, plunge, rest", :saunaPlunge, {}));
        menu.addItem(new WatchUi.MenuItem("Plunge", "plunge, rest", :plunge, {}));
        menu.setFocus(current);
        return menu;
    }

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

// Picking a session type opens the main screen (the max time and max HR settings).
class SaunaTypeDelegate extends WatchUi.Menu2InputDelegate {

    private var _session as SaunaSession;

    function initialize(session as SaunaSession) {
        Menu2InputDelegate.initialize();
        _session = session;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        var type = TYPE_SAUNA;
        if (id == :saunaPlunge) {
            type = TYPE_SAUNA_PLUNGE;
        } else if (id == :plunge) {
            type = TYPE_PLUNGE;
        }
        _session.setType(type);
        WatchUi.switchToView(new SaunaView(_session), new SaunaDelegate(_session), WatchUi.SLIDE_LEFT);
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
