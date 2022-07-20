local QBCore = exports['qb-core']:GetCoreObject()

local Races = {
    RaceType = nil,
    RaceLaps = nil,
    RaceTrack = nil,
    RaceFinish = nil,
    RaceJoin = nil,
    RaceDrivers = {},
    Zone = nil,
    Zonecombo = nil,
}
local CurrentRace
local Marker
local Joined

CurrentRaceData = {
    RaceIndex = nil,
    RaceType = nil,
    RaceLaps = nil,
    RaceTrack = nil,
    RaceDrivers = 0,
    RaceStarted = false,
    Checkpoints = {},
    CurrentCheckpoint = 0,
    NextCheckpoint = 1,
    CurrentLap = 0,
    CurrentPos = 0,
    LapValue = 0,
    TotalValue = 0,
    BestLapValue = 0,
    SecurityTime = 0,
}

local function DrawText3Ds(x, y, z, text)
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function CreateRaceZone(index)
    Races[index].Zone = BoxZone:Create(
        Races[index].RaceJoin, 20, 20, {
            minZ = Races[index].RaceJoin.z - 1,
            maxZ = Races[index].RaceJoin.z + 4,
            name = Races[index].RaceType,
            debugPoly = false,
            heading = 0
        })
        Races[index].Zonecombo = ComboZone:Create({Races[index].Zone}, {name = "box"..Races[index].RaceType, debugPoly = false})
        Races[index].Zonecombo:onPlayerInOut(function(isPointInside)
            if isPointInside then
                CurrentRace = index
                Marker = true
                exports['qb-core']:DrawText(Lang:t("race_join"), 'left')
            else
                if index == CurrentRace then
                    Marker = false
                    CurrentRace = nil
                    exports['qb-core']:HideText()
                end
            end
        end
    )
end

local function DestroyZone(index)
    if Races[index] then
        Races[index].Zonecombo:destroy()
        Races[index].Zone:destroy()            
    end
end

local function RaceUI()
    CreateThread(function()
        while true do
            if CurrentRaceData.RaceStarted then
                SendNUIMessage({
                    action = "Update",
                    type = "race",
                    data = {
                        CurrentCheckpoint = CurrentRaceData.CurrentCheckpoint,
                        TotalCheckpoints = #CurrentRaceData.Checkpoints,
                        TotalLaps = CurrentRaceData.RaceLaps,
                        CurrentLap = CurrentRaceData.CurrentLap,
                        Position = CurrentRaceData.CurrentPos,
                        Drivers = CurrentRaceData.RaceDrivers,
                        LapValue = CurrentRaceData.LapValue,
                        TotalValue = CurrentRaceData.TotalValue,
                        BestLapValue = CurrentRaceData.BestLapValue,
                        Type = CurrentRaceData.RaceType,
                    },
                    active = true,
                })
                Wait(200)
            else
                SendNUIMessage({
                    action = "Update",
                    type = "race",
                    data = {},
                    active = false,
                })
                break
            end
        end
    end)
end

