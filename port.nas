var aloft = props.getNode("environment/config/aloft");
var status = props.getNode("livewxx/status-text", 1);
var available = props.getNode("/livewxx/available", 1);

var MIN_FETCH_INTERVAL = 15; # Makes sure we do not exceed rate limits
var MAX_FETCH_INTERVAL = 60;

var MIN_FETCH_DIST = 1000;


var LEVELS = ["850", "700", "500", "400", "300"];

var make_url = nil;

var init = func(addon) {
    globals["jsontest"] = func {
	    print("=== Reloading json ===");
	    delete(globals, "json");
	    io.load_nasal(addon.basePath~"/json.nas", "json");
	    json.test(addon.basePath~"/test.json");
    };

	io.load_nasal(addon.basePath~"/json.nas", "json");
    make_url = string.compileTemplate(io.readfile(addon.basePath~"/url.txt"));

    delete(globals, "livewxx");
    globals["livewxx"] = {
        "start": start,
        "stop": stop,
        "once": main_loop
    };
}

var cleanup = func() {
    removelistener(la);
    removelistener(lb);
    stop();
    delete(globals, "json");
}

var last_fetch_pos = geo.aircraft_position();
var last_fetch_t = systime();

var main_loop = func {
    print("Executing main loop");
    
    var pos = geo.aircraft_position();
    var dt = systime() - last_fetch_t;

    if (pos.distance_to(last_fetch_pos) < MIN_FETCH_DIST and dt < MAX_FETCH_INTERVAL) {
        print("Not fetching because too little distance");
        return;
    }
    if (dt < MIN_FETCH_INTERVAL) {
        print("Not fetching becsause too little time has passed since last fetch.");
        status.setValue("Holding");
        return;
    }

    status.setValue("Fetching");

    last_fetch_pos = pos;
    last_fetch_t = systime();

    print("Starting winds aloft fetch");
    var url = make_url({lat: str(pos.lat()), lon: str(pos.lon())});
    http.load(url)
        .fail(func print("OpenMeteo fetch failed"))
        .done(func(r) on_data(r.response));

    status.setValue("Ready");

    print("Main loop done");
}

var on_data = func(text) {
    print("Received data from OpenMeteo");
    var data = json.parse(text);
    var hour = getprop("/sim/time/real/hour"); # Because the API returns 24 values for the day, we can use this as an index

    for (var i = 0; i < 5; i += 1) {
        var level = LEVELS[i];
        var entry = aloft.getChild("entry", i);

        entry.setValue("elevation-ft", data["hourly"]["geopotential_height_"~level~"hPa"][hour] * M2FT);
        entry.setValue("wind-from-heading-deg", data["hourly"]["winddirection_"~level~"hPa"][hour]);
        entry.setValue("wind-speed-kt", data["hourly"]["windspeed_"~level~"hPa"][hour]);
    }

    print("Winds aloft update pushed");

}

var timer = maketimer(5, main_loop);


var start = func {
    print("Starting live winds");
    setprop("/environment/params/metar-updates-winds-aloft", 0);
    timer.start();
    status.setValue("Ready");
}

var stop = func {
    print("Stopping live winds");
    timer.stop();
    setprop("/environment/params/metar-updates-winds-aloft", 1);
    status.setValue("Disabled"); 
}

var la = setlistener("/livewxx/enable", func(node) {
    if (node.getBoolValue() and available.getBoolValue()) {
        start();
    } else {
        stop();
    }
}, 1, 0);

var lb = setlistener("/nasal/local_weather/enabled", func(node) {
    if (node.getBoolValue()) {
        available.setValue(0);
        props.getNode("/livewxx/enable").setValue(0)
    } else {
        available.setValue(1);
    }
}, 1, 0);