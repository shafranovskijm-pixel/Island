# Island — systemic RPG development plan

## Target
A mobile-first 2D systemic fantasy-life RPG. The player begins as nobody. There is no class selection. Skills, biography, appearance, reputation, relationships and political position emerge from repeated actions and consequences.

The island must continue to live without the player.

## Phase 1 — Simulation kernel
Acceptance:
- world clock and day/night
- needs: hunger, energy, hygiene
- NPC schedules and movement
- NPC personality traits and individual goals
- persistent player chronicle
- deterministic/offline AI fallback

Status: foundation implemented.

## Phase 2 — Social life
Acceptance:
- NPC↔NPC friendship, trust, respect, fear, attraction, love, jealousy, resentment and debt
- autonomous meetings
- courtship and relationships can form without the player
- arguments and breakups emerge from relationship state
- rumors spread only through NPC knowledge/memory
- player can become friend, enemy, lover, debtor, patron or target

Status: core relationships and autonomous romance foundation implemented; deeper breakup/family logic next.

## Phase 3 — Economy and ordinary life
Acceptance:
- finite physical stock, ownership and prices
- jobs and wages
- rent, rooms, homelessness and sleeping outside
- food production/supply shortages
- borrowing, debts and repayment
- clothing and possessions reflect wealth/lifestyle
- begging is a viable life path

## Phase 4 — Crime, law and vice
Acceptance:
- theft, witnesses, memory and rumor
- guards react to known crimes, not omniscient flags
- fines, jail, escape and criminal reputation
- alcohol/gambling/fantasy substances create needs and consequences
- NPCs can commit crimes autonomously
- black market and corruption

## Phase 5 — Politics and power
Acceptance:
- council, merchants, guard, temple and underworld factions
- influence, wealth and approval
- taxes/laws affect economy and behavior
- NPCs seek offices and influence
- corruption, bribery, protests, coups and leadership changes can emerge
- player can become official leader or informal power broker

## Phase 6 — Ships and leaving the island
Acceptance:
- ships physically arrive and depart on schedules
- crews have needs/jobs/cargo
- passage can be bought, earned, stolen or negotiated
- stowaway route is systemic
- piracy/merchant/naval routes depend on relationships and skills
- leaving the island becomes a continuation, not a hard ending

## Phase 7 — Character biography and visual evolution
Acceptance:
- every meaningful event enters the chronicle
- lifestyle vectors create emergent titles rather than selected classes
- appearance layers respond to poverty, hygiene, alcohol, crime, sea life, magic and wealth
- clothing/equipment later replace placeholder procedural shapes
- biography remains after restart via save system

Status: initial persistent chronicle + procedural visual profile implemented.

## Phase 8 — AI layer
Rules:
- Godot simulation is the source of truth
- LLM cannot directly mutate world state
- AI returns only validated intentions/dialogue
- NPC may only speak from known memories/facts, but may lie when motivation supports it
- game remains fully playable offline

AI uses:
- free-form dialogue
- rare high-level intentions
- rumor wording, letters, diaries
- summarizing emergent histories
- optional Game Master suggestions when simulation becomes stagnant

Status: validated AI bridge + offline fallback implemented. Network provider intentionally not enabled until simulation is stable.

## Phase 9 — World director
Acceptance:
- storms, fires, shortages, festivals, disease, fights, arrests and discoveries alter actual world state
- director nudges probabilities but never dictates outcomes
- events create downstream economic/social/political consequences

## Phase 10 — Mobile production
Acceptance:
- landscape touch controls
- readable scalable UI
- save/load
- Android debug APK in CI
- smoke test before every APK export
- performance budget for autonomous NPC count

## Definition of a vertical-slice build
A valid first "complete" prototype must support at least one emergent chain such as:

shortage → price increase → NPC debt → stress/drinking → fight → arrest → ship crew vacancy → new escape opportunity for player

No step in the chain should require a hard-coded quest script.
