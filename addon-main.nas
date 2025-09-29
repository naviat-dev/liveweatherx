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
}

var main = func(addon) {
  logprint(LOG_INFO, "Skeleton addon initialized from path ", addon.basePath);
}
