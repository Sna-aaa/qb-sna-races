local QBCore = exports['qb-core']:GetCoreObject()

local InCreator = false

local CreatorData = {
    TrackId = "",
    name = "",
    securitytime = 0,
    distance = 0,
    checkpoints = {},
    TireDistance = 3.0,
    --ConfirmDelete = false,
    ClosestCheckpoint = 0,
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

local function AddCheckpoint()
    local PlayerPed = PlayerPedId()
    local PlayerPos = GetEntityCoords(PlayerPed)
    local PlayerVeh = GetVehiclePedIsIn(PlayerPed)
    local Offset = {
        left = {
            x = (GetOffsetFromEntityInWorldCoords(PlayerVeh, -CreatorData.TireDistance, 0.0, 0.0)).x,
            y = (GetOffsetFromEntityInWorldCoords(PlayerVeh, -CreatorData.TireDistance, 0.0, 0.0)).y,
            z = (GetOffsetFromEntityInWorldCoords(PlayerVeh, -CreatorData.TireDistance, 0.0, 0.0)).z,
        },
        right = {
            x = (GetOffsetFromEntityInWorldCoords(PlayerVeh, CreatorData.TireDistance, 0.0, 0.0)).x,
            y = (GetOffsetFromEntityInWorldCoords(PlayerVeh, CreatorData.TireDistance, 0.0, 0.0)).y,
            z = (GetOffsetFromEntityInWorldCoords(PlayerVeh, CreatorData.TireDistance, 0.0, 0.0)).z,
        }
    }

    CreatorData.checkpoints[#CreatorData.checkpoints+1] = {
        coords = {
            x = PlayerPos.x,
            y = PlayerPos.y,
            z = PlayerPos.z,
        },
        offset = Offset,
    }


    for id, CheckpointData in pairs(CreatorData.checkpoints) do
        if CheckpointData.blip ~= nil then
            RemoveBlip(CheckpointData.blip)
        end

        CheckpointData.blip = AddBlipForCoord(CheckpointData.coords.x, CheckpointData.coords.y, CheckpointData.coords.z)

        SetBlipSprite(CheckpointData.blip, 1)
        SetBlipDisplay(CheckpointData.blip, 4)
        SetBlipScale(CheckpointData.blip, 0.8)
        SetBlipAsShortRange(CheckpointData.blip, true)
        SetBlipColour(CheckpointData.blip, 26)
        ShowNumberOnBlip(CheckpointData.blip, id)
        SetBlipShowCone(CheckpointData.blip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Lang:t("creator_checkpoint", {value = id}))
        EndTextCommandSetBlipName(CheckpointData.blip)
    end
end

local function DeleteCheckpoint()
    local NewCheckpoints = {}
    if RaceData.ClosestCheckpoint ~= 0 then
        if CreatorData.checkpoints[RaceData.ClosestCheckpoint] ~= nil then
            if CreatorData.checkpoints[RaceData.ClosestCheckpoint].blip ~= nil then
                RemoveBlip(CreatorData.checkpoints[RaceData.ClosestCheckpoint].blip)
                CreatorData.checkpoints[RaceData.ClosestCheckpoint].blip = nil
            end
            if CreatorData.checkpoints[RaceData.ClosestCheckpoint].pileleft ~= nil then
                local coords = CreatorData.checkpoints[RaceData.ClosestCheckpoint].offset.left
                local Obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 5.0, 'prop_offroad_tyres02', 0, 0, 0)
                DeleteObject(Obj)
                ClearAreaOfObjects(coords.x, coords.y, coords.z, 50.0, 0)
                CreatorData.checkpoints[RaceData.ClosestCheckpoint].pileleft = nil
            end
            if CreatorData.checkpoints[RaceData.ClosestCheckpoint].pileright ~= nil then
                local coords = CreatorData.checkpoints[RaceData.ClosestCheckpoint].offset.right
                local Obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 5.0, 'prop_offroad_tyres02', 0, 0, 0)
                DeleteObject(Obj)
                ClearAreaOfObjects(coords.x, coords.y, coords.z, 50.0, 0)
                CreatorData.checkpoints[RaceData.ClosestCheckpoint].pileright = nil
            end

            for id, data in pairs(CreatorData.checkpoints) do
                if id ~= RaceData.ClosestCheckpoint then
                    NewCheckpoints[#NewCheckpoints+1] = data
                end
            end
            CreatorData.checkpoints = NewCheckpoints
        else
            QBCore.Functions.Notify(Lang:t("error_too_fast"), 'error')
        end
    else
        QBCore.Functions.Notify(Lang:t("error_too_fast"), 'error')
    end
end

local function SaveRace()
    local RaceDistance = 0

    for k, v in pairs(CreatorData.checkpoints) do
        if k + 1 <= #CreatorData.checkpoints then
            local checkpointdistance = #(vector3(v.coords.x, v.coords.y, v.coords.z) - vector3(CreatorData.checkpoints[k + 1].coords.x, CreatorData.checkpoints[k + 1].coords.y, CreatorData.checkpoints[k + 1].coords.z))
            RaceDistance = RaceDistance + checkpointdistance
        end
    end

    CreatorData.distance = RaceDistance

    TriggerServerEvent('qb-races:server:SaveTrack', CreatorData, CreatorData.TrackId)

    Config.Tracks[CreatorData.TrackId] = CreatorData
    QBCore.Functions.Notify(Lang:t("success_race_saved", {value = CreatorData.name}), 'success')

    for id,_ in pairs(CreatorData.checkpoints) do
        if CreatorData.checkpoints[id].blip ~= nil then
            RemoveBlip(CreatorData.checkpoints[id].blip)
            CreatorData.checkpoints[id].blip = nil
        end
        if CreatorData.checkpoints[id] ~= nil then
            if CreatorData.checkpoints[id].pileleft ~= nil then
                local coords = CreatorData.checkpoints[id].offset.left
                local Obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 5.0, 'prop_offroad_tyres02', 0, 0, 0)
                DeleteObject(Obj)
                ClearAreaOfObjects(coords.x, coords.y, coords.z, 50.0, 0)
                CreatorData.checkpoints[id].pileleft = nil
            end
            if CreatorData.checkpoints[id].pileright ~= nil then
                local coords = CreatorData.checkpoints[id].offset.right
                local Obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 5.0, 'prop_offroad_tyres02', 0, 0, 0)
                DeleteObject(Obj)
                ClearAreaOfObjects(coords.x, coords.y, coords.z, 50.0, 0)
                CreatorData.checkpoints[id].pileright = nil
            end
        end
    end

    InCreator = false
    CreatorData.name = ""
    CreatorData.checkpoints = {}
end

local function CreatorLoop()
    CreateThread(function()
        while InCreator do
            local PlayerPed = PlayerPedId()
            local PlayerVeh = GetVehiclePedIsIn(PlayerPed)

            if PlayerVeh ~= 0 then
                if IsControlJustPressed(0, 161) or IsDisabledControlJustPressed(0, 161) then
                    AddCheckpoint()
                end

                if IsControlJustPressed(0, 162) or IsDisabledControlJustPressed(0, 162) then
                    if CreatorData.checkpoints ~= nil and next(CreatorData.checkpoints) ~= nil then
                        DeleteCheckpoint()
                    else
                        QBCore.Functions.Notify(Lang:t("error_no_checkpoint"), 'error')
                    end
                end

                if IsControlJustPressed(0, 311) or IsDisabledControlJustPressed(0, 311) then
                    if CreatorData.checkpoints ~= nil and #CreatorData.checkpoints >= 2 then
                        SaveRace()
                    else
                        QBCore.Functions.Notify(Lang:t("error_not_enough_points"), 'error')
                    end
                end

                if IsControlJustPressed(0, 40) or IsDisabledControlJustPressed(0, 40) then
                    if CreatorData.TireDistance + 1.0 ~= 16.0 then
                        CreatorData.TireDistance = CreatorData.TireDistance + 1.0
                    else
                        QBCore.Functions.Notify(Lang:t("error_maxwidth"))
                    end
                end

                if IsControlJustPressed(0, 39) or IsDisabledControlJustPressed(0, 39) then
                    if CreatorData.TireDistance - 1.0 ~= 1.0 then
                        CreatorData.TireDistance = CreatorData.TireDistance - 1.0
                    else
                        QBCore.Functions.Notify(Lang:t("error_minwidth"))
                    end
                end
            else
                local coords = GetEntityCoords(PlayerPedId())
                DrawText3Ds(coords.x, coords.y, coords.z, Lang:t("error_must_be_in_vehicle"))
            end

            if IsControlJustPressed(0, 163) or IsDisabledControlJustPressed(0, 163) then
                if not CreatorData.ConfirmDelete then
                    CreatorData.ConfirmDelete = true
                    QBCore.Functions.Notify(Lang:t("message_confirm"), 'primary', 5000)
                else
                    for id, CheckpointData in pairs(CreatorData.checkpoints) do
                        if CheckpointData.blip ~= nil then
                            RemoveBlip(CheckpointData.blip)
                        end
                    end

                    for id,_ in pairs(CreatorData.checkpoints) do
                        if CreatorData.checkpoints[id].pileleft ~= nil then
                            local coords = CreatorData.checkpoints[id].offset.left
                            local Obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 8.0, 'prop_offroad_tyres02', 0, 0, 0)
                            DeleteObject(Obj)
                            ClearAreaOfObjects(coords.x, coords.y, coords.z, 50.0, 0)
                            CreatorData.checkpoints[id].pileleft = nil
                        end

                        if CreatorData.checkpoints[id].pileright ~= nil then
                            local coords = CreatorData.checkpoints[id].offset.right
                            local Obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 8.0, 'prop_offroad_tyres02', 0, 0, 0)
                            DeleteObject(Obj)
                            ClearAreaOfObjects(coords.x, coords.y, coords.z, 50.0, 0)
                            CreatorData.checkpoints[id].pileright = nil
                        end
                    end

                    RaceData.InCreator = false
                    CreatorData.RaceName = nil
                    CreatorData.checkpoints = {}
                    QBCore.Functions.Notify(Lang:t("message_editor_cancelled"), 'error')
                    CreatorData.ConfirmDelete = false
                end
            end
            Wait(0)
        end
    end)
end

CreateThread(function()
    while true do
        if InCreator then
            local PlayerPed = PlayerPedId()
            local PlayerVeh = GetVehiclePedIsIn(PlayerPed)

            if PlayerVeh then
                local Offset = {
                    left = {
                        x = (GetOffsetFromEntityInWorldCoords(PlayerVeh, -CreatorData.TireDistance, 0.0, 0.0)).x,
                        y = (GetOffsetFromEntityInWorldCoords(PlayerVeh, -CreatorData.TireDistance, 0.0, 0.0)).y,
                        z = (GetOffsetFromEntityInWorldCoords(PlayerVeh, -CreatorData.TireDistance, 0.0, 0.0)).z,
                    },
                    right = {
                        x = (GetOffsetFromEntityInWorldCoords(PlayerVeh, CreatorData.TireDistance, 0.0, 0.0)).x,
                        y = (GetOffsetFromEntityInWorldCoords(PlayerVeh, CreatorData.TireDistance, 0.0, 0.0)).y,
                        z = (GetOffsetFromEntityInWorldCoords(PlayerVeh, CreatorData.TireDistance, 0.0, 0.0)).z,
                    }
                }

                DrawText3Ds(Offset.left.x, Offset.left.y, Offset.left.z, Lang:t("creator_checkpoint_l"))
                DrawText3Ds(Offset.right.x, Offset.right.y, Offset.right.z, Lang:t("creator_checkpoint_r"))
            end
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

local function CreatorUI()
    CreateThread(function()
        while true do
            if InCreator then
                SendNUIMessage({
                    action = "Update",
                    type = "creator",
                    data = CreatorData,
                    active = true,
                })
                Wait(200)
            else
                SendNUIMessage({
                    action = "Update",
                    type = "creator",
                    data = CreatorData,
                    active = false,
                })
                break
            end
        end
    end)
end

RegisterNetEvent('qb-races:client:CreateTrack', function(id, name, security)
    if not InCreator then
        CreatorData.name = name
        CreatorData.TrackId = id
        CreatorData.securitytime = security
        InCreator = true
        CreatorUI()
        CreatorLoop()
    else
        QBCore.Functions.Notify(Lang:t("error_already_track"), 'error')
    end
end)