local function SetupRace(id)
    if Races[id].RaceTrack ~= "no" then
        for k, v in pairs(Config.Tracks[Races[id].RaceTrack].checkpoints) do
            ClearAreaOfObjects(v.offset.left.x, v.offset.left.y, v.offset.left.z, 50.0, 0)
            local pileleft = CreateObject('prop_offroad_tyres02', v.offset.left.x, v.offset.left.y, v.offset.left.z, 0, 0, 0)
            PlaceObjectOnGroundProperly(pileleft)
            --FreezeEntityPosition(pileleft, 1)
            SetEntityAsMissionEntity(pileleft, 1, 1)
    
            ClearAreaOfObjects(v.offset.right.x, v.offset.right.y, v.offset.right.z, 50.0, 0)
            local pileright = CreateObject('prop_offroad_tyres02', v.offset.right.x, v.offset.right.y, v.offset.right.z, 0, 0, 0)
            PlaceObjectOnGroundProperly(pileright)
            --FreezeEntityPosition(pileright, 1)
            SetEntityAsMissionEntity(pileright, 1, 1)
    
            local blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
            SetBlipSprite(blip, 1)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, 0.6)
            SetBlipAsShortRange(blip, true)
            SetBlipColour(blip, 26)
            ShowNumberOnBlip(blip, k)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(Lang:t("creator_checkpoint", {value = k}))
            EndTextCommandSetBlipName(blip)

            CurrentRaceData.Checkpoints[k] = {
                pileleft = pileleft,
                pileright = pileright,
                blip = blip,
            }
        end
    else
        local blip = AddBlipForCoord(Races[id].RaceFinish.x, Races[id].RaceFinish.y, Races[id].RaceFinish.z)
        SetBlipSprite(blip, 1)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 1.0)
        SetBlipAsShortRange(blip, true)
        SetBlipColour(blip, 26)
        ShowNumberOnBlip(blip, 1)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Lang:t("creator_checkpoint", {value = 1}))
        EndTextCommandSetBlipName(blip)
        CurrentRaceData.Checkpoints[1] = {
            blip = blip,
        }
    end
end

local function showNonLoopParticle(dict, particleName, coords, scale, time)
    RequestNamedPtfxAsset(dict)
    while not HasNamedPtfxAssetLoaded(dict) do
        Wait(0)
    end
    UseParticleFxAssetNextCall(dict)
    local particleHandle = StartParticleFxLoopedAtCoord(particleName, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, scale, false, false, false)
    SetParticleFxLoopedColour(particleHandle, 0, 255, 0 ,0)
    return particleHandle
end

local function DoPilePfx()
    if CurrentRaceData.Checkpoints[CurrentRaceData.CurrentCheckpoint] ~= nil then
        local Timeout = 500
        local Size = 2.0
        local left = showNonLoopParticle('core', 'ent_sht_flame', Config.Tracks[CurrentRaceData.RaceTrack].checkpoints[CurrentRaceData.CurrentCheckpoint].offset.left, Size)
        local right = showNonLoopParticle('core', 'ent_sht_flame', Config.Tracks[CurrentRaceData.RaceTrack].checkpoints[CurrentRaceData.CurrentCheckpoint].offset.right, Size)

        SetTimeout(Timeout, function()
            StopParticleFxLooped(left, false)
            StopParticleFxLooped(right, false)
        end)
    end
end

local function GetMaxDistance(OffsetCoords)
    local Distance = #(vector3(OffsetCoords.left.x, OffsetCoords.left.y, OffsetCoords.left.z) - vector3(OffsetCoords.right.x, OffsetCoords.right.y, OffsetCoords.right.z))
    local Retval = 7.5
    if Distance > 20.0 then
        Retval = 12.5
    end
    return Retval
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

local function FinishRace()
    DoPilePfx()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsUsing(ped)
    local vehiclename = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    TriggerServerEvent('qb-races:server:FinishRace', CurrentRaceData.RaceIndex, CurrentRaceData.BestLapValue, CurrentRaceData.TotalValue, vehiclename, false)
    local type = CurrentRaceData.RaceType
    if type == "train" then
        type = "race"
    end
    if type == "drift" then
        if CurrentRaceData.BestLapValue ~= 0 then
            QBCore.Functions.Notify(Lang:t("message_"..type.."_finished_best", {value = CurrentRaceData.TotalValue, value2 = CurrentRaceData.BestLapValue}))
        else
            QBCore.Functions.Notify(Lang:t("message_"..type.."_finished", {value = CurrentRaceData.TotalValue}))
        end            
    else
        if CurrentRaceData.BestLapValue ~= 0 then
            QBCore.Functions.Notify(Lang:t("message_"..type.."_finished_best", {value = SecondsToClock(CurrentRaceData.TotalValue), value2 = SecondsToClock(CurrentRaceData.BestLapValue)}))
        else
            QBCore.Functions.Notify(Lang:t("message_"..type.."_finished", {value = SecondsToClock(CurrentRaceData.TotalValue)}))
        end            
                
    end

    if CurrentRaceData.RaceType == "drift" then
        TriggerEvent('qb-races:client:ToggleDrift')
    end

    for k, v in pairs(CurrentRaceData.Checkpoints) do
        DeleteObject(v.pileleft)
        DeleteObject(v.pileright)
        RemoveBlip(v.blip)
    end
    CurrentRaceData.RaceIndex = nil
    CurrentRaceData.RaceType = nil
    CurrentRaceData.RaceLaps = 0
    CurrentRaceData.RaceTrack = nil
    CurrentRaceData.RaceDrivers = 0

    CurrentRaceData.Checkpoints = {}
    CurrentRaceData.RaceStarted = false
    CurrentRaceData.CurrentCheckpoint = 0
    CurrentRaceData.CurrentLap = 0
end

local function CancelRace(reason)
    CurrentRaceData.BestLapValue = 0
    CurrentRaceData.TotalValue = 0

    TriggerServerEvent('qb-races:server:FinishRace', CurrentRaceData.RaceIndex, CurrentRaceData.BestLapValue, CurrentRaceData.TotalValue, "", true)
    if reason == "TO" then
        QBCore.Functions.Notify(Lang:t("error_race_timeout"), 'error')
    elseif reason == "CA" then
        QBCore.Functions.Notify(Lang:t("error_race_cancelled"), 'error')
    end
    

    if CurrentRaceData.RaceType == "drift" then
        TriggerEvent('qb-races:client:ToggleDrift')
    end

    for k, v in pairs(CurrentRaceData.Checkpoints) do
        DeleteObject(v.pileleft)
        DeleteObject(v.pileright)
        RemoveBlip(v.blip)
    end
    CurrentRaceData.RaceIndex = nil
    CurrentRaceData.RaceType = nil
    CurrentRaceData.RaceLaps = 0
    CurrentRaceData.RaceTrack = nil
    CurrentRaceData.RaceDrivers = 0

    CurrentRaceData.Checkpoints = {}
    CurrentRaceData.RaceStarted = false
    CurrentRaceData.CurrentCheckpoint = 0
    CurrentRaceData.CurrentLap = 0
    TriggerServerEvent('instance:setNamed', 0)

end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
	QBCore.Functions.TriggerCallback('qb-races:server:GetRaces', function(result)
        for k, v in pairs(result) do
            Races[k] = v
            CreateRaceZone(k)
        end
	end)
end)

RegisterNetEvent('qb-races:client:CancelRace', function()
    CancelRace("CA")
end)

RegisterNetEvent('qb-races:client:CreateRace', function(data, id)
    Races[id] = data
    CreateRaceZone(id)
end)

RegisterNetEvent('qb-races:client:RemoveRace', function(id)
    DestroyZone(id)
    Marker = false
end)

RegisterNetEvent('qb-races:client:GetPosition', function(position)
    CurrentRaceData.CurrentPos = position
end)

