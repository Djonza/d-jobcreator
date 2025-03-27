lib.locale()

local nuiVisible = false

function openJobManager()
    if not nuiVisible then
        SetNuiFocus(true, true)
        SendNUIMessage({ action = "open" })
        nuiVisible = true
    end
end

function closeJobManager()
    if nuiVisible then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "close" })
        nuiVisible = false
    end
end


RegisterCommand(Config.openJobCreator, function(source, args, rawCommand)
    local playerData = ESX.GetPlayerData()
    local allowed = false

    for _, group in ipairs(Config.AllowedGroups) do
        if playerData.group == group then
            allowed = true
            break
        end
    end

    if allowed then
        TriggerServerEvent('d-jobcreator:requestJobsList')
        openJobManager()
    else
        sendNotification('error', locale('no_permissions'), 3000)
        return false
    end
end, false)

RegisterNUICallback('close', function(data, cb)
    closeJobManager()
    cb('ok')
end)

RegisterNUICallback('addJob', function(data, cb)
    playerSource = source
    TriggerServerEvent('d-jobcreator:addJob', data) 
    cb({ status = "ok" })
end)

RegisterNUICallback('addJobGrade', function(data, cb)
    playerSource = source
    TriggerServerEvent('d-jobcreator:addJobGrade', data) 
    cb({ status = "ok" })
end)


RegisterNetEvent('d-jobcreator:receiveJobsList')
AddEventHandler('d-jobcreator:receiveJobsList', function(jobs)
    SendNUIMessage({
        type = 'jobsList',
        jobs = jobs
    })
end)

RegisterNUICallback('getJobGrades', function(data, cb)
    local jobName = data.jobName 
    TriggerServerEvent('d-jobcreator:getJobGrades', jobName)
    cb('ok')
end)

RegisterNetEvent('d-jobcreator:receiveJobGrades')
AddEventHandler('d-jobcreator:receiveJobGrades', function(grades)
    SendNUIMessage({
        type = 'jobGrades',
        grades = grades
    })
end)

RegisterNUICallback('updateJobGrades', function(data, cb)
    local playerSource = source
    if data and data.data then
        TriggerServerEvent('d-jobcreator:updateJobGrades', data.data)
    else
        print("ERROR: No data received from NUI")
    end
    cb('ok')
end)



RegisterNUICallback('deleteJobGrade', function(data, cb)
    playerSource = source
    TriggerServerEvent('d-jobcreator:deleteJobGrade', data.job_name, data.grade)
    cb("success")
end)


RegisterNUICallback('deleteJob', function(data, cb)
    playerSource = source
    TriggerServerEvent('d-jobcreator:deleteJob', data.job_name)
    cb("success")
end)

function sendNotification(type, message, duration)
    if Config.NotificationSystem == "djonza" then
    showNotification(type, message, duration)
     elseif Config.NotificationSystem == "ox_lib" then
        exports['ox_lib']:notify({
            title = title, 
            description = message,
            type = type,           
        })
    elseif Config.NotificationSystem == "esx" then
        ESX.ShowNotification(message)
    elseif Config.NotificationSystem == "custom" then
        TriggerEvent('your_custom_notify', message)
    else
        print("Unknown notification system!")
        end
    end

    RegisterNetEvent("sendNotificationClient")
    AddEventHandler("sendNotificationClient", function(type, message, duration)
        sendNotification(type, message, duration)
    end)

RegisterNetEvent('showNotification')
AddEventHandler('showNotification', function(type, message, duration)
    SendNUIMessage({
        action = 'showNotification',
        type = type,
        message = message,
        duration = duration,
    })
end)


function showNotification(type, message, duration)
    SendNUIMessage({
        action = 'showNotification',
        type = type,
        message = message,
        duration = duration
    })
end

RegisterNetEvent('d-jobcreator:receiveGarages')
AddEventHandler('d-jobcreator:receiveGarages', function(garages)
    SendNUIMessage({
        type = "loadGarages", 
        garages = garages
    })
end)


RegisterNUICallback("getGaragesForJob", function(data, cb)
    local jobName = data.jobName 
  TriggerServerEvent('garage:getGaragesForJob', jobName) 
end)

RegisterNUICallback('addNewGarage', function(data, cb)
    local playerSource = source
    TriggerServerEvent('garage:addNewGarage', data)
    cb({ success = true, message = 'Garage has been aded!' })
    TriggerServerEvent('reloadgarages', jobName)
end)


