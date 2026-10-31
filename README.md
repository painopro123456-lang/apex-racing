# Apex Racing

A Godot 4 project for a personal 3D formula-style racing game.

## Current baseline
This repository starts from the recovered Apex Racing prototype. It contains a dark navy/blue selection menu, selectable fictional teams and drivers, three procedural test circuits, a basic player car, and simple AI traffic.

## Run
1. Install Godot 4.x.
2. Clone this repository and open `project.godot`.
3. Press Play.
4. Select a team, driver, and circuit, then start the race.
5. Drive with WASD or arrow keys.

## Current limitations
This is an early playable prototype, not a finished F1-scale game. The teams and drivers are fictional placeholders. The three circuits are procedural test layouts, not accurate recreations of real tracks. Cars use primitive geometry; handling, AI, race rules, pit stops, tyre/fuel simulation, weather, damage, career/championship modes, and save data are not implemented yet.

The project uses Godot's Compatibility renderer as a low-end-friendly starting point. Performance on integrated graphics and 4 GB RAM has not yet been measured or guaranteed.

## Development direction
Keep the existing visual identity and expand the prototype incrementally: improve vehicle physics and AI, build distinct circuit layouts, then add race-weekend systems, game modes, content data, and optimized assets. Any real-world team branding, driver likenesses, or official liveries must be handled with appropriate permissions.
