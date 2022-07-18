local QBCore = exports['qb-core']:GetCoreObject()
local Races = {}
local RacePositions = {}

QBCore.Functions.CreateUseableItem("drift", function(source, item)
    TriggerClientEvent('smallresource:client:ToggleDrift', source)
end)

local function IsWhitelisted(CitizenId)
    local retval = false
    for _, cid in pairs(Config.WhitelistedCreators) do
        if cid == CitizenId then
            retval = true
            break
        end
    end
    local Player = QBCore.Functions.GetPlayerByCitizenId(CitizenId)
    local Perms = QBCore.Functions.GetPermission(Player.PlayerData.source)
    if Perms.admin or Perms.god then
        retval = true
    end
    return retval
end

RegisterNetEvent('qb-races:server:SaveTrack', function(TrackData, id)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	if not Player then return end
    local trackData = {}
    trackData.name = TrackData.name
    if TrackData.author then
        trackData.author = TrackData.author
    else
        trackData.author = Player.PlayerData.name
    end
    trackData.distance = TrackData.distance
    trackData.checkpoints = TrackData.checkpoints
    trackData.securitytime = TrackData.securitytime

	local path = GetResourcePath(GetCurrentResourceName())
    local tempfile, err = io.open(path:gsub('//', '/')..'/tracks/'..string.gsub(id, ".lua", "")..'.lua', 'w+')
    if tempfile then
        tempfile:close()
        path = path:gsub('//', '/')..'/tracks/'..string.gsub(id, ".lua", "")..'.lua'
    else
        return error(err)
    end

	local file = io.open(path, 'a+')
	local str = "\n\n-- Track "..trackData.name.." created by "..trackData.author.."\nConfig.Tracks['"..id.."'] = {"
	file:write(str)
    str = "\n    author = '"..trackData.author.."',"
    file:write(str)
    str = "\n    name = '"..trackData.name.."',"
    file:write(str)
    str = "\n    distance = '"..trackData.distance.."',"
    file:write(str)
    str = "\n    securitytime = '"..trackData.securitytime.."',"
    file:write(str)
    str = "\n    checkpoints = {"
    file:write(str)
    for k, v in pairs(trackData.checkpoints) do
        str = "\n        {"
        file:write(str)
        str = "\n            coords = {"
        file:write(str)
        str = "\n                x = "..v.coords.x..","
        file:write(str)
        str = "\n                y = "..v.coords.y..","
        file:write(str)
        str = "\n                z = "..v.coords.z..","
        file:write(str)
        str = "\n            },"
        file:write(str)
        str = "\n            offset = {"
        file:write(str)
        str = "\n                left = {"
        file:write(str)
        str = "\n                    x = "..v.offset.left.x..","
        file:write(str)
        str = "\n                    y = "..v.offset.left.y..","
        file:write(str)
        str = "\n                    z = "..v.offset.left.z..","
        file:write(str)
        str = "\n                },"
        file:write(str)
        str = "\n                right = {"
        file:write(str)
        str = "\n                    x = "..v.offset.right.x..","
        file:write(str)
        str = "\n                    y = "..v.offset.right.y..","
        file:write(str)
        str = "\n                    z = "..v.offset.right.z..","
        file:write(str)
        str = "\n                },"
        file:write(str)
        str = "\n            },"
        file:write(str)
        str = "\n        },"
        file:write(str)
    end
    str = "\n    },"
    file:write(str)
    str = "\n}"
    file:write(str)
	file:close()

    Config.Tracks[id] = trackData
    TriggerClientEvent('qb-races:client:SaveTrack', -1, id, trackData)
end)

