local QBCore = exports['qb-core']:GetCoreObject()

local function MenuMain()
    local mainMenu = {
        {
            header = Lang:t("menu_race"),
            isMenuHeader = true
        },
        {
            header = Lang:t("menu_race_management"),
            txt = Lang:t("menu_create_race"),
            params = {
                event = "qb-races:client:RaceMenu"
            }
        },
        {
            header = Lang:t("menu_stats_races"),
            txt = Lang:t("menu_stats_for_races"),
            params = {
                event = "qb-races:client:StatsMenu",
                args = {
                    type = "race",
                }
            }
        },
        {
            header = Lang:t("menu_stats_drifts"),
            txt = Lang:t("menu_stats_for_drifts"),
            params = {
                event = "qb-races:client:StatsMenu",
                args = {
                    type = "drift",
                }
            }
        },
        {
            header = Lang:t("menu_close"),
            params = {
                event = "qb-menu:client:closeMenu"
            }
        },
    }
    exports['qb-menu']:openMenu(mainMenu)
end

local function MenuTrack()
    local trackMenu = {
        {
            header = Lang:t("menu_track"),
            isMenuHeader = true
        },
        {
            header = Lang:t("menu_create_track"),
            txt = Lang:t("menu_create_track"),
            params = {
                event = "qb-races:client:CreateMenu"
            }
        },
    }
    for k, v in pairs(Config.Tracks) do
        trackMenu[#trackMenu + 1] = {
            header = v.name,
            txt = Lang:t("menu_edit_track", {value = v.name}),
            params = {
                event = "qb-races:client:EditMenu",
                args = {
                    track = k,
                }
            }
        }
    end
    trackMenu[#trackMenu + 1] = {
        header = Lang:t("menu_close"),
        params = {
            event = "qb-menu:client:closeMenu"
        }
    }
    exports['qb-menu']:openMenu(trackMenu)
end

