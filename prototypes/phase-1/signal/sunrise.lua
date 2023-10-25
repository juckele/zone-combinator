local signal_prototype = table.deepcopy(data.raw["virtual-signal"]["signal-everything"])
signal_prototype.name = "day-length"
signal_prototype.icon = "__zone-combinator__/graphics/signal/sunrise.png"
signal_prototype.icon_size = 512
signal_prototype.order = "z"
signal_prototype.subgroup = "virtual-signal"

data:extend({signal_prototype})