RegisterNetEvent('qb-races:server:CreateRace', function(type, laps, track, fee, finish, instance)
    local src = source
	local Player = QBCore.Functions.GetPlayer(src)
    local PlayerPed = GetPlayerPed(src)
    local PlayerPos = GetEntityCoords(PlayerPed)
    local CreateOk = true
    if track ~= "no" then
        if Config.Tracks[track].occupied then
            CreateOk = false
            TriggerClientEvent('QBCore:Notify', src, Lang:t("error_track_occupied"), 'error')
        end
    end
    if CreateOk then
        Races[Player.PlayerData.citizenid] = {
            RaceType = type,
            RaceLaps = laps,
            RaceTrack = track,
            RaceFinish = finish,
            RaceJoin = PlayerPos,
            RaceFee = fee,
            RacePot = 0,
            FirstArrived = false,
            Instance = instance,
            RaceDrivers = {},
        }
        TriggerClientEvent('qb-races:client:CreateRace', -1, Races[Player.PlayerData.citizenid], Player.PlayerData.citizenid)
    end
end)

RegisterNetEvent('qb-races:server:FinishRace', function(id, bestlap, total, car, cancel)
    local src = source
	local Player = QBCore.Functions.GetPlayer(src)
    if not cancel and Races[id].RaceTrack ~= "no" then
        local type
        if Races[id].RaceType == "train" then
            type = "race"
        else
            type = Races[id].RaceType
        end
        local result = MySQL.Sync.fetchAll('SELECT * FROM races WHERE track = ? AND citizenid = ? AND type = ? AND car = ?', {Races[id].RaceTrack, id, type, car})
        if result[1] then
            if Races[id].RaceType == "drift" then
                if bestlap > result[1].best then
                    TriggerClientEvent('QBCore:Notify', src, "Your best score is updated", 'success')
                    MySQL.Async.execute('UPDATE races SET best = ? WHERE track = ? AND citizenid = ? AND type = ? AND car = ?', {bestlap, Races[id].RaceTrack, id, type, car})
                end
            else
                if bestlap < result[1].best then
                    TriggerClientEvent('QBCore:Notify', src, "Your best lap is updated", 'success')
                    MySQL.Async.execute('UPDATE races SET best = ? WHERE track = ? AND citizenid = ? AND type = ? AND car = ?', {bestlap, Races[id].RaceTrack, id, type, car})
                end
            end
        else
            TriggerClientEvent('QBCore:Notify', src, "New best score for this car", 'success')
            MySQL.Async.insert('INSERT INTO races (track, citizenid, type, car, best) VALUES (?, ?, ?, ?, ?)', {Races[id].RaceTrack, id, type, car, bestlap})
        end
    end
    Races[id].RaceDrivers[source].score = total
    Races[id].RaceDrivers[source].best = bestlap
    Races[id].RaceDrivers[source].finished = true
    if not Races[id].FirstArrived and Races[id].RaceType == "race" and not cancel then
        Races[id].FirstArrived = true
        if Races[id].RacePot ~= 0 then
            Player.Functions.AddMoney('cash', Races[id].RacePot, "race-won")
            TriggerClientEvent('QBCore:Notify', src, Lang:t("success_won_race_fee", {value = Races[id].RacePot}), 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t("success_won_race"), 'success')
        end
    end
    
    local best = 0
    local index
    local running = false
    for k, v in pairs(Races[id].RaceDrivers) do
        if not v.finished then
            running = true
        else
            if v.score > best then
                best = v.score
                index = v.source
            end
        end
    end    
    if not running then
        if Races[id].RaceType == "drift" then
            if Races[id].RacePot ~= 0 then
                local DriverPlayer = QBCore.Functions.GetPlayer(index)
                DriverPlayer.Functions.AddMoney('cash', Races[id].RacePot, "race-won")
                TriggerClientEvent('QBCore:Notify', index, Lang:t("success_won_drift_fee", {value = Races[id].RacePot}), 'success')
            else
                TriggerClientEvent('QBCore:Notify', index, Lang:t("success_won_drift"), 'success')
            end
        end
        if Races[id].RaceTrack ~= "no" then
            Config.Tracks[Races[id].RaceTrack].occupied = false
        end
        Races[id] = nil
    end
end)

