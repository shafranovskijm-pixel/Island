# Crafting and production design

The crafting system is data-driven and intended to scale without hard-coding each item into the main game script.

## Progression loop

1. Gather loose branches, stones, reeds, food and sand by hand.
2. Process wood into planks and sticks; fiber into rope.
3. Make a stone knife and wooden hammer.
4. Build and physically place a workbench.
5. Make stone axe, pickaxe, shovel, hoe, fishing rod and basic weapons.
6. Gather clay, coal, copper ore and iron ore.
7. Build a campfire and furnace; smelt glass, brick and metal ingots.
8. Build forge, loom, kitchen, sawbench, alchemy table and occult altar.
9. Produce advanced tools, weapons, armor, furniture, building pieces, food, medicine and ritual objects.

## Current recipe groups

- materials and processing
- placeable crafting stations
- stone and iron tools
- weapons, shields and armor
- walls, doors, ladders, storage and furniture
- food and drink
- farming support
- medicine and alchemy
- occult crafting

## System rules

- Recipes may require theory, practical experience, resources, tools and a nearby station.
- Stations are physical objects. The player crafts them, carries them, places them and can later pick them up.
- Tools have durability and can break during crafting or resource gathering.
- Resources belong to the player inventory; crafting does not silently consume the island's public economy stock.
- Crafted structures become world objects and can participate in free-form actions such as breaking, burning, hiding behind or moving.
- The mobile UI uses a recipe book with categories, pages, readiness reasons and tap-to-craft rows instead of a literal 3×3 grid.

## Expansion model

New items are added to `scripts/crafting_catalog.gd`. A recipe only needs category, profession, theory requirement, practice requirement, station, inputs, tools and output. This allows hundreds of future recipes without rewriting the game controller.