RegisterNetEvent('qb-races:client:CountdownRace', function(id, drivers, best)
    SetupRace(id)
    if Races[id].RaceTrack ~= "no" then
        SetNewWaypoint(Config.Tracks[Races[id].RaceTrack].checkpoints[1].coords.x, Config.Tracks[Races[id].RaceTrack].checkpoints[1].coords.y)
    else
        SetNewWaypoint(Races[id].RaceFinish.x, Races[id].RaceFinish.y)
    end
    CurrentRaceData.RaceIndex = id
    CurrentRaceData.RaceType = Races[id].RaceType
    CurrentRaceData.RaceLaps = Races[id].RaceLaps
    CurrentRaceData.RaceTrack = Races[id].RaceTrack
    CurrentRaceData.RaceFinish = Races[id].RaceFinish
    CurrentRaceData.RaceDrivers = drivers
    CurrentRaceData.CurrentCheckpoint = 0
    CurrentRaceData.NextCheckpoint = 1
    CurrentRaceData.CurrentLap = 1
    CurrentRaceData.BestLapValue = best
    CurrentRaceData.LapValue = 0
    CurrentRaceData.CurrentPos = 0
    CurrentRaceData.TotalValue = 0
    CurrentRaceData.SecurityTime = 0


    if CurrentRaceData.RaceType == "drift" then
        TriggerEvent('qb-races:client:ToggleDrift')
    end

    local countdownRace = 5

    while countdownRace ~= 0 do
        FreezeEntityPosition(GetVehiclePedIsIn(PlayerPedId(), true), true)
        PlaySound(-1, "slow", "SHORT_PLAYER_SWITCH_SOUND_SET", 0, 0, 1)
        QBCore.Functions.Notify(countdownRace, 'primary', 800)
        Wait(1000)
        countdownRace = countdownRace - 1
    end

    CurrentRaceData.RaceStarted = true
    RaceUI()
    Joined = false
    FreezeEntityPosition(GetVehiclePedIsIn(PlayerPedId(), true), false)
    QBCore.Functions.Notify(Lang:t("message_go"), 'success')
end)



