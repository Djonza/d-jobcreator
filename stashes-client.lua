local stashLocations = {}

RegisterNetEvent('stash:updateStashes')
 AddEventHandler('stash:updateStashes', function(stashes)
    stashLocations = stashes
    SpawnStashObjects(stashes)
end)

function GetPlayerJob()
    return ESX.GetPlayerData().job.name
end

local stashObjects = {} 

function SpawnStashObjects()
    for _, obj in ipairs(stashObjects) do
        if DoesEntityExist(obj) then
            DeleteEntity(obj)
        end
    end
    
    stashObjects = {} 

    for _, stash in ipairs(stashLocations) do
        print(stash)
        local stashModel = `prop_ld_int_safe_01` 
        RequestModel(stashModel)
        while not HasModelLoaded(stashModel) do
            Wait(100)
        end

        local stashObject = CreateObject(stashModel, stash.coords.x, stash.coords.y, stash.coords.z - 1.0, false, false, false)
        SetEntityHeading(stashObject, 0.0)
        FreezeEntityPosition(stashObject, true)

        if DoesEntityExist(stashObject) then
            print('Entity exists')
            table.insert(stashObjects, stashObject) 
        else
            print('Entity does not exist')
            DeleteEntity(stashObject)
        end

        exports.ox_target:addLocalEntity(stashObject, {
            {
                label = "Open stash",
                icon = "fa-solid fa-box-open",
                onSelect = function()
                    local playerJob = GetPlayerJob()
                    if playerJob == stash.job then
                        exports.ox_inventory:openInventory('stash', stash.id)
                    else
                        return false
                    end
                end
            }
        })
    end
end