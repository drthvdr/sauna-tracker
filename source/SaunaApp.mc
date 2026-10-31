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
        return [new SaunaView(_session), new SaunaDelegate(_session)];
    }

    // If the app is closed mid-session, keep what was recorded rather than lose it.
    function onStop(state as Dictionary?) as Void {
        _session.saveIfActive();
    }
}
