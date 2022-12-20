local localDefines =
{
    status = 
    {
        idle = 0,
        accepting = 1,
        loading = 2,
        moving = 3,
        deconstructing = 4,
        building = 5,
        upgrading = 6,
        returning = 7,
        unloading = 8,
        initialyze = 9
    }
}

script.on_init(function()
    global.surfaces = {}
    for _, surface in pairs(game.surfaces) do
        initSurface(surface.index)
    end
end)

function initSurface(surfaceIndex)
    global.cleanDeconstructionWithoutID = 0
    global.surfaces[surfaceIndex] = {}

    local surface = global.surfaces[surfaceIndex]

    surface.baseStations = {}
    local baseStations = game.surfaces[surfaceIndex].find_entities_filtered {name = "spidertron-construction-base-station"}
    for _, baseStation in pairs(baseStations) do
        script.register_on_entity_destroyed(baseStation)
        surface.baseStations[baseStation.unit_number] = baseStation
    end

    surface.spidertrons = {}
    surface.constructionSpidertrons = {}
    local spidertrons = game.surfaces[surfaceIndex].find_entities_filtered {type = "spider-vehicle"}
    for _, spidertron in pairs(spidertrons) do
        if spidertron.grid ~= nil then
            script.register_on_entity_destroyed(spidertron)
            surface.spidertrons[spidertron.unit_number] = spidertron
            if spidertron.grid.get_contents()["spidertron-construction-controller"] ~= nil then
                script.register_on_entity_destroyed(spidertron)
                surface.constructionSpidertrons[spidertron.unit_number] = 
                {
                    entity = spidertron,
                    status = localDefines.status.initialyze,
                    jobs = {},
                    itemsForJob = {}
                }
            end
        end
    end

    surface.ghosts = {}
    for _, ghost in pairs(game.surfaces[surfaceIndex].find_entities_filtered({type="entity-ghost"})) do
        build(ghost)
    end

    surface.deconstruction = {}
    surface.deconstructionWithoutID = {}
    for _, deconstruction in pairs(game.surfaces[surfaceIndex].find_entities_filtered({to_be_deconstructed=true})) do
        if (deconstruction.unit_number ~= nil) then
            surface.deconstruction[deconstruction.unit_number] =
            {
                entity = deconstruction,
                spidertron = nil
            }
        
        else
            table.insert(surface.deconstructionWithoutID, {
                entity = deconstruction,
                spidertron = nil
            })
        end
    end

    surface.upgrade = {}
    for _, upgrade in pairs(game.surfaces[surfaceIndex].find_entities_filtered({to_be_upgraded=true})) do
        script.register_on_entity_destroyed(upgrade)
        surface.upgrade[upgrade.unit_number] =
        {
            entity = upgrade,
            spidertron = nil,
            item = upgrade.get_upgrade_target().items_to_place_this[1]
        }
    end
end

script.on_event(defines.events.on_entity_destroyed, function(event)
    for _, surface in pairs(global.surfaces) do
        if surface.baseStations[event.unit_number] then
            surface.baseStations[event.unit_number] = nil
        elseif surface.spidertrons[event.unit_number] then
            surface.spidertrons[event.unit_number] = nil
            if surface.constructionSpidertrons[event.unit_number] then
                surface.constructionSpidertrons[event.unit_number] = nil
            end
        elseif surface.ghosts[event.unit_number] then
            surface.ghosts[event.unit_number] = nil
        elseif surface.upgrade[event.unit_number] then
            surface.upgrade[event.unit_number] = nil
        elseif surface.deconstruction[event.unit_number] then
            surface.deconstruction[event.unit_number] = nil
        end
    end
end)

script.on_event(defines.events.on_surface_created, function(event)
    initSurface(event.surface_index)
end)

script.on_event(defines.events.on_surface_deleted, function(event)
    global.surfaces[event.surface_index] = nil
end)

script.on_event(defines.events.on_equipment_inserted, function(event)
    if event.equipment.name == "spidertron-construction-controller" then
        for _, surface in pairs(global.surfaces) do
            for _, spidertron in pairs(surface.spidertrons) do
                if event.grid == spidertron.grid then
                    surface.constructionSpidertrons[spidertron.unit_number] = 
                    {
                        entity = spidertron,
                        status = localDefines.status.initialyze,
                        jobs = {},
                        itemsForJob = {}
                    }
                end
            end
        end
    end
end)