CreateThread(function()
    local wait
    while true do
        if CurrentRace and Marker then
            local racename
            if Races[CurrentRace].RaceTrack == "no" then
                racename = "Waypoint"
            else
                racename = Config.Tracks[Races[CurrentRace].RaceTrack].name
            end
            DrawText3Ds(Races[CurrentRace].RaceJoin.x, Races[CurrentRace].RaceJoin.y, Races[CurrentRace].RaceJoin.z + 1, Lang:t("message_race_details", {value = racename, value1 = Races[CurrentRace].RaceType, value2 = Races[CurrentRace].RaceLaps, value3 = Races[CurrentRace].RaceFee}))
            if IsControlJustReleased(0, 38) then    --Press E to join the race
                local ped = PlayerPedId()
                local vehicle = GetVehiclePedIsUsing(ped)
                local vehiclename = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
                QBCore.Functions.TriggerCallback('qb-races:server:JoinRace', function(result)
                    if result then
                        QBCore.Functions.Notify(Lang:t("message_added_to_race"), "success")
                        Marker = false
                        Joined = true
                        DestroyZone(CurrentRace)
                        exports['qb-core']:HideText()
                        if Races[CurrentRace].RaceType == "train" then
                            Wait(3000)
                            TriggerServerEvent('qb-races:server:StartRace')
                        end
                    else
                        QBCore.Functions.Notify(Lang:t("error_added_to_race"), "error")
                    end
                end, CurrentRace, vehiclename)
            end
            Wait(0)
        elseif CurrentRace and Joined and Races[CurrentRace].RaceTrack ~= "no" then
            DrawText3Ds(Config.Tracks[Races[CurrentRace].RaceTrack].checkpoints[1].coords.x, Config.Tracks[Races[CurrentRace].RaceTrack].checkpoints[1].coords.y, Config.Tracks[Races[CurrentRace].RaceTrack].checkpoints[1].coords.z, Lang:t("race_start"))
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    while true do
        if CurrentRaceData.RaceStarted then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)

            if CurrentRaceData.RaceTrack ~= "no" then
                local data = Config.Tracks[CurrentRaceData.RaceTrack].checkpoints[CurrentRaceData.NextCheckpoint]
                local CheckpointDistance = #(pos - vector3(data.coords.x, data.coords.y, data.coords.z))
                local MaxDistance = GetMaxDistance(Config.Tracks[CurrentRaceData.RaceTrack].checkpoints[CurrentRaceData.NextCheckpoint].offset)
                TriggerServerEvent('qb-races:server:SendPosition', CurrentRace, CheckpointDistance, CurrentRaceData.CurrentCheckpoint, CurrentRaceData.CurrentLap)
                if CheckpointDistance < MaxDistance then
                    CurrentRaceData.CurrentCheckpoint = CurrentRaceData.CurrentCheckpoint + 1
                    CurrentRaceData.NextCheckpoint = CurrentRaceData.NextCheckpoint + 1
                    if CurrentRaceData.CurrentCheckpoint == #Config.Tracks[CurrentRaceData.RaceTrack].checkpoints then
                        CurrentRaceData.NextCheckpoint = 1
                    elseif CurrentRaceData.CurrentCheckpoint > #Config.Tracks[CurrentRaceData.RaceTrack].checkpoints then
                        CurrentRaceData.CurrentCheckpoint = 1
                        if CurrentRaceData.CurrentLap + 1 > CurrentRaceData.RaceLaps then
                            if CurrentRaceData.RaceType == "drift" then
                                if CurrentRaceData.BestLapValue < CurrentRaceData.LapValue then
                                    CurrentRaceData.BestLapValue = CurrentRaceData.LapValue
                                end
                            else
                                if CurrentRaceData.BestLapValue == 0 or CurrentRaceData.BestLapValue > CurrentRaceData.LapValue then
                                    CurrentRaceData.BestLapValue = CurrentRaceData.LapValue
                                end    
                            end
                            FinishRace()
                        else
                            CurrentRaceData.CurrentLap = CurrentRaceData.CurrentLap + 1
                            if CurrentRaceData.RaceType == "drift" then
                                if CurrentRaceData.BestLapValue < CurrentRaceData.LapValue then
                                    CurrentRaceData.BestLapValue = CurrentRaceData.LapValue
                                end
                            else
                                if CurrentRaceData.BestLapValue == 0 or CurrentRaceData.BestLapValue > CurrentRaceData.LapValue then
                                    CurrentRaceData.BestLapValue = CurrentRaceData.LapValue
                                end
                            end
                            CurrentRaceData.LapValue = 0
                        end
                    end
                    if CurrentRaceData.RaceStarted then
                        DoPilePfx()    
                        SetNewWaypoint(Config.Tracks[CurrentRaceData.RaceTrack].checkpoints[CurrentRaceData.NextCheckpoint].coords.x, Config.Tracks[CurrentRaceData.RaceTrack].checkpoints[CurrentRaceData.NextCheckpoint].coords.y)
                        --TriggerServerEvent('qb-lapraces:server:UpdateRacerData', CurrentRaceData.RaceId, CurrentRaceData.CurrentCheckpoint, CurrentRaceData.Lap, false)
                        PlaySound(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0, 0, 1)
                        SetBlipScale(CurrentRaceData.Checkpoints[CurrentRaceData.CurrentCheckpoint].blip, 0.6)
                        SetBlipScale(CurrentRaceData.Checkpoints[CurrentRaceData.NextCheckpoint].blip, 1.0)
                    end
                end
            else
                local CheckpointDistance = #(vector2(pos.x, pos.y) - vector2(CurrentRaceData.RaceFinish.x, CurrentRaceData.RaceFinish.y))
                TriggerServerEvent('qb-races:server:SendPosition', CurrentRace, CheckpointDistance, nil, nil)
                if CheckpointDistance < 15 then
                    FinishRace()
                end
            end
            Wait(100)
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    while true do
        if CurrentRaceData.RaceStarted then
            if CurrentRaceData.RaceType ~= "drift" then
                CurrentRaceData.LapValue = CurrentRaceData.LapValue + 1
                CurrentRaceData.TotalValue = CurrentRaceData.TotalValue + 1                    
            end
            CurrentRaceData.SecurityTime = CurrentRaceData.SecurityTime + 1
            if CurrentRaceData.RaceTrack ~= "no" and CurrentRaceData.SecurityTime >= ( Config.Tracks[CurrentRaceData.RaceTrack].securitytime * CurrentRaceData.RaceLaps ) then
                CancelRace("TO")
            end
            Wait(100)
        else
            Wait(1000)
        end
    end
end)