RegisterNUICallback("updateGarage", function(data, cb)
    local playerSource = source
    if not data.id then
        print(data.id)
        print("❌ ERROR: Garage id invalid!")
        return cb({ success = false, message = "Invalid garage id!" })
    end

    TriggerServerEvent("d-jobcreator:updateGarage", data)
    cb({ success = true, message = "Podaci poslati serveru." })
end)

RegisterNUICallback('deleteGarage', function(data, cb)
    local playerSource = source
    local jobName = data.job 
    TriggerServerEvent('d-jobcreator:deleteGarage', data.id, jobName)
    TriggerServerEvent('reloadgarages', jobName)
    cb("success")
end)



RegisterNUICallback("getStashLocation", function(data, cb)
    local jobName = data.jobName
    print(jobName)
    TriggerServerEvent("d-jobcreator:getStashLocation", jobName)
    cb({ success = true, message = "Podaci poslati serveru." })
end)

RegisterNetEvent("d-jobcreator:receiveStashLocation")
AddEventHandler("d-jobcreator:receiveStashLocation", function(stashLocation, stashCapacity, stashSlots)
    if stashLocation then
        SendNUIMessage({
            action = "setStashLocation", 
            location = stashLocation,
            capacity = stashCapacity,
            slots = stashSlots
        })
    else
        print("Stash location not found for this job.")
    end
end)

RegisterNUICallback("updateStash", function(data, cb)
    local playerSOurce = source
    local jobName = data.jobName
    print(jobName)
    TriggerServerEvent("d-jobcreator:updateStashLocation", data)
    TriggerServerEvent('d-jobcreator:loadjobstashes')
    cb({ success = true, message = "Podaci poslati serveru." })
end)

local npcEntity = nil


local function decodeCoordinates(coordString)
    local coords = {}
    for v in string.gmatch(coordString, "([-?%d.]+)") do
        table.insert(coords, tonumber(v)) 
    end
    return vector3(coords[1], coords[2], coords[3])  
end

local function createNPC(location)
    RequestModel(Config.npcModel)
    while not HasModelLoaded(Config.npcModel) do
        Wait(100)
    end
    local npc = CreatePed(4, Config.npcModel, location.x, location.y, location.z - 1.0, 0.0, false, true)
    SetEntityInvincible(npc, true) 
    FreezeEntityPosition(npc, true) 
    SetBlockingOfNonTemporaryEvents(npc, true) 

    return npc 
end

local garages = {}

RegisterNetEvent('d-jobcreator:loadGarages')
AddEventHandler('d-jobcreator:loadGarages', function(data)
    if not data or #data == 0 then
        print("[GARAGE] Nema garaza u bazi.")
        return
    end
    for _, garage in pairs(garages) do
        if DoesEntityExist(garage.npc) then
            DeleteEntity(garage.npc)
        end
    end
    garages = {}
    for _, garage in ipairs(data) do
        if garage.location and garage.job then
            local location = decodeCoordinates(garage.location)
            local npcExists = false
            for _, existingGarage in pairs(garages) do
                if existingGarage.coords and #(existingGarage.coords - location) < 0.5 then
                    npcExists = true
                    break
                end
            end
            if not npcExists then
                local npc = createNPC(location)
                table.insert(garages, {
                    id = json.encode(garage.id),
                    name = json.encode(garage.name),
                    npc = npc,
                    coords = location,
                    job = garage.job
                })
            else    
                for _, garage in pairs(garages) do
                    print("Garage ID:", garage.job)
                end
                print('Npc vec postoji na ovoj lokaciji.')
            end
        end
    end
end)



RegisterNetEvent("d-jobcreator:loadVehicles")
AddEventHandler("d-jobcreator:loadVehicles", function(data)
    if data and type(data) == "table" and #data > 0 then
        local vehiclesJson = data[1].vehicles

        if vehiclesJson and type(vehiclesJson) == "string" and vehiclesJson ~= "[]" then
            local decodedVehicles = json.decode(vehiclesJson)
            if decodedVehicles and type(decodedVehicles) == "table" and #decodedVehicles > 0 then
                local vehicleList = {}

                for _, vehicle in ipairs(decodedVehicles) do
                    print("Found vehicle:", vehicle)

                    table.insert(vehicleList, {
                        title = vehicle,
                        description = vehicle,
                        icon = 'car',
                        event = 'd-jobcreator:spawnVehicle',
                        args = {
                            vehicleModel = vehicle,
                            spawnpoint = data[1].spawn_location 
                        }
                    })
                end

                lib.registerContext({
                    id = 'vehicle_menu',
                    title = 'Vehicles',
                    options = vehicleList,
                })

                lib.showContext('vehicle_menu')
            else
                sendNotification("error", "Vehicle list is not valid!", 5000)
            end
        else
            sendNotification("error", "No available vehicles for this job!", 5000)
        end
    else
        sendNotification("error", "No available vehicles for this job!", 5000)
    end
end)