RegisterNetEvent('qb-races:server:SendPosition', function(index, distance, checkpoint, lap)
    local src = source
    if Races[index] then
        Races[index].RaceDrivers[src].distance = distance
        Races[index].RaceDrivers[src].checkpoint = checkpoint
        Races[index].RaceDrivers[src].lap = lap
        if lap then
            Races[index].RaceDrivers[src].forpos = 100000000 - ( lap * 1000000 ) - (checkpoint * 10000) + distance
        else
            Races[index].RaceDrivers[src].forpos = distance
        end
    end
end)

CreateThread(function()
    local sleep
    while true do
        sleep = 1000
        for k, v in pairs(Races) do
            if v.RaceRunning then
                RacePositions[k] = {}
                for i, w in pairs(v.RaceDrivers) do
                    RacePositions[k][#RacePositions[k] + 1] = w
                end
                if RacePositions[k] then
                    table.sort(RacePositions[k], function(k1, k2) return k1.forpos < k2.forpos end)
                    for k, v in pairs(RacePositions[k]) do
                        TriggerClientEvent('qb-races:client:GetPosition', v.source, k)
                    end
                end
                sleep = 100
            end
        end
        Wait(sleep)
    end
end)

QBCore.Functions.CreateCallback('qb-races:server:GetRaces', function(source, cb)
	cb(Races)
end)

QBCore.Functions.CreateCallback('qb-races:server:JoinRace', function(source, cb, index, car)
    local src = source
	local Player = QBCore.Functions.GetPlayer(src)
    local JoinOk = true
    if Races[index].RaceType == "drift" then
        if Config.IsDriftItemNeededForRace then
            if not Player.Functions.GetItemByName("drift") then
                TriggerClientEvent('QBCore:Notify', src, Lang:t("error_no_configuration"), 'error')
                JoinOk = false
            end
        end
    end

    if Player.PlayerData.money.cash < Races[index].RaceFee then
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error_not_enough_cash"), 'error')
        JoinOk = false
    end

    if JoinOk then
        if Races[index].RaceFee > 0 then
            Player.Functions.RemoveMoney('cash', Races[index].RaceFee, "race-joined")
        end
        Races[index].RacePot = Races[index].RacePot + Races[index].RaceFee
        Races[index].RaceDrivers[source] = {}
        Races[index].RaceDrivers[source].citizenid = Player.PlayerData.citizenid
        Races[index].RaceDrivers[source].source = source
        Races[index].RaceDrivers[source].car = car
        Races[index].RaceDrivers[source].forpos = 0
    end
    cb(JoinOk)
end)

local function StartRace(src)
	local Player = QBCore.Functions.GetPlayer(src)
    TriggerClientEvent('qb-races:client:RemoveRace', -1, Player.PlayerData.citizenid)
    if Races[Player.PlayerData.citizenid] then
        if Races[Player.PlayerData.citizenid].RaceTrack ~= "no" then
            Config.Tracks[Races[Player.PlayerData.citizenid].RaceTrack].occupied = true
        end
        local type 
        if Races[Player.PlayerData.citizenid].RaceType == "train" then
            type = "race"
        else
            type = Races[Player.PlayerData.citizenid].RaceType
        end
        local drivers = 0
    
        for k, v in pairs(Races[Player.PlayerData.citizenid].RaceDrivers) do
            drivers = drivers + 1
            local result = MySQL.Sync.fetchAll('SELECT * FROM races WHERE track = ? AND citizenid = ? AND type = ? AND car = ?', {Races[Player.PlayerData.citizenid].RaceTrack, v.citizenid, type, v.car})
            if result[1] then
                v.best = result[1].best
            else
                v.best = 0
            end
        end
        for k, v in pairs(Races[Player.PlayerData.citizenid].RaceDrivers) do
            TriggerClientEvent('qb-races:client:CountdownRace', v.source, Player.PlayerData.citizenid, drivers, v.best)
        end
        Races[Player.PlayerData.citizenid].RaceRunning = true
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error_no_race"), 'error')
    end
end

QBCore.Functions.CreateCallback('qb-races:server:GetStats', function(source, cb, track, type, perso)
    local Player = QBCore.Functions.GetPlayer(source)
    local result = {}
    local direction
    if type == "drift" then
        direction = "DESC"
    else
        direction = "ASC"
    end
    if perso then

        local res = MySQL.Sync.fetchAll('SELECT * FROM races WHERE track = ? AND citizenid = ? AND type = ? ORDER BY best '..direction..' LIMIT '..Config.StatsLimit, {track, Player.PlayerData.citizenid, type})
        for k, v in pairs(res) do
            result[#result + 1] = {
                best = v.best,
                car = v.car,
                name = Player.PlayerData.charinfo.firstname
            }
        end
    else
        local res = MySQL.Sync.fetchAll('SELECT races.best, races.car, players.charinfo FROM races INNER JOIN players ON races.citizenid = players.citizenid WHERE races.track = ? AND races.type = ? ORDER BY best '..direction..' LIMIT '..Config.StatsLimit, {track, type})
        for k, v in pairs(res) do
            local charinfo = json.decode(v.charinfo)
            result[#result + 1] = {
                best = v.best,
                car = v.car,
                name = charinfo.firstname.." "..charinfo.lastname
            }
        end
    end
    cb(result)
end)

RegisterNetEvent('qb-races:server:StartRace', function()
    local src = source
    StartRace(src)
end)

QBCore.Commands.Add("race", Lang:t("command_race"), {}, false, function(source, args)
    TriggerClientEvent('qb-races:client:MainMenu', source)
end)

QBCore.Commands.Add("raceadmin", Lang:t("command_raceadmin"), {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if IsWhitelisted(Player.PlayerData.citizenid) then
        TriggerClientEvent('qb-races:client:TrackMenu', src)
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t("error_not_authorized"), 'error')
    end
end)

QBCore.Commands.Add("racestart", Lang:t("command_racestart"), {}, false, function(source, args)
    StartRace(source)
end)

QBCore.Commands.Add("racequit", Lang:t("command_racequit"), {}, false, function(source, args)
    TriggerClientEvent('qb-races:client:CancelRace', source)
end)

 
local Namedinstances = {}
 
 
RegisterNetEvent("instance:setNamed", function(setName)
 
    print('[INSTANCES] Named Instances looked like this: ', json.encode(Namedinstances))
    local src = source
    local instanceSource = nil
 
    TriggerClientEvent('DoTheBigRefreshYmaps', src)
 
    if setName == 0 then
            for k,v in pairs(Namedinstances) do
                for k2,v2 in pairs(v.people) do
                    if v2 == src then
                        table.remove(v.people, k2)
                    end
                end
                if #v.people == 0 then
                    Namedinstances[k] = nil
                end
            end
        instanceSource = setName
 
    else
        for k,v in pairs(Namedinstances) do
            if v.name == setName then
                instanceSource = k
            end
        end
 
        if instanceSource == nil then
            instanceSource = math.random(1, 63)
 
            while Namedinstances[instanceSource] and #Namedinstances[instanceSource] >= 1 do
                instanceSource = math.random(1, 63)
                Citizen.Wait(1)
            end
        end
    end
 
    if instanceSource ~= 0 then
 
        if not Namedinstances[instanceSource] then
            Namedinstances[instanceSource] = {
                name = setName,
                people = {}
            }
        end
 
        table.insert(Namedinstances[instanceSource].people, src)
 
    end
 
    SetPlayerRoutingBucket(
        src --[[ string ]], 
        instanceSource
    )
    print('[INSTANCES] Named Instances now look like this: ', json.encode(Namedinstances))
end)