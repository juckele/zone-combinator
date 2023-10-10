---Sets the signals on the zone combinator to the given values
---@param entity LuaEntity the combinator
function set_zone_combinator_signals(entity, params)
  local control_behavior = entity.get_control_behavior()

  local control_behavior_params = {}
  local index = 1
  if params.radius then
    table.insert(control_behavior_params, {index=index, signal={type="virtual", name="se-radius"}, count=params.radius})
    index = index + 1
  end
  if params.ticks_per_day then
    table.insert(control_behavior_params, {index=index, signal={type="virtual", name="se-star"}, count=params.ticks_per_day})
    index = index + 1
  end
  if params.hostiles_present then
    table.insert(control_behavior_params, {index=index, signal={type="item", name="artillery-targeting-remote"}, count=params.hostiles_present})
    index = index + 1
  end
  if params.has_water then
    table.insert(control_behavior_params, {index=index, signal={type="fluid", name="water"}, count=params.has_water})
    index = index + 1
  end
  if params.primary_resource then
    local type = "item"
    if game.item_prototypes[params.primary_resource] then
      table.insert(control_behavior_params, {index=index, signal={type="item", name=params.primary_resource}, count=1})
      index = index + 1
    elseif game.fluid_prototypes[params.primary_resource] then
      table.insert(control_behavior_params, {index=index, signal={type="fluid", name=params.primary_resource}, count=1})
      index = index + 1
    end
  end
  if params.robot_attrition then
    table.insert(control_behavior_params, {index=index, signal={type="item", name="logistic-robot"}, count=params.robot_attrition})
    index = index + 1
  end

  control_behavior.parameters = control_behavior_params
end

function update_zone_combinator(entity)
  -- the player does not need to change the values in this combinator
  entity.operable = false
    
  -- compute and set the values for the combinator
  local surface_index = entity.surface.index
  local zone = remote.call("space-exploration", "get_zone_from_surface_index", {surface_index = surface_index})
  if not zone then return end

  local hostiles_present = true
  if zone.hostiles_extict then
    hostiles_present = false
  end

  local has_water = true
  if zone.tags then
    for _, tag in pairs(zone.tags) do
      if tag == "water_none" then
        has_water = false
      end
    end
  end

  local robot_attrition = remote.call("space-exploration", "robot_attrition_for_surface", {surface_index = surface_index})

  set_zone_combinator_signals(entity, {
    radius = zone.radius,
    ticks_per_day = zone.ticks_per_day,
    hostiles_present = hostiles_present and 1,
    has_water = has_water and 1,
    primary_resource = zone.primary_resource,
    robot_attrition = math.floor(robot_attrition * 100),
  })
end

local filters = {{
  filter = "name",
  name = "zone-combinator",
}}
function on_entity_created(event)
  local entity
  if event.entity and event.entity.valid then
    entity = event.entity
  end
  if event.created_entity and event.created_entity.valid then
    entity = event.created_entity
  end
  if event.destination and event.destination.valid then
    entity = event.destination
  end
  if not entity then return end
  if entity.name ~= "zone-combinator" then return end
  update_zone_combinator(entity)
end
script.on_event(defines.events.on_entity_cloned, on_entity_created, filters)
script.on_event(defines.events.on_built_entity, on_entity_created, filters)
script.on_event(defines.events.on_robot_built_entity, on_entity_created, filters)
script.on_event(defines.events.script_raised_built, on_entity_created, filters)
script.on_event(defines.events.script_raised_revive, on_entity_created, filters)