script.on_event(defines.events.on_equipment_removed, function(event)
    if event.equipment.name == "spidertron-construction-controller" then
        for _, surface in pairs(global.surfaces) do
            for _, constructionSpidertron in pairs(surface.constructionSpidertrons) do
                if event.grid == constructionSpidertron.grid then
                    surface.constructionSpidertrons[constructionSpidertron.unit_number] = nil
                end
            end
        end
    end
end)

script.on_event(defines.events.on_marked_for_deconstruction, function(event)
    if (event.entity.unit_number ~= nil) then
        script.register_on_entity_destroyed(event.entity)        
        global.surfaces[event.entity.surface.index].deconstruction[event.entity.unit_number] = 
        {
            entity = event.entity,
            spidertron = nil
        }
    else
        table.insert(global.surfaces[event.entity.surface.index].deconstructionWithoutID, 
        {
            entity = event.entity,
            spidertron = nil
        })
    end
end)

script.on_event({defines.events.on_cancelled_deconstruction, defines.events.on_robot_mined_entity, defines.events.on_player_mined_entity}, function(event)
    if (event.entity.unit_number ~= nil) then
        global.surfaces[event.entity.surface.index].deconstruction[event.entity.unit_number] = nil
    else
        global.cleanDeconstructionWithoutID = event.entity.surface.index
    end
end)

script.on_event(defines.events.on_marked_for_upgrade, function(event)
    script.register_on_entity_destroyed(event.entity)
    global.surfaces[event.entity.surface.index].upgrade[event.entity.unit_number] = 
    {
        entity = event.entity,
        spidertron = nil,
        item = event.target.items_to_place_this[1]
    }
end)

script.on_event(defines.events.on_cancelled_upgrade, function(event)
    global.surfaces[event.entity.surface.index].upgrade[event.entity.unit_number] = nil
end)

script.on_event(defines.events.on_post_entity_died, function(event)
    if event.ghost ~= nil then
        build(event.ghost)
    end
end)

script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity, defines.events.script_raised_built}, function(event)
    build(event.created_entity)
end)

script.on_event(defines.events.on_pre_ghost_deconstructed, function(event)
    global.surfaces[event.ghost.surface.index].ghosts[event.ghost.unit_number] = nil
end)

function build(entity)
    local surface = global.surfaces[entity.surface.index]
    if entity.type == "entity-ghost" then
        --ghost gebaut
        script.register_on_entity_destroyed(entity)

        local items = {entity.ghost_prototype.items_to_place_this[1]}

        for name, count in pairs(entity.item_requests) do
            table.insert(items, {name = name, count = count})
        end

        surface.ghosts[entity.unit_number] = 
        {
            entity = entity,
            spidertron = nil,
            items = items
        }
        
    elseif entity.name == "spidertron-construction-base-station" then
        -- base gebaut
        script.register_on_entity_destroyed(entity)
        surface.baseStations[entity.unit_number] = entity
    elseif entity.type == "spider-vehicle" then
        --spider gebaut
        if entity.grid ~= nil then
            script.register_on_entity_destroyed(entity)
            surface.spidertrons[entity.unit_number] = entity
            if entity.grid.get_contents()["spidertron-construction-controller"] ~= nil then
                surface.constructionSpidertrons[entity.unit_number] = 
                {
                    entity = entity,
                    status = localDefines.status.initialyze,
                    jobs = {},
                    itemsForJob = {}
                }
            end
        end
    end
end

script.on_nth_tick(1, function(event)
    if (global.cleanDeconstructionWithoutID > 0) then
        local surface = global.surfaces[global.cleanDeconstructionWithoutID]
        for key, deconstruction in pairs(surface.deconstructionWithoutID) do
            if (deconstruction.to_be_deconstructed() == false) then
                surface.deconstructionWithoutID[key] = nil
            end
        end

        global.cleanDeconstructionWithoutID = 0
    else
        for _, surface in pairs(global.surfaces) do
            for _, spidertron in pairs(surface.constructionSpidertrons) do
                if (spidertron.status == localDefines.status.initialyze) then
                    --TODO
                    --zur nächsten basisstation schicken
                    --alles aus inventar -> trash
                    --soviel constructionbots requesten und locken wie in equipte roboports passen
                    --ein stack cliff explosives requesten und locken
                    spidertron.status = localDefines.status.idle
                elseif (spidertron.status == localDefines.status.idle or spidertron.status == localDefines.status.accepting) then
                    --TODO
                    --job und request hinzufügen erst build -> upgrade -> deconstructWithID -> deconstructWithoutID
                    --wenn jobs voll -> loading
                elseif (spidertron.status == localDefines.status.loading) then
                    --TODO
                    --wenn alles für die jobs geladen
                    --los schicken
                end

            end
        end
    end
end)