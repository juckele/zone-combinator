function table_contains(table, check)
  for k,v in pairs(table) do if v == check then return true end end
  return false
end

---Sets the signals on the zone combinator to the given values
---@param entity LuaEntity the combinator
function set_zone_combinator_signals(entity, params)
  local control_behavior = entity.get_control_behavior()

  local control_behavior_params = {}
  local index = 1
  if params.index and params.signal then
    table.insert(control_behavior_params, {index=index, signal={type="virtual", name=params.signal}, count=params.index})
    index = index + 1
  end
  if params.radius then
    table.insert(control_behavior_params, {index=index, signal={type="virtual", name="se-radius"}, count=params.radius})
    index = index + 1
  end
  if params.ticks_per_day then
    table.insert(control_behavior_params, {index=index, signal={type="item", name="solar-panel"}, count=params.ticks_per_day})
    index = index + 1
  end
  if params.threat then
    table.insert(control_behavior_params, {index=index, signal={type="item", name="artillery-targeting-remote"}, count=params.threat})
    index = index + 1
  end
  if not params.waterless then
    table.insert(control_behavior_params, {index=index, signal={type="fluid", name="water"}, count=1})
    index = index + 1
  end
  if params.biter_meteors then
    table.insert(control_behavior_params, {index=index, signal={type="virtual", name="se-meteor"}, count=1})
    index = index + 1
  end
  if params.plagued then
    table.insert(control_behavior_params, {index=index, signal={type="item", name="se-plague-bomb"}, count=1})
    index = index + 1
  end
  if params.life_support then
    table.insert(control_behavior_params, {index=index, signal={type="item", name="se-lifesupport-canister"}, count=1})
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

local icon_prefix = "virtual-signal/"

function get_zone_signal(surface_index)
  local zone = remote.call("space-exploration", "get_zone_from_surface_index", {surface_index = surface_index})
  if not zone then return nil, nil end

  local zone_icon = remote.call("space-exploration", "get_zone_icon", {zone_index = zone.index})

  return zone.index, string.sub(zone_icon, string.len(icon_prefix) + 1, string.len(zone_icon))
end

function update_zone_combinator(entity)
  -- compute and set the values for the combinator
  local surface_index = entity.surface.index
  local zone = remote.call("space-exploration", "get_zone_from_surface_index", {surface_index = surface_index})
  if not zone then return end

  local threat = remote.call("space-exploration", "threat_for_surface", {surface_index = surface_index})
  local robot_attrition = remote.call("space-exploration", "robot_attrition_for_surface", {surface_index = surface_index})
  local hazards = remote.call("space-exploration", "hazards_for_surface", {surface_index = surface_index})
  local index, signal = get_zone_signal(surface_index)
  local plagued = table_contains(hazards, "plague-world")
  local life_support = plagued or (zone.type ~= "moon" and zone.type ~= "planet") -- this probably will change in some future version of SE where some planets/moons don't just happen to all have breathable atmospheres
  local waterless = table_contains(hazards, "waterless") or (zone.type ~= "moon" and zone.type ~= "planet")
  local primary_resource = nil
  if zone.type ~= "orbit" then
    primary_resource = zone.primary_resource
  end

  set_zone_combinator_signals(entity, {
    radius = zone.radius,
    ticks_per_day = zone.ticks_per_day,
    threat = math.floor(threat * 100),
    waterless = waterless,
    biter_meteors = table_contains(hazards, "biter-meteors"),
    plagued = plagued,
    primary_resource = primary_resource,
    robot_attrition = math.floor(robot_attrition * 100),
    index = index,
    signal = signal,
    life_support = life_support,
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