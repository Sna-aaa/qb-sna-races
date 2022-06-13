local QBCore = exports['qb-core']:GetCoreObject()

-- https://runtime.fivem.net/doc/natives/?_0x29439776AAA00A62
local vehicleClassWhitelist = {0, 1, 2, 3, 4, 5, 6, 7, 9}

local handleMods = {
	{"fInitialDragCoeff", 90.22},
	{"fDriveInertia", .31},
	{"fSteeringLock", 22},
	{"fTractionCurveMax", -1.1},
	{"fTractionCurveMin", -.4},
	{"fTractionCurveLateral", 2.5},
	{"fLowSpeedTractionLossMult", -.57}
}
local driftMode = false
local driftVehicle = nil


local driftScore = 0
local driftTotalScore = 0
local drifting = false
local driftTime = 0


local function DrawNotif(text)
	SetNotificationTextEntry("STRING")
	AddTextComponentString(text)
	DrawNotification(false, false)
end

local function IsVehicleClassWhitelisted(vehicleClass)
	for index, value in ipairs(vehicleClassWhitelist) do
		if value == vehicleClass then
			return true
		end
	end
	return false
end

local function ToggleDrift(vehicle)
	local modifier
	if GetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDragCoeff") > 90 then
		driftMode = false
		modifier = -1
		DrawNotif(Lang:t("drift_disable"))
	else 
		driftMode = true
		modifier = 1
		driftTotalScore = 0
		DrawNotif(Lang:t("drift_enable"))
	end
	for index, value in ipairs(handleMods) do
		SetVehicleHandlingFloat(vehicle, "CHandlingData", value[1], GetVehicleHandlingFloat(vehicle, "CHandlingData", value[1]) + value[2] * modifier)
	end
end

RegisterNetEvent('smallresource:client:ToggleDrift', function()
	local playerPed = PlayerPedId()
	if IsPedInAnyVehicle(playerPed) then
		driftVehicle = GetVehiclePedIsIn(playerPed, false)
		if GetPedInVehicleSeat(driftVehicle, -1) == playerPed and IsVehicleClassWhitelisted(GetVehicleClass(driftVehicle)) then
			QBCore.Functions.Progressbar("use_drift", Lang:t("drift_config"), 1000, false, true, {
				disableMovement = false,
				disableCarMovement = false,
				disableMouse = false,
				disableCombat = true,
			}, {}, {}, {}, function() -- Done
				ToggleDrift(driftVehicle)
			end)
		end
	end
end)

RegisterNetEvent('qb-races:client:ToggleDrift', function()
	local playerPed = PlayerPedId()
	if IsPedInAnyVehicle(playerPed) then
		driftVehicle = GetVehiclePedIsIn(playerPed, false)
		ToggleDrift(driftVehicle)
	end
end)
--RegisterCommand('toggledrift', function()
--    TriggerEvent('smallresource:client:ToggleDrift')
--end, false)


local function round(number)
	number = tonumber(number)
	number = math.floor(number)
	
	if number < 0.01 then
		number = 0
	elseif number > 999999999 then
		number = 999999999
	end
	return number
end

local function angle(veh)
	if not veh then return false end
	local vx,vy,vz = table.unpack(GetEntityVelocity(veh))
	local modV = math.sqrt(vx*vx + vy*vy)
	
	
	local rx,ry,rz = table.unpack(GetEntityRotation(veh,0))
	local sn,cs = -math.sin(math.rad(rz)), math.cos(math.rad(rz))
	
	if GetEntitySpeed(veh)* 3.6 < 30 or GetVehicleCurrentGear(veh) == 0 then return 0,modV end --speed over 30 km/h
	
	local cosX = (sn*vx + cs*vy)/modV
	if cosX > 0.966 or cosX < 0 then return 0,modV end
	return math.deg(math.acos(cosX))*0.5, modV
end

local function DrawHudText(text, colour, coordsx, coordsy, scalex, scaley)
	SetTextFont(7)
	SetTextProportional(7)
	SetTextScale(scalex, scaley)
	local colourr,colourg,colourb,coloura = table.unpack(colour)
	SetTextColour(colourr,colourg,colourb, coloura)
	SetTextDropshadow(0, 0, 0, 0, coloura)
	SetTextEdge(1, 0, 0, 0, coloura)
	SetTextDropShadow()
	SetTextOutline()
	SetTextEntry("STRING")
	AddTextComponentString(text)
	EndTextCommandDisplayText(coordsx,coordsy)
end

CreateThread(function()			--Frame Thread

	while true do
		if driftMode then
			SetVehicleCheatPowerIncrease(driftVehicle, 5.0)
			if driftScore ~= 0 then
				DrawHudText(tostring(driftScore), {255, 191, 0, 255}, 0.5, 0.05, 0.7, 0.7)
			end
			--if driftTotalScore ~= 0 then
			--	DrawHudText(tostring(driftTotalScore), {255, 191, 0, 255}, 0.05, 0.6, 0.7, 0.7)
			--end
			Wait(0)
		else
			Wait(1000)
		end
	end
end)


CreateThread( function()		--Score Thread
	local tick
	local body

	while true do
		if driftMode then
			local angle,velocity = angle(driftVehicle)
			tick = GetGameTimer()

			if angle ~= 0 then
				if driftScore == 0 then		--Begin drift
					drifting = true
					body = math.ceil(GetVehicleBodyHealth(driftVehicle))
				end
				driftScore = driftScore + math.floor(angle * velocity) * 0.2	--Calculate score
				driftScore = round(driftScore)
				driftTime = tick
			end
			if drifting and body ~= math.ceil(GetVehicleBodyHealth(driftVehicle)) then		--Cancel drift if damaged
				driftScore = 0
				drifting = false
			end
			if drifting and tick - driftTime > 1850 then		--If time limit reached, add score to total
                CurrentRaceData.LapValue = CurrentRaceData.LapValue + driftScore
                CurrentRaceData.TotalValue = CurrentRaceData.TotalValue + driftScore                    
				--driftTotalScore = driftTotalScore + driftScore
				driftScore = 0
				drifting = false
			end
			Wait(100)
		else
			Wait(1000)
		end
	end
end)


