local ox_inventory = exports.ox_inventory
local oxmysql = exports.oxmysql
local stashes = {}

local function LoadJobStashes()
    stashes = {}

    oxmysql:execute('SELECT name, stash_location, stash_capacity, stash_slots FROM jobs', {}, function(result)
        if result then
            for _, job in ipairs(result) do
                if job.stash_location and job.stash_location ~= '' then
                    local coords = json.decode(job.stash_location) 
                    print(coords)
 
                    if coords then
                        local stashId = 'stash_' .. job.name
                        local capacity = tonumber(job.stash_capacity) or 30000
                        local slots = tonumber(job.stash_slots) or 50
    
                        ox_inventory:RegisterStash(stashId, job.name .. ' Stash', slots, capacity, false, job.name)
                        table.insert(stashes, {
                            id = stashId,
                            job = job.name,
                            coords = vector3(coords.x, coords.y, coords.z),
                            capacity = capacity,
                            slots = slots
                        })
                    end
                end
            end
            print(json.encode(stashes, { indent = true })) 
            TriggerClientEvent('stash:updateStashes', -1, stashes)        
        end
    end)
end

RegisterNetEvent('d-jobcreator:loadjobstashes', function(stashes)
    LoadJobStashes()
end)

AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        print("⌛ Waiting for data, before loading stashes...")
        SetTimeout(1000, LoadJobStashes)
    end
end)

RegisterNetEvent('esx:playerLoaded', function(playerId)
    LoadJobStashes()
end)

RegisterCommand(Config.reloadStashes, function(source, args, rawCommand)
    if source == 0 then
        LoadJobStashes()
        print("Stashes are reloaded from data-base.")
    end
end)


