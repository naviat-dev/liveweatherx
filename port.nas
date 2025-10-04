var aloft = props.getNode("/environment/config/aloft");
var sim_time = props.getNode("/sim/time/utc");
var real_time = props.getNode("/sim/time/real");

var status = props.getNode("/livewxx/status-text", 1);
var available = props.getNode("/livewxx/available", 1);
var use_sim_time = props.getNode("/livewxx/use-sim-time", 1);

var MIN_FETCH_INTERVAL = 15; # Makes sure we do not exceed rate limits
var MAX_FETCH_INTERVAL = 60;

var MIN_FETCH_DIST = 1000;

var DEFAULT_LAYERS = [5000, 10000, 18000, 24000, 30000];
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
    var datetime = (use_sim_time.getBoolValue() ? sim_time : real_time).getValues();
    var url = make_url({
        lat: str(pos.lat()),
        lon: str(pos.lon()),
        date: sprintf("%04d-%02d-%02d", datetime["year"], datetime["month"], datetime["day"])
    });
    print(url);

    http.load(url)
        .fail(func {
            print("OpenMeteo fetch failed");
            status.setValue("Error");
        })
        .done(func(r) {
            print(r.response);
            on_data(r.response);
        });

    print("Main loop done");
}

var on_data = func(text) {
    print("Received data from OpenMeteo");
    var data = json.parse(text);

    if (contains(data, "error")) {
        print("OpenMeteo data error: " ~ data["reason"]);
        status.setValue("Error");
        return;
    }

    var hour = getprop("/sim/time/real/hour"); # Because the API returns 24 values for the day, we can use this as an index

    for (var i = 0; i < 5; i += 1) {
        var level = LEVELS[i];
        var entry = aloft.getChild("entry", i);

        var elev_m = data["hourly"]["geopotential_height_"~level~"hPa"][hour];
        entry.setValue("elevation-ft", elev_m ? elev_m * M2FT : DEFAULT_LAYERS[i]);
        entry.setValue("wind-from-heading-deg", data["hourly"]["winddirection_"~level~"hPa"][hour] or 0);
        entry.setValue("wind-speed-kt", data["hourly"]["windspeed_"~level~"hPa"][hour] or 0);
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
    for (var i = 0; i < 5; i += 1) {
        var entry = aloft.getChild("entry", i);
        entry.setValue("elevation-ft", DEFAULT_LAYERS[i]);
    }
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
        props.getNode("/livewxx/enable").setValue(0);
    } else {
        available.setValue(1);
    }
}, 1, 0);