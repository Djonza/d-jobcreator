lib.locale()

RegisterNetEvent('d-jobcreator:requestJobsList')
AddEventHandler('d-jobcreator:requestJobsList', function()
    local src = source
    local jobs = {}
    local result = MySQL.query.await('SELECT * FROM jobs')
    if result then
        for _, job in pairs(result) do
            table.insert(jobs, { name = job.name or 'Undefined' })
        end
    end
    TriggerClientEvent('d-jobcreator:receiveJobsList', src, jobs)
end)

RegisterNetEvent('d-jobcreator:getJobGrades')
AddEventHandler('d-jobcreator:getJobGrades', function(jobName)
    local src = source
    local grades = {}
    local query = 'SELECT job_name, grade, name, label, salary FROM job_grades WHERE job_name = ? ORDER BY grade ASC'
    local result = MySQL.query.await(query, { jobName })
    if result then
        for _, row in pairs(result) do
            table.insert(grades, {
                job_name = row.job_name,
                grade = row.grade,
                name = row.name,
                label = row.label,
                salary = row.salary
            })
        end
    end
    TriggerClientEvent('d-jobcreator:receiveJobGrades', src, grades)
end)

RegisterNetEvent('d-jobcreator:updateJobGrades')
AddEventHandler('d-jobcreator:updateJobGrades', function(updates)
    if not updates or #updates == 0 then
        print("ERROR: No data received")
        return
    end

    local playerSource = source  
    local successCount = 0
    local failCount = 0

    for _, update in ipairs(updates) do
        local jobName = update.job_name
        local grade = update.grade
        local name = update.name
        local label = update.label
        local salary = update.salary
        local updateJobGradesQuery = [[
            UPDATE job_grades 
            SET label = ?, salary = ?, name = ?
            WHERE job_name = ? AND grade = ?
        ]]
        local affectedRows = MySQL.Sync.execute(updateJobGradesQuery, {label, salary, name, jobName, grade})
        if affectedRows < 1 then
            failCount = failCount + 1
            print("Failed to update job_grades for job:", jobName, "and grade:", grade)
        else
            successCount = successCount + 1
            print("Successfully updated job_grades for job:", jobName, "and grade:", grade)
        end
    end
    if failCount > 0 then
        typee = 'error'
        message = locale('job_grade_update_failed')
    else
        typee = 'success'
        message = locale('job_grades_updated')
    end
    TriggerClientEvent('sendNotificationClient', playerSource, typee, message, 3000)
end)


RegisterNetEvent('d-jobcreator:addJob')
AddEventHandler('d-jobcreator:addJob', function(new)
    if not new then
        print("ERROR: No data received.")
        return
    end
    local playerSource = source  
    local jobName = new.job_name
    local label = new.label
    local whitelisted = new.whitelisted 
    local checkQuery = [[
        SELECT COUNT(*) as count FROM jobs WHERE name = ? OR label = ?
    ]]
    local result = MySQL.Sync.fetchAll(checkQuery, {jobName, label})

    if result and result[1] and result[1].count > 0 then
        TriggerClientEvent('sendNotificationClient', playerSource, 'error', locale('job_exists'), 3000)
      --  print("ERROR: Job with the same name or label already exists!")
        return
    end
    local insertQuery = [[
        INSERT INTO jobs (name, label, whitelisted) VALUES (?, ?, ?)
    ]]
    local affectedRows = MySQL.Sync.execute(insertQuery, {jobName, label, whitelisted})

    if affectedRows > 0 then
        print(source, playerSource)
        TriggerClientEvent('sendNotificationClient', playerSource, 'success', 'Job added successfully', 3000)
        TriggerClientEvent('d-jobcreator:receiveJobsList', -1, MySQL.query.await('SELECT * FROM jobs'))
    else
        TriggerClientEvent('sendNotificationClient', playerSource, 'error', locale('add_job_failed'), 3000)
     --   print("ERROR: Failed to insert new job!")
    end
end)



RegisterNetEvent('d-jobcreator:addJobGrade')
AddEventHandler('d-jobcreator:addJobGrade', function(update)
    if not update then
        print("ERRO: No data received.")
        return
    end
    local playerSource = source
    local jobName = update.job_name
    local grade = update.grade
    local name = update.name
    local label = update.label
    local salary = update.salary
    local checkNameQuery = [[
        SELECT COUNT(*) FROM job_grades 
        WHERE job_name = ? AND name = ?
    ]]
    local nameCount = MySQL.Sync.fetchScalar(checkNameQuery, {jobName, name})

    if nameCount > 0 then
        TriggerClientEvent('sendNotificationClient', playerSource, 'error', locale('job_grade_name'), 3000)
        print("DUPLICATED:", jobName, ", name:", name)
        return
    end
    local checkGradeQuery = [[
        SELECT COUNT(*) FROM job_grades 
        WHERE job_name = ? AND grade = ?
    ]]
    local gradeCount = MySQL.Sync.fetchScalar(checkGradeQuery, {jobName, grade})

    if gradeCount > 0 then
        TriggerClientEvent('sendNotificationClient', playerSource, 'error', locale("job_grade_exists"), 3000)
     --   print("DUPLICATED:", jobName, ", grade:", grade)
        return
    end
    local insertJobGradesQuery = [[
        INSERT INTO job_grades (job_name, name, grade, label, salary) 
        VALUES (?, ?, ?, ?, ?)
    ]]
    local affectedRows1 = MySQL.Sync.execute(insertJobGradesQuery, {jobName, name, grade, label, salary})

    if affectedRows1 < 1 then
        TriggerClientEvent('sendNotificationClient', playerSource, 'error', 'job_grade_insert_failed', 3000)
    else
        TriggerClientEvent('d-jobcreator:receiveJobGrades', -1, MySQL.query.await('SELECT * FROM job_grades WHERE job_name = ?', {jobName}))
    end

    if affectedRows1 > 0 then
        TriggerClientEvent('sendNotificationClient', playerSource, 'success', locale("job_grade_added"), 3000)
    else
        TriggerClientEvent('sendNotificationClient', playerSource, 'error', locale('job_grade_added_failed'), 3000)
    --    print("ERROR: Failed to add job grade.")
    end
end)

RegisterNetEvent('d-jobcreator:deleteJobGrade')
AddEventHandler('d-jobcreator:deleteJobGrade', function(jobName, grade)
    local playerSource = source
    local deleteQuery = [[
        DELETE FROM job_grades WHERE job_name = ? AND grade = ?
    ]]
    local affectedRows = MySQL.Sync.execute(deleteQuery, {jobName, grade})
    if affectedRows > 0 then
     --   TriggerClientEvent('sendNotificationClient', playerSource, 'success', locale('job_grade_deleted'), 3000)
        TriggerClientEvent('d-jobcreator:receiveJobGrades', -1, MySQL.query.await('SELECT * FROM job_grades WHERE job_name = ?', {jobName}))
    else
        TriggerClientEvent('sendNotificationClient', playerSource, 'error', locale('job_grade_deleted_failed'), 3000)
        print("ERROR: Failed to delete job grade for job: ", jobName, "and grade:", grade)
    end
end)



RegisterNetEvent('d-jobcreator:deleteJob')
AddEventHandler('d-jobcreator:deleteJob', function(jobName)
    local playerSource = source
    if not jobName then
        TriggerClientEvent('sendNotificationClient', playerSource, 'error', locale('no_job_found'), 3000)
        return
    end
    local deleteJobGradesQuery = [[
        DELETE FROM job_grades 
        WHERE job_name = ?
    ]]
    local affectedRows1 = MySQL.Sync.execute(deleteJobGradesQuery, {jobName})

    if affectedRows1 < 1 then
        TriggerClientEvent('sendNotificationClient', playerSource, 'error', locale('job_grade_deleted_failed'), 3000)
 --       print("ERROR: Failed to delete job_grades for job:", jobName)
    else
    end

    local deleteJobQuery = [[
        DELETE FROM jobs 
        WHERE name = ?
    ]]
    local affectedRows2 = MySQL.Sync.execute(deleteJobQuery, {jobName})

    if affectedRows2 < 1 then
        TriggerClientEvent('sendNotificationClient', playerSource, 'error', locale('job_deleted_failed'), 3000)
       -- print("ERROR: Failed to delete job ", jobName)
    else
        TriggerClientEvent('d-jobcreator:receiveJobsList', -1, MySQL.query.await('SELECT * FROM jobs'))

    end
    local deleteJobQuery = [[
        DELETE FROM d_garages 
        WHERE job = ?
    ]]
    local affectedRows2 = MySQL.Sync.execute(deleteJobQuery, {jobName})

    if affectedRows2 < 1 then
        TriggerClientEvent("sendNotificationClient", playerSource, 'error', locale("job_deleted_garages_failed"), 3000)
    else
        TriggerClientEvent("sendNotificationClient", playerSource, 'success', locale('job_deleted'), 3000)
        TriggerClientEvent('d-jobcreator:receiveJobsList', -1, MySQL.query.await('SELECT * FROM jobs'))

    end
end)

RegisterServerEvent('garage:getGaragesForJob')
AddEventHandler('garage:getGaragesForJob', function(job)
    local source = source
    local garages = {}

    MySQL.Async.fetchAll("SELECT * FROM d_garages WHERE job = @job", {
        ["@job"] = job
    }, function(result)
        print("Rezultat iz baze:", json.encode(result))  
        if result then
            for _, garage in ipairs(result) do
                table.insert(garages, {
                    id = garage.id,
                    name = garage.name,
                    location = garage.location,
                    spawn_location = garage.spawn_location,
                    vehicles = garage.vehicles,
                    type = garage.type,
                    blip = garage.blip,
                    job = garage.job
                })
            end
        end
  --      TriggerClientEvent('d-jobcreator:loadGarages', source, garages)
        TriggerClientEvent('d-jobcreator:receiveGarages', source, garages)
    end)
end)

RegisterServerEvent('garage:addNewGarage')
AddEventHandler('garage:addNewGarage', function(addGarageData)
    local playerSource = source
    if not addGarageData then
        TriggerClientEvent("sendNotificationClient", playerSource, 'error', locale('no_data_received'), 3000)
  --      print("ERROR: No data received")
        return
    end

    if not (addGarageData.location and addGarageData.spawn_location) then
        print(addGarageData.location, addGarageData.spawn_location)
        TriggerClientEvent('sendNotificationClient', playerSource, 'error', locale('locations_invalid'), 5000)
        return
    end

    local job = addGarageData.job
    local name = addGarageData.name
    local location = json.encode(addGarageData.location)
    local spawn_location = json.encode(addGarageData.spawn_location) 
    local vehicles = json.encode(addGarageData.vehicles) 
    local type = addGarageData.type
    local blip = addGarageData.blip


    MySQL.Async.execute('INSERT INTO d_garages (job, name, location, spawn_location, vehicles, type, blip) VALUES (@job, @name, @location, @spawn_location, @vehicles, @type, @blip)', {
        ['@job'] = job,
        ['@name'] = name,
        ['@location'] = location,
        ['@spawn_location'] = spawn_location,
        ['@vehicles'] = vehicles, 
        ['@type'] = type,
        ['@blip'] = blip
    }, function(affectedRows)
        if affectedRows > 0 then
            addGarageData.vehicles = json.decode(vehicles) 
            TriggerClientEvent("sendNotificationClient", playerSource, 'success', locale('garage_added'), 3000)
            TriggerClientEvent('d-jobcreator:receiveGarages', -1, MySQL.query.await('SELECT * FROM d_garages WHERE job = ?', {job}))
            print(job)
        else
            TriggerClientEvent("sendNotificationClient", playerSource, 'success', locale('garage_add_error'), 3000)
        end
    end)
end)


RegisterServerEvent('d-jobcreator:updateGarage')
AddEventHandler('d-jobcreator:updateGarage', function(updatedGarageData)
    local playerSource = source
    local id = updatedGarageData.id
    local name = updatedGarageData.name
    local location = json.encode(updatedGarageData.location)
    local spawn_location = json.encode(updatedGarageData.spawn_location)
    local vehicles = updatedGarageData.vehicles
    local type = updatedGarageData.type
    local blip = updatedGarageData.blip
    local job = updatedGarageData.job


    MySQL.Async.execute('UPDATE d_garages SET name = @name, location = @location, spawn_location = @spawn_location, vehicles = @vehicles, type = @type, blip = @blip WHERE id = @id', {
        ['@id'] = id,
        ['@name'] = name,
        ['@location'] = location,
        ['@spawn_location'] = spawn_location,
        ['@vehicles'] = vehicles,
        ['@type'] = type,
        ['@blip'] = blip
    }, function(affectedRows)
        if affectedRows > 0 then
            updatedGarageData.vehicles = json.decode(vehicles)
            TriggerClientEvent("sendNotificationClient", playerSource, 'success', locale('garage_add_error'), 3000)
            TriggerClientEvent('d-jobcreator:receiveGarages', -1, MySQL.query.await('SELECT * FROM d_garages WHERE job = ?', {job}))
        else
            TriggerClientEvent('sendNotificationClient', playerSource, 'error', locale('garage_update_error'), 3000)
        end
    end)
end)

RegisterNetEvent('d-jobcreator:deleteGarage')
AddEventHandler('d-jobcreator:deleteGarage', function(id, job)
    local deleteQuery = [[
        DELETE FROM d_garages WHERE id = ?
    ]]
    local affectedRows = MySQL.Sync.execute(deleteQuery, {id})
    if affectedRows > 0 then        
        TriggerClientEvent('sendNotificationClient', playerSource, 'success', locale('garage_deleted'), 3000)
        TriggerClientEvent('d-jobcreator:receiveGarages', -1, MySQL.query.await('SELECT * FROM d_garages WHERE job = ?', {job}))
    else
        TriggerClientEvent('sendNotificationClient', playerSource, 'error', locale('garage_deleted_error'), 3000)
    end
end)

RegisterServerEvent('reloadgarages')
AddEventHandler('reloadgarages', function()
    local src = source
    MySQL.Async.fetchAll("SELECT job, location, name, id FROM d_garages", {}, function(results)
        if not results or #results == 0 then
            return
        end
        TriggerClientEvent("d-jobcreator:loadGarages", src, results)
    end)
end)

RegisterNetEvent("d-jobcreator:getVehiclesForJob")
AddEventHandler("d-jobcreator:getVehiclesForJob", function(job, id)
    local src = source

    if not job or not id then
        TriggerClientEvent('sendNotificationClient|', playerSource, 'error', locale('no_job_found'), 3000)
        return
    end

    MySQL.Async.fetchAll("SELECT job, vehicles, spawn_location FROM d_garages WHERE job = @job AND id = @id", {
        ['@job'] = job,
        ['@id'] = id
    }, function(results)
        if not results or #results == 0 then
            return
        end
        TriggerClientEvent('d-jobcreator:loadVehicles', src, results)
    end)
end)




RegisterServerEvent("d-jobcreator:getStashLocation")
AddEventHandler("d-jobcreator:getStashLocation", function(job)
    print('Server vraca jobName kao', job)
    local src = source
    local result = MySQL.query.await("SELECT stash_location, stash_capacity, stash_slots FROM jobs WHERE `name` = ?", { job })
    if result and #result > 0 then
        local stashLocation = json.decode(result[1].stash_location)
        local stashCapacity = tonumber(result[1].stash_capacity)
        local stashSlots = tonumber(result[1].stash_slots)
        print('Stash capacity is', stashCapacity)
        TriggerClientEvent("d-jobcreator:receiveStashLocation", src, stashLocation, tonumber(stashCapacity), tonumber(stashSlots))
    else
        TriggerClientEvent("d-jobcreator:receiveStashLocation", src, nil)
    end
end)


RegisterServerEvent("d-jobcreator:updateStashLocation")
AddEventHandler("d-jobcreator:updateStashLocation", function(updatedStashData)
    local jobName = updatedStashData.jobName
    local stashLocation = updatedStashData.stashLocation
    local stashCapacity = updatedStashData.stashCapacity
    local stashSlots = updatedStashData.stashSlots
    if stashLocation and type(stashLocation) == "table" then
        stashLocation = json.encode(stashLocation) 
    else
        print("ERROR: Invalid stashLocation format")
        TriggerClientEvent("d-jobcreator:stashLocationUpdated", source, false)
        return
    end
    MySQL.query("UPDATE jobs SET stash_location = ?, stash_capacity = ?, stash_slots = ? WHERE name = ?", {stashLocation, stashCapacity, stashSlots, jobName}, function(affectedRows)
        if affectedRows then
            TriggerEvent('d-jobcreator:loadjobstashes')
        else
        end
    end)
end)

