# Browser gameplay test checklist

Do not judge this pass by feature count. Judge whether the mature Godot base solves the fundamental problems of the old build.

## Character
- Silhouette reads as a finished authored character rather than primitive geometry.
- Run/jump/aim transitions look coherent.
- Upper-body aiming and weapon pose do not visibly break locomotion.
- Feet feel grounded rather than sliding.

## Camera
- Camera follows without nausea or excessive lag.
- Aiming is predictable.
- Character does not dominate the center of the screen.
- Mouse sensitivity feels controllable.

## Movement
- Starting/stopping feels responsive.
- Strafing feels intentional rather than floaty.
- Jumping has readable takeoff/landing.
- Sprint feels like a speed state, not a teleport.
- Drylands glide/boost should be judged separately from the upstream ground controller.

## Combat
- Aim → fire loop feels immediate.
- Impact effects make hits readable.
- Enemy animations and return fire are legible.
- Shield/health feedback is understandable without staring at the HUD.

## Decision gate
If character animation, ground movement, camera and shooting feel substantially better than the old Filament build, keep this Godot foundation and build Drylands-specific systems on it. If those fundamentals are still poor, stop before adding more content and choose a different controller/demo foundation.
