import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class SaunaApp extends Application.AppBase {

    private var _session as SaunaSession;

    function initialize() {
        AppBase.initialize();
        _session = new SaunaSession();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        // First pick the kind of session; that leads to the main screen.
        return [SaunaMenus.buildTypeMenu(_session.getType()), new SaunaTypeDelegate(_session)];
    }

    // If the app is closed mid-session, keep what was recorded rather than lose it.
    function onStop(state as Dictionary?) as Void {
        _session.saveIfActive();
    }
}
