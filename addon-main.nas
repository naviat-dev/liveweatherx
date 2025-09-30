#This file is part of FlightGear.
#
#FlightGear is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 2 of the License, or
#(at your option) any later version.
#
#FlightGear is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with FlightGear.  If not, see <http://www.gnu.org/licenses/>.

# This is the main addon Nasal hook. It MUST contain a function
# called "main". The main function will be called upon init with
# the addons.Addon instance corresponding to the addon being loaded.
#
# This script will live in its own Nasal namespace that gets
# dynamically created from the global addon init script.
# It will be something like "__addon[ADDON_ID]__" where ADDON_ID is
# the addon identifier, such as "org.flightgear.addons.Skeleton".
#
# See $FG_ROOT/Docs/README.add-ons for info about the addons.Addon
# object that is passed to main(), and much more. The latest version
# of this README.add-ons document is at:
#
#   https://sourceforge.net/p/flightgear/fgdata/ci/next/tree/Docs/README.add-ons
#

var pressureIndex = [[110, 1000], [320, 975], [500, 950], [800, 925], [1000, 900], [1500, 850], [1900, 800], [3000, 700], [4200, 600], [5600, 500], [7200, 400], [9200, 300], [10400, 250], [11800, 200], [13500, 150], [15800, 100], [17700, 70], [19300, 50], [22000, 30]];

var unload = func(addon) {
	# This function is for addon development only. It is called on addon 
	# reload. The addons system will replace setlistener() and maketimer() to
	# track this resources automatically for you.
	#
	# Listeners created with setlistener() will be removed automatically for you.
	# Timers created with maketimer() will have their stop() method called 
	# automatically for you. You should NOT use settimer anymore, see wiki at
	# http://wiki.flightgear.org/Nasal_library#maketimer.28.29
	#
	# Other resources should be freed by adding the corresponding code here,
	# e.g. myCanvas.del();

	_v_port.cleanup();
	delete(globals, "_v_port");

}

var main = func(addon) {


	io.load_nasal(addon.basePath~"/port.nas", "_v_port"); # Temporary file for the ported nasal script
	_v_port.init(addon);

	logprint(LOG_INFO, "Skeleton addon initialized from path ", addon.basePath);
	var latInit = getprop("/position/latitude-deg");
	var lonInit = getprop("/position/longitude-deg");
	var altInit = getprop("/position/altitude-ft");
	logprint(LOG_INFO, "Initial position: lat=", latInit, " lon=", lonInit, " alt=", altInit);
}

var update = func(lat, lon, alt) {
	print(pressureIndex.size());
	var alt_m = alt * FT2M; # feet to meters
	var pressureUpper = 0;
	var pressureLower = 0;
	var interval = 0.0;
	# We need to convert the altitude from feet into a pressure value
	if (alt_m < pressureIndex[0][0]) {
		pressureLower = pressureIndex[0][1];
		pressureUpper = pressureIndex[0][1];
	} else if (alt_m >= pressureIndex[pressureIndex.size() - 1][0]) {
		pressureLower = pressureIndex[pressureIndex.size() - 1][1];
		pressureUpper = pressureIndex[pressureIndex.size() - 1][1];
	} else {
		for (var i = 0; i < pressureIndex.size() - 1; i += 1) {
			if (alt_m >= pressureIndex[i][0] and alt_m < pressureIndex[i + 1][0]) {
				pressureLower = pressureIndex[i][1];
				pressureUpper = pressureIndex[i + 1][1];
				interval = (alt_m - pressureIndex[i][0]) / (pressureIndex[i + 1][0] - pressureIndex[i][0]);
				break;
			}
		}
	}
	# http.load("");
	# http.load("http://example.com/test.txt")
    # .done(func(r) print("Got response: " ~ r.response));
}
