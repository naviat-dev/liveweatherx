var aloft = props.getNode("environment/config/aloft");

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
}

var cleanup = func() {
    stop();
    delete(globals, "json");
}

var loop = func {
    print("Starting winds aloft fetch");
    var pos = geo.aircraft_position();
    var url = make_url({lat: str(pos.lat()), lon: str(pos.lon())});
    http.load(url)
        .fail(func print("OpenMeteo fetch failed"))
        .done(func(r) on_data(r.response));
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

var timer = maketimer(60, loop);


var start = func {
    print("Starting live winds");
    setprop("/environment/params/metar-updates-winds-aloft", 0);
    timer.start();
}

var stop = func {
    print("Stopping live winds");
    timer.stop();
    setprop("/environment/params/metar-updates-winds-aloft", 1);
    
}

delete(globals, "livewx");
globals["livewx"] = {
	"start": start,
    "stop": stop,
    "once": loop
};