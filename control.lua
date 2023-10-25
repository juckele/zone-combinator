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

function get_zone_signal(zone)
  local zone_icon = remote.call("space-exploration", "get_zone_icon", {zone_index = zone.index})
  return zone.index, string.sub(zone_icon, string.len(icon_prefix) + 1, string.len(zone_icon))
end

--------------------------------------------------------------
-- BEGIN GET THREAT
-- Remove when remote interface from SE is added.
-- All code in this block derived from SE scripts/zone.lua.
--------------------------------------------------------------
local function enemy_base_setting_to_threat(enemy_base_setting)
  return math.max(0, math.min(1, enemy_base_setting.size / 3))  -- 0-1
end

function get_threat(zone)
  if is_solid(zone) then
    if zone.is_homeworld and zone.surface_index then
      local surface = get_surface(zone)
      local mapgen = surface.map_gen_settings
      if mapgen.autoplace_controls["enemy-base"] and mapgen.autoplace_controls["enemy-base"].size then
        return enemy_base_setting_to_threat(mapgen.autoplace_controls["enemy-base"])
      end
    end
    if zone.controls and zone.controls["enemy-base"] and zone.controls["enemy-base"].size then
      local threat = enemy_base_setting_to_threat(zone.controls["enemy-base"])
      if Zone.is_biter_meteors_hazard(zone) then
        return math.max(threat, 0.01)
      end
      return threat
    end
  end
  return 0
end

function get_surface(zone)
  if zone.type == "spaceship" then
    return Spaceship.get_current_surface(zone)
  end
  if zone.surface_index then
    return game.get_surface(zone.surface_index)
  end
  return nil
end

function is_solid(zone)
  return zone.type == "planet" or zone.type == "moon"
end
--------------------------------------------------------------
-- END GET THREAT
--------------------------------------------------------------

--------------------------------------------------------------
-- BEGIN GET HAZARDS
-- Remove when remote interface from SE is added.
-- All code in this block derived from SE scripts/zone.lua.
--------------------------------------------------------------
function get_hazards(zone)
  local hazards = {}
  if is_biter_meteors_hazard(zone) then
    table.insert(hazards, "biter-meteors")
  end
  if zone.plague_used then
    table.insert(hazards, "plague-world")
  end
  if zone.tags and table_contains(zone.tags, "water_none") then
    table.insert(hazards, "waterless")
  end
  return hazards
end

function is_biter_meteors_hazard(zone)
  return zone.controls and zone.controls["se-vitamelange"] and zone.controls["se-vitamelange"].richness > 0
end
--------------------------------------------------------------
-- END GET HAZARDS
--------------------------------------------------------------


function update_zone_combinator(entity)
  -- compute and set the values for the combinator
  local surface_index = entity.surface.index
  local zone = remote.call("space-exploration", "get_zone_from_surface_index", {surface_index = surface_index})
  if not zone then return end
  log("zone_information:" .. serpent.block(zone))
  
  -- TODO use remote calls when implemented:
  -- local threat = remote.call("space-exploration", "threat_for_surface", {surface_index = surface_index})
  local threat = get_threat(zone)
  local robot_attrition = remote.call("space-exploration", "robot_attrition_for_surface", {surface_index = surface_index})
  -- local hazards = remote.call("space-exploration", "hazards_for_surface", {surface_index = surface_index})
  local hazards = get_hazards(zone)
  local index, signal = get_zone_signal(zone)
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