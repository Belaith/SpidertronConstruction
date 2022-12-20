local item = table.deepcopy(data.raw["item"]["roboport"])
item.name = "spidertron-construction-base-station"
item.place_result = "spidertron-construction-base-station"
item.order = item.order .. "b"

local base_station = table.deepcopy(data.raw["roboport"]["roboport"])
base_station.name = "spidertron-construction-base-station"
base_station.minable = {hardness = 0.2, mining_time = 1, result = "spidertron-construction-base-station"}
base_station.logistics_radius = 20
base_station.construction_radius = 0

local recipe =
{
    type = "recipe",
    name = "spidertron-construction-base-station",
    enabled = false,
    ingredients =
    {
        { "roboport", 1}
    },
    result = "spidertron-construction-base-station",
    result_count = 1,
    energy = 1
}

data:extend({item, base_station, recipe})

table.insert(data.raw["technology"]["spidertron"].effects,{type = "unlock-recipe", recipe="spidertron-construction-base-station"})
