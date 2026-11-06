import Toybox.Lang;

// What each session type is made of, and what things are called on screen. BACK steps
// through the phases of the chosen type, in order, and starts over after the last one.
module SaunaTypes {

    function sequence(type as Number) as Array<Number> {
        if (type == TYPE_SAUNA_PLUNGE) {
            return [PHASE_SWEAT, PHASE_PLUNGE, PHASE_REST] as Array<Number>;
        }
        if (type == TYPE_PLUNGE) {
            return [PHASE_PLUNGE, PHASE_REST] as Array<Number>;
        }
        return [PHASE_SWEAT, PHASE_REST] as Array<Number>;
    }

    function typeName(type as Number) as String {
        if (type == TYPE_SAUNA_PLUNGE) {
            return "Sauna + plunge";
        }
        return type == TYPE_PLUNGE ? "Plunge" : "Sauna";
    }

    // The name of the saved activity (the watch allows about 15 characters).
    function activityName(type as Number) as String {
        return type == TYPE_PLUNGE ? "Cold plunge" : typeName(type);
    }

    function phaseName(kind as Number) as String {
        if (kind == PHASE_PLUNGE) {
            return "Plunge";
        }
        return kind == PHASE_REST ? "Rest" : "Sweat";
    }

    // The phase the max-time alert applies to: sweat, or the plunge in a plunge-only session.
    function timedPhase(type as Number) as Number {
        return type == TYPE_PLUNGE ? PHASE_PLUNGE : PHASE_SWEAT;
    }

    function maxTimeOptions(type as Number) as Array<Number> {
        return type == TYPE_PLUNGE ? MAX_TIME_OPTIONS_PLUNGE : MAX_TIME_OPTIONS_SAUNA;
    }
}
