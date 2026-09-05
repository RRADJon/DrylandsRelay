# Third-party notices

## Godot Engine

Godot Engine is open source under the MIT license. This rebuild targets Godot 4.5.2.

## Godot Third Person Shooter Demo

Upstream repository: `godotengine/tps-demo`

Pinned source commit used by this rebuild:
`90f2e38d7b5cf9e6fd0b788d0da1df4b84d49269`

The upstream project's `LICENSE.md` states that its code is MIT licensed. Its game assets are Copyright (c) 2018 Juan Linietsky and Fernando Miguel Calabró and are distributed under CC BY 3.0. Its music is Copyright (c) 2018 Christian Fernando Perucchi and is also distributed under CC BY 3.0.

This repository does not copy the upstream asset payload. The bootstrap process obtains the pinned upstream project from its official GitHub repository, then installs the Drylands overlay. Keep the upstream `LICENSE.md` with redistributed builds and provide the required attribution.

## Drylands Relay overlay

New Drylands-specific scripts in `drylands/` and `tools/` were created for this rebuild. They may be used under the MIT license; see `LICENSE`.
