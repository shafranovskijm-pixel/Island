# Island

Systemic 2D island-life RPG prototype in Godot 4.

## Core idea
The player starts as nobody. There is no class selection. Repeated actions, relationships, needs, rumors and consequences shape both the character and the island.

## v0.3 living-history prototype
- top-down movement
- mobile touch joystick and action button
- day/time simulation
- hunger, energy and coins
- physical items and ownership
- theft, witnesses and NPC memory
- suspicion, reputation and wanted state
- player biography: meaningful actions become dated life events
- persistent biography in `user://player_history.json`
- lifestyle vectors: homeless, worker, thief, sailor, merchant, mage, drunk, criminal, social
- automatic emergent title such as Nobody, Street Drifter, Petty Thief or Sea Wolf
- visual player appearance derived from lifestyle: clothing tier, dirt, beard, sailor marker, thief hood, magical aura and signs of drinking
- Biography button on mobile HUD showing recent life events
- NPC needs: hunger, fatigue and social need
- NPC personality traits: greed, sociability, lawfulness, curiosity and drinking tendency
- NPC personal money, homes, workplaces and long-term goals
- autonomous daily movement between work, home and tavern
- NPC-to-NPC relationship graph
- physical gossip: nearby NPCs can pass memories to each other
- rumors about witnessed theft can spread gradually rather than becoming globally known
- world event log foundation for future autonomous stories

## Design rule
Do not create a quest when a combination of systems can create the same situation naturally. A job opening, feud, shortage, arrest, friendship or rumor should ideally be a consequence of world state.

## Character-history rule
The game should be able to tell the player's biography after dozens of days without the designer having written that biography in advance. The same history also drives how the character looks.

Example:
> Arrived as nobody → slept rough → begged → worked at the docks → learned theft → was caught → became known in the tavern → learned sailing → visually changed from a clean castaway into a rough port thief/sailor.

## Controls
Desktop: WASD to move, E or Space to interact.

Mobile: left virtual joystick, right action button, Biography button in the top-right corner.

## Next systemic layers
1. Full game-state save/load, not only biography
2. Sleeping locations, rent, homelessness and hygiene
3. Physical buying/selling and supply shortages
4. NPC autonomous jobs, theft, fights and crimes
5. Guards, arrests, fines and prison
6. Relationship events: friendships, feuds, romance, debts and betrayal
7. Ships arriving/departing with crews, cargo and vacancies
8. Dynamic professions and hidden skill combinations
9. Magic that bends normal simulation rules
10. Android export workflow
