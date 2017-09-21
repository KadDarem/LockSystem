------------------------------ 
------- SCRIPT PARAMETERS ----
------------------------------

local distanceParam = 5.0 
local key = 303 -- Press U



RegisterNetEvent('hud:NotifColor')
AddEventHandler('hud:NotifColor', function(txt,color)
    txt=tostring(txt)
    SetNotificationTextEntry('STRING')
    Citizen.InvokeNative(0x92F0DA1E27DB96DC , color)
    AddTextComponentString(txt)
    DrawNotification(false, false)    
end)


local lastCar = {lastcar=0, lastmodel = 0 , lastplate = 0, lockStatus }

local lock_Car = {car=0, model = 0 , plate = 0}

local timer = 0

local notif = false
local reset = false
local timereset = 2000
Citizen.CreateThread(function() 
    while true do 
        Wait(0) 
        if IsControlJustPressed(1,key) then
            timer = GetGameTimer()
            notif = true
            reset = true
        end
        if IsControlJustReleased(1, key) and GetGameTimer() - timer < timereset then
            notif = false
            local player = GetPlayerPed(-1)
            local FixAction = IsPedGettingIntoAVehicle(player)
            local targetVehicle = nil
            local targetplate = nil
            local targetname = nil
            local targetmodel = nil
            GetLastCar()
                
            if lock_Car.plate == 0 then
                if lastCar.lockStatus then 
                    TriggerEvent('hud:NotifColor',"Véhicule déjà fermé",6)
                elseif not FixAction then
                    if lastCar.lastplate ~= nil then 
                        lock_Car.car = lastCar.lastcar
                        lock_Car.model = lastCar.lastmodel
                        lock_Car.plate = lastCar.lastplate
                        SetVehicleDoorsLockedForAllPlayers(lock_Car.car, true)
                        TriggerEvent('hud:NotifColor',"Ω  Véhicule ~h~fermé",6)
                        TriggerEvent('InteractSound_CL:PlayOnOne', 'lock', 1.0)
                    end
                end
            elseif lock_Car.plate ~= 0 then
                if lastCar.lastplate ~= nil then
                    if not FixAction then
                        if (lastCar.lastplate == lock_Car.plate and lastCar.lastmodel == lock_Car.model) then
                            SetVehicleDoorsLockedForAllPlayers(lastCar.lastcar, false)
                            lock_Car = {car=0, model = 0 , plate = 0 }
                            TriggerEvent('hud:NotifColor',"Ω  Véhicule ~h~ouvert",141)
                            TriggerEvent('InteractSound_CL:PlayOnOne', 'unlock', 1.0)
                            SetVehicleEngineOn(lastCar.lastcar, true, false, false)
                        else
                            TriggerEvent('hud:NotifColor',"Ce n'est pas votre véhicule",6)
                        end
                    end
                else
                    TriggerEvent('hud:NotifColor',"Véhicule trop éloigné",6)
                end
            end
        elseif IsControlPressed(1,key) and GetGameTimer() - timer > timereset and reset then
            notif = false
            reset = false
            lock_Car = {car=0, model = 0 , plate = 0 }
            lastCar = {lastcar=0, lastmodel = 0 , lastplate = 0, lockStatus }
            TriggerEvent('hud:NotifColor',"Ω Clé ~h~réinitialisé",200)
            TriggerEvent('InteractSound_CL:PlayOnOne', 'demo', 1.0)
        end
    end
end)

Citizen.CreateThread(function() 
    while true do
        Wait(0)
            if notif then
                Wait(500)
                local compteur = 0
                while IsControlPressed(1,key) and notif do
                    compteur = compteur + 10
                    local width = (compteur / (timereset))*0.18
                    Wait(10)
                    DrawRect(0.894, 0.969, 0.193, 0.033, 0, 0, 0, 150)
                    DrawAdvancedText(0.896, 0.973, 0.005, 0.0028, 0.287, "REINITIALISATION CLE", 255, 255, 255, 255, 0, 1)
                    DrawRect(0.943, 0.968, 0.08, 0.015, 106, 0, 0, 174)
                    DrawRect(0.900 + width/2 , 0.968, width , 0.015, 181, 0, 0, 255)
                end
            end
    end
end)

function DrawAdvancedText(x,y ,w,h,sc, text, r,g,b,a,font,jus)
    SetTextFont(font)
    SetTextProportional(0)
    SetTextScale(sc, sc)
	N_0x4e096588b13ffeca(jus)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
	DrawText(x - 0.1+w, y - 0.02+h)
end

function getVehicleInDirection(coordFrom, coordTo)
	local rayHandle = CastRayPointToPoint(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10, GetPlayerPed(-1), 0)
	local a, b, c, d, vehicle = GetRaycastResult(rayHandle)
	return vehicle
end    
    
function GetPosition(lastCar, player)
    posCar = GetEntityCoords(lastCar.car, false)
    carX, carY, carZ = posCar.x, posCar.y, posCar.z 

    posPlayer = GetEntityCoords(player, false) 
    playerX, playerY, playerZ = posPlayer.x, posPlayer.y, posPlayer.z
    return
end

function GetLastCar()
    if IsPedInAnyVehicle(GetPlayerPed(-1)) then
        local car = GetVehiclePedIsIn(GetPlayerPed(-1), true)
        lastCar.lastcar = car
        lastCar.lastplate = GetVehicleNumberPlateText(car)
        lastCar.lastmodel = GetDisplayNameFromVehicleModel(GetEntityModel(car))
        lastCar.lockStatus = GetVehicleDoorsLockedForPlayer(car,GetPlayerPed(-1)) 
    else
        local playerped = GetPlayerPed(-1)	
        local coordA = GetEntityCoords(playerped, 1)
        local coordB = GetOffsetFromEntityInWorldCoords(playerped, 0.0, distanceParam, 0.0)
        targetVehicle = getVehicleInDirection(coordA, coordB)
        if targetVehicle  ~= nil then
            lastCar.lastcar = targetVehicle
            lastCar.lastplate = GetVehicleNumberPlateText(targetVehicle)
            lastCar.lastmodel = GetDisplayNameFromVehicleModel(GetEntityModel(targetVehicle))
            lastCar.lockStatus = GetVehicleDoorsLockedForPlayer(targetVehicle,GetPlayerPed(-1)) 
        end
    end
end