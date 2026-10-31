# Apex Racing

A personal 3D formula-style racing game built with Godot 4.

## Windows download

The repository automatically builds a **Windows `.exe`** whenever changes are pushed to `main`, and when a workflow is manually started.

- **Latest Windows executable:** open [GitHub Releases](https://github.com/painopro123456-lang/apex-racing/releases/latest) and download `ApexRacing.exe`.
- **Build artifacts:** open [Actions](https://github.com/painopro123456-lang/apex-racing/actions), choose a successful run, and download `Apex-Racing-Windows`.

No Android or iOS targets are planned. Windows is the only target platform.

## Run from source

1. Install Godot 4.4.1.
2. Clone or download this repository.
3. Open `project.godot` in Godot.
4. Press Play.

## Current prototype

The current baseline includes a dark navy/blue selection menu, selectable fictional teams and drivers, three procedural test circuits, a basic player car, and simple AI cars.

This is an early playable prototype, not a finished F1-scale game. Teams and drivers are fictional placeholders. The circuits are procedural test layouts, not accurate recreations of real tracks. Cars use primitive geometry. Advanced handling, competitive AI, race rules, pit stops, tyre/fuel simulation, weather, damage, career/championship modes, and save data are not implemented yet.

The project uses Godot's Compatibility renderer as a low-end-friendly starting point. Performance has not yet been measured or guaranteed.

## Development direction

Keep the existing visual identity and expand incrementally: improve vehicle physics and AI, build distinct circuit layouts, then add race-weekend systems, game modes, content data, and optimized assets. Any real-world team branding, driver likenesses, or official liveries must be handled with appropriate permissions.
