local item = table.deepcopy(data.raw["item"]["exoskeleton-equipment"])
item.name = "spidertron-construction-controller"
item.placed_as_equipment_result = 'spidertron-construction-controller'
item.order = item.order .. "b"

local category =
{
	type = 'equipment-category',
	name = 'spidertron-construction-controller'
}

local equipment = table.deepcopy(data.raw["movement-bonus-equipment"]["exoskeleton-equipment"])
equipment.name = "spidertron-construction-controller"
equipment.categories = {'spidertron-construction-controller'}
equipment.place_result = "spidertron-construction-controller"

local recipe =
{
	type = 'recipe',
	name = 'spidertron-construction-controller',
	ingredients =
	{
		{'rocket-control-unit', 1},
		{'processing-unit', 1},
		{'spidertron-remote', 1}
	},
	results = {{'spidertron-construction-controller', 1}},
	enabled = false
}

data:extend({item, category, equipment, recipe})

table.insert(data.raw["technology"]["spidertron"].effects,{type = "unlock-recipe", recipe="spidertron-construction-controller"})