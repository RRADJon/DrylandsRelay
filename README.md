# Drylands Relay — Godot browser-first rebuild

This is the **browser validation build** of the Godot rebuild. It uses the official Godot Third Person Shooter Demo as the foundation and applies the Drylands gameplay layer on top.

The purpose of this milestone is simple: **play the real Godot character/controller/camera/combat in Chrome before spending time on an APK**.

## What you are testing

The browser build preserves the official TPS demo's authored player character, skeleton/AnimationTree, third-person camera, root-motion locomotion, aiming, firing, animated red-robot enemies, level art, particles, audio and physics. The Drylands layer adds:

- 100 shield + 100 health;
- 3.5-second shield recharge delay;
- 8-minute / 20-elimination match state;
- sprint;
- airborne glide;
- boost meter;
- Drylands HUD and kill feed;
- touch controls when a touchscreen browser exposes touch input.

It deliberately does **not** replace the upstream character or animation with the old Drylands placeholder models.

## Put it on your existing GitHub Pages site

For the existing `RRADJon/DrylandsGame` repository:

1. Extract this ZIP.
2. Upload the extracted files/folders to the **root** of the repository.
3. Make sure `.github/workflows/static.yml` from this package replaces your previous static Pages workflow.
4. Commit to `main`.
5. In **Settings → Pages**, keep **Source = GitHub Actions**.
6. Open **Actions → Build Godot Browser Preview** and wait for the build and deploy jobs to turn green.
7. Open `https://rradjon.github.io/DrylandsGame/`.

The workflow does not commit the huge upstream TPS demo into your repository. During the build it fetches the official demo at the pinned release commit, applies the Drylands overlay, exports Godot WebGL 2 files, then deploys only the generated browser build.

## Browser controls

After loading, click **CLICK TO DEPLOY** once. This user gesture lets the browser grant pointer-lock mouse control and unlock audio.

- **WASD** — move
- **Mouse** — look
- **Right mouse** — aim
- **Left mouse** — shoot while aiming
- **Space** — jump
- **Shift** — sprint
- **F** — glide while airborne
- **Q** — boost while gliding
- **Esc** — pause / release mouse

Chrome or Edge is recommended for this test.

## Important Web-vs-native graphics limitation

Godot 4 Web exports run through **WebGL 2 and the Compatibility renderer**. The native Android build can use Godot's Mobile renderer, so the browser preview is primarily for validating character quality, animation, controller feel, camera, combat, enemy behavior and level readability. Features that require Forward+ (for example SDFGI or volumetric fog) are not available in the browser Compatibility renderer.

For that reason, do not treat a browser lighting difference as proof that the Android renderer will look identical. Do treat bad animation, bad movement, bad camera or bad combat feel as real blockers — those are exactly what this browser pass is intended to expose.

## Reproducible foundation

- Godot: **4.5.2**
- Official TPS demo commit: `90f2e38d7b5cf9e6fd0b788d0da1df4b84d49269`
- Web export: WebGL 2 / Compatibility renderer
- Web threads: disabled, so normal GitHub Pages HTTPS hosting works without cross-origin-isolation headers

## Android is still available, but not automatic

`.github/workflows/build-android.yml` remains included for later, but it is **manual-only** in this browser-first package. Pushing to `main` builds/deploys the browser version, not an APK.