local function MenuRace()
    local trackoptions = {}
    trackoptions[#trackoptions + 1] = {value = "no", text = Lang:t("menu_race_no_track")}
    for k, v in pairs(Config.Tracks) do
        trackoptions[#trackoptions + 1] = {value = k, text = v.name}
    end

    local dialog = exports['qb-input']:ShowInput({
        header = Lang:t("menu_create_race"),
        submitText = Lang:t("menu_submit_create"),
        inputs = {
			{
				text = Lang:t("menu_race_type"),
				name = "racetype",
				type = "select",
				options = {
					{ value = "race", text = Lang:t("menu_type_race") },
					{ value = "drift", text = Lang:t("menu_type_drift") },
                    { value = "train", text = Lang:t("menu_type_train") },
					--{ value = "drag", text = "Drag race" }
				},
				default = "race"
			},

            {
                text = Lang:t("menu_race_laps"),
                name = "laps",
                type = "text",
                isRequired = true,
                default = "1",
            },
            {
                text = Lang:t("menu_race_track"),
                name = "track",
				type = "select",
				options = trackoptions,
				default = "no"
            },
            {
                text = Lang:t("menu_race_fee"),
                name = "fee",
                type = "text",
                isRequired = false,
                default = "",
            },
        }
    })
    if dialog then 
        local finish
        if dialog.fee == "" then
            dialog.fee = 0
        end
        if dialog.track == "no" then
            local WaypointHandle = GetFirstBlipInfoId(8)
            if DoesBlipExist(WaypointHandle) then
                finish = GetBlipInfoIdCoord(WaypointHandle, Citizen.ReturnResultAnyway(), Citizen.ResultAsVector())
                TriggerServerEvent('qb-races:server:CreateRace', dialog.racetype, math.floor(dialog.laps), dialog.track, math.floor(dialog.fee), finish)
            else
                QBCore.Functions.Notify(Lang:t("error_waypoint_needed"), "error")
            end
        else
            --Check if track is at less than 300m
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local pointDistance = #(pos - vector3(Config.Tracks[dialog.track].checkpoints[1].coords.x, Config.Tracks[dialog.track].checkpoints[1].coords.y, Config.Tracks[dialog.track].checkpoints[1].coords.z))
            if pointDistance < 300 then
                TriggerServerEvent('qb-races:server:CreateRace', dialog.racetype, math.floor(dialog.laps), dialog.track, math.floor(dialog.fee), nil)
            else
                QBCore.Functions.Notify(Lang:t("error_too_far"), "error")
            end
        end
    end
end

local function MenuEdit(track)
    local dialog = exports['qb-input']:ShowInput({
        header = Lang:t("menu_edit_track", {value = Config.Tracks[track].name}),
        submitText = Lang:t("menu_submit_save"),
        inputs = {
            {
                text = Lang:t("menu_track_name"),
                name = "trackname",
                type = "text",
                isRequired = true,
                default = Config.Tracks[track].name,
            },
            {
                text = Lang:t("menu_security_time"),
                name = "securitytime",
                type = "text",
                isRequired = true,
                default = Config.Tracks[track].securitytime,
            },

        }
    })
    if dialog then
        Config.Tracks[track].securitytime = dialog.securitytime
        Config.Tracks[track].name = dialog.trackname
        TriggerServerEvent('qb-races:server:SaveTrack', Config.Tracks[track], track) 
    end
end

local function MenuCreate()
    local dialog = exports['qb-input']:ShowInput({
        header = Lang:t("menu_create_track"),
        submitText = Lang:t("menu_submit_create"),
        inputs = {
            {
                text = Lang:t("menu_track_identifier"),
                name = "trackid",
                type = "text",
                isRequired = true,
                default = "",
            },
            {
                text = Lang:t("menu_track_name"),
                name = "trackname",
                type = "text",
                isRequired = true,
                default = "",
            },
            {
                text = Lang:t("menu_security_time"),
                name = "securitytime",
                type = "text",
                isRequired = true,
                default = "",
            },

        }
    })
    if dialog then
        TriggerEvent('qb-races:client:CreateTrack', dialog.trackid, dialog.trackname, dialog.securitytime) 
    end
end

local function MenuStats(type)

    local statsMenu = {
        {
            header = Lang:t("menu_stats_for", {value = type}),
            isMenuHeader = true
        },
    }

    for k, v in pairs(Config.Tracks) do
        statsMenu[#statsMenu + 1] = {
            header = Lang:t("menu_stats", {value = v.name}),
            txt = Lang:t("menu_stats_for_track", {value = v.name}),
            params = {
                event = "qb-races:client:StatMenu",
                args = {
                    track = k,
                    type = type,
                    perso = false,
                }
            }
        }
        statsMenu[#statsMenu + 1] = {
            header = Lang:t("menu_personal_stats", {value = v.name}),
            txt = Lang:t("menu_personal_stats_for", {value = v.name}),
            params = {
                event = "qb-races:client:StatMenu",
                args = {
                    track = k,
                    type = type,
                    perso = true,
                }
            }
        }
    end

    statsMenu[#statsMenu + 1] = {
        header = Lang:t("menu_back"),
        txt = "",
        params = {
            event = "qb-races:client:MainMenu",
        }
    }    
    exports['qb-menu']:openMenu(statsMenu)
end

local function SecondsToClock(seconds)
    local cent = tonumber(seconds)
    local retval = 0
    if seconds <= 0 then
        retval = "00:00:00"
    else
        local h = math.floor(cent/36000)       --Get whole hours
        cent = cent - h*36000;
        local m = math.floor(cent/600)          --Get remaining minutes
        cent = cent - m*600;
        local s = math.floor(cent/10)           --Get remaining seconds
        cent = cent - s*10;
        retval = string.format("%02i:%02i:%02i.%01i", h, m, s, cent)
    end
    return retval
end

local function MenuStat(track, type, perso)
    local statMenu = {
        {
            header = Lang:t("menu_stats_for", {value = Config.Tracks[track].name}),
            isMenuHeader = true
        },
    }
	QBCore.Functions.TriggerCallback('qb-races:server:GetStats', function(result)
        for k, v in pairs(result) do
            if perso then
                if type == "race" then
                    statMenu[#statMenu + 1] = {
                        header = SecondsToClock(v.best).." / "..v.car,
                        txt = "",
                    }    
                else
                    statMenu[#statMenu + 1] = {
                        header = v.best.." / "..v.car,
                        txt = "",
                    }    
                end
            else
                if type == "race" then
                    statMenu[#statMenu + 1] = {
                        header = SecondsToClock(v.best).." / "..v.name,
                        txt = v.car,
                    }    
                else
                    statMenu[#statMenu + 1] = {
                        header = v.best.." / "..v.name,
                        txt = v.car,
                    }    
                end
            end
        end
        statMenu[#statMenu + 1] = {
            header = Lang:t("menu_back"),
            txt = "",
            params = {
                event = "qb-races:client:StatsMenu",
                args = {
                    type = type,
                }
            }
        }    
        exports['qb-menu']:openMenu(statMenu)
	end, track, type, perso)
end

RegisterNetEvent('qb-races:client:MainMenu', function()
    MenuMain()
end)
RegisterNetEvent('qb-races:client:RaceMenu', function()
    MenuRace()
end)
RegisterNetEvent('qb-races:client:TrackMenu', function()
    MenuTrack()
end)
RegisterNetEvent('qb-races:client:EditMenu', function(data)
    local track = data.track
    MenuEdit(track)
end)
RegisterNetEvent('qb-races:client:CreateMenu', function()
    MenuCreate()
end)
RegisterNetEvent('qb-races:client:StatsMenu', function(data)
    local type = data.type
    MenuStats(type)
end)
RegisterNetEvent('qb-races:client:StatMenu', function(data)
    local track = data.track
    local type = data.type
    local perso = data.perso
    MenuStat(track, type, perso)
end)