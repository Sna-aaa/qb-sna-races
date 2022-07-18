# qb-races
Race Track Creation and Race management For QB-Core

Join our Discord : https://discord.gg/kvSwVzD8Rd

# Features
* Track creator/editor in game with command /raceadmin
* Track creator is accessible to the staff (admin, god) and to specified citizenid in the config
* Tracks made as lua files to allow save and sharing
* Each track have a maximum time to run, each driver must finish the race before this time
* Race creation with command /race
* Race can be created for a track or with a waypoint
* Race on tracks must be created near the track
* Number of laps can be specified for track races
* Race can be created with a fee, winner takes all
* Once created, the race can be joined by drivers
* Once joined, the starting line is shown to align cars
* The race creator launch the race with command /racestart
* No race can be created on a track if a race already running
* Races can be race or drift type, race save lap time, drift save points
* Best lap times and points are stored in DB for statistics and retrieved before a race
* Drift points are from angle and speed, each bump cancel the current drift points (like in need for speed)
* Your participation in a race can be cancelled with command /racequit, bests are not stored
* General statistics can be consulted by track (10 best times/scores with names and car)
* Personal statistics can be consulted by track (10 best times/scores with car)


# Installation
* Import races.sql in your DB

* Add in qb-core/shared/items.lua
```lua
	['drift'] 				 	 = {['name'] = 'drift', 			  	  		['label'] = 'Drift configuration', 					['weight'] = 1000, 		['type'] = 'item', 		['image'] = 'laptop.png', 				['unique'] = true, 	['useable'] = true, 	['shouldClose'] = true,	   ['combinable'] = nil,   ['description'] = 'Chip to toggle drift mode'},
```


# License

    QBCore Framework
    Copyright (C) 2021 Joshua Eger

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>