CreateThread(function()
    local playerJob = nil
    local isNear = false 
    local currentGarage = nil 
    local currentZone = nil 

    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local newJob = ESX.GetPlayerData().job.name
        if newJob ~= playerJob then
            playerJob = newJob
        end

        local nearestGarage = nil
        local nearestDistance = math.huge
        if #garages > 0 then
            for _, garage in pairs(garages) do
                if garage.job == playerJob and garage.coords then
                    local distance = #(playerCoords - garage.coords)
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearestGarage = garage
                    end
                end
            end
        end
        if nearestGarage and nearestDistance < 5.0 then
            if not isNear or currentGarage ~= nearestGarage then
                isNear = true
                currentGarage = nearestGarage
                if currentZone then
                    exports.ox_target:removeZone(currentZone)
                end
                currentZone = exports.ox_target:addBoxZone({
                    coords = nearestGarage.coords,
                    size = vector3(2.0, 2.0, 2.0), 
                    debugPoly = false,  
                    options = {
                        {
                            name = 'open_garage_zone', 
                            icon = 'fa-solid fa-box-open',  
                            label = 'Garage',  
                            onSelect = function()
                                TriggerServerEvent('d-jobcreator:getVehiclesForJob', playerJob, nearestGarage.id)
                            end
                        },
                        {
                            name = 'return_garage_zone', 
                            icon = 'fa-solid fa-box-open',  
                            label = 'Return vehicle',  
                            onSelect = function()
                                local ped = PlayerPedId()
                                local vehicle = GetVehiclePedIsIn(ped, true)
                                if DoesEntityExist(vehicle) then
                                    DeleteEntity(vehicle)
                                else
                                    return
                                end
                            end                            
                        }
                    }
                })
            end
            sleep = 0 
        else
            if isNear then
                if currentZone then
                    exports.ox_target:removeZone(currentZone)
                end
                isNear = false
                currentGarage = nil
                currentZone = nil
            end
        end

        Wait(sleep)
    end
end)


RegisterNetEvent('d-jobcreator:spawnVehicle')
AddEventHandler('d-jobcreator:spawnVehicle', function(data)
    local vehicleModel = data.vehicleModel
    local spawnpoint = decodeCoordinates(data.spawnpoint)
    print(vehicleModel, spawnpoint)


    if not vehicleModel or vehicleModel == "" then
        lib.notify({
            title = 'Error',
            description = 'Nevazeci model vozila!',
            type = 'error'
        })
        return
    end


    if not IsModelInCdimage(vehicleModel) or not IsModelAVehicle(vehicleModel) then
        lib.notify({
            title = 'Error',
            description = 'Model vozila ne postoji!',
            type = 'error'
        })
        return
    end

    if IsPedInAnyVehicle(PlayerPedId()) then
        lib.notify({
            title = 'Error',
            description = 'Vec ste u vozilu, to nece moci tako!!',
            type = 'error'
        })
        return
    end

    local playerPed = PlayerPedId()
    local heading = GetEntityHeading(playerPed)

    if ESX.Game.IsSpawnPointClear(spawnpoint, 5.0) then
        ESX.Game.SpawnVehicle(vehicleModel, spawnpoint, heading, function(vehicle)
            if DoesEntityExist(vehicle) then
                TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
                lib.notify({
                    title = 'Vozilo Spawnovano',
                    description = 'Uspješno ste spawnovali vozilo: ' .. vehicleModel,
                    type = 'success'
                })
            else
                lib.notify({
                    title = 'Greška',
                    description = 'Nije moguće spawnovati vozilo!',
                    type = 'error'
                })
            end
        end)
    else
        return
        lib.notify({
            title = 'Greška',
            description = 'Spawnpoint je zauzet!',
            type = 'error'
        })
    end
end)

RegisterCommand(Config.reloadGarages, function()
    if source == 0 then
    TriggerServerEvent('reloadgarages', jobName)
    end
end)


AddEventHandler("onResourceStart", function(resourceName)
    local playerData = ESX.GetPlayerData()
    if playerData and playerData.job then
    if resourceName == GetCurrentResourceName() then
        TriggerServerEvent('reloadgarages', playerData.job.name)
        end
    end
end)

RegisterNetEvent('esx:playerLoaded', function(player, xPlayer, isNew)
    local playerData = ESX.GetPlayerData()
    if playerData and playerData.job then
        TriggerServerEvent('reloadgarages', playerData.job.name)
        print('Player loaded with job:', playerData.job.name)
        end
end)

  


