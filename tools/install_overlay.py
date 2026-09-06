#!/usr/bin/env python3
"""Install the Drylands Relay overlay onto the pinned official Godot TPS demo."""
from __future__ import annotations

import argparse
import shutil
from pathlib import Path

PINNED_COMMIT = "90f2e38d7b5cf9e6fd0b788d0da1df4b84d49269"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"Patch '{label}' expected exactly 1 match, found {count}")
    return text.replace(old, new, 1)


def patch_project(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    text = replace_once(
        text,
        'config/name="Godot Third-Person Shooter Demo"',
        'config/name="Drylands Relay"',
        "project name",
    )
    text = replace_once(
        text,
        'config/description="Godot Third Person Shooter with high quality assets and lighting"',
        'config/description="Drylands Relay — Godot TPS rebuild"',
        "description",
    )
    text = replace_once(
        text,
        'run/main_scene="res://main/main.tscn"',
        'run/main_scene="res://drylands/game.tscn"',
        "main scene",
    )
    text = replace_once(
        text,
        'Settings="*res://menu/settings.gd"',
        'Settings="*res://menu/settings.gd"\nDrylandsState="*res://drylands/drylands_state.gd"',
        "autoload",
    )

    # Browser-first build: make Compatibility the actual project renderer, not
    # merely a feature-tag override. Godot 4 Web exports only support WebGL 2
    # through the Compatibility renderer. Native Android can get its Mobile
    # renderer back when we resume the native export track.
    if '[rendering]' not in text:
        text += '\n[rendering]\n'

    if 'renderer/rendering_method="gl_compatibility"' not in text:
        text = text.replace(
            '[rendering]\n',
            '[rendering]\nrenderer/rendering_method="gl_compatibility"\n',
            1,
        )

    if 'renderer/rendering_method.web="gl_compatibility"' not in text:
        text = text.replace(
            '[rendering]\n',
            '[rendering]\nrenderer/rendering_method.web="gl_compatibility"\n',
            1,
        )

    # HDR window output is not part of the browser preview path and can trip
    # platform validation on a compatibility/WebGL export.
    text = text.replace(
        'window/hdr/request_hdr_output=true',
        'window/hdr/request_hdr_output=false',
    )

    if 'window/handheld/orientation=0' not in text:
        text = text.replace(
            '[display]\n',
            '[display]\n\nwindow/handheld/orientation=0\n',
            1,
        )

    # CRITICAL WEB FIX:
    # The upstream TPS demo sets scaling_3d/mode=2 (FSR2). FSR2 only works
    # with Forward+, while Godot Web export uses Compatibility/WebGL 2.
    # A `.web` override is not enough during headless export because the
    # editor initializes the root viewport from the base project setting.
    text = replace_once(
        text,
        'scaling_3d/mode=2',
        'scaling_3d/mode=0',
        'disable Forward+-only FSR2 for Web export',
    )

    # Native-resolution bilinear rendering for browser validation.
    if 'scaling_3d/scale=' not in text:
        text = text.replace(
            '[rendering]\n',
            '[rendering]\nscaling_3d/scale=1.0\n',
            1,
        )

    # Keep explicit Web overrides too.
    if 'scaling_3d/mode.web=0' not in text:
        text = text.replace(
            '[rendering]\n',
            '[rendering]\n'
            'scaling_3d/mode.web=0\n'
            'scaling_3d/scale.web=1.0\n'
            'lights_and_shadows/positional_shadow/atlas_size.web=1024\n',
            1,
        )

    # Compatibility browser preview does not need the Forward+/Mobile HDR 2D path.
    text = text.replace(
        'viewport/hdr_2d=true',
        'viewport/hdr_2d=false',
    )

    if 'scaling_3d/mode=2' in text:
        raise RuntimeError(
            'FSR2 is still enabled in project.godot; '
            'Compatibility/Web export cannot continue.'
        )

    # Single-threaded Web export is intentionally used for widest hosting
    # compatibility. Keep 3D physics on the main thread as well.
    if '[physics]' in text and '3d/run_on_separate_thread=false' not in text:
        text = text.replace(
            '[physics]\n',
            '[physics]\n3d/run_on_separate_thread=false\n',
            1,
        )

    path.write_text(text, encoding="utf-8")


def patch_player(path: Path) -> None:
    text = path.read_text(encoding="utf-8")

    text = replace_once(
        text,
        '\torientation.origin = Vector3()\n\tif not multiplayer.is_server():',
        '\torientation.origin = Vector3()\n'
        '\tadd_to_group(&"drylands_player")\n'
        '\tDrylandsState.register_player(self)\n'
        '\tif not multiplayer.is_server():',
        "player registration",
    )

    text = replace_once(
        text,
        '\tvar h_velocity: Vector3 = orientation.origin / delta\n'
        '\tvelocity.x = h_velocity.x\n'
        '\tvelocity.z = h_velocity.z\n'
        '\tvelocity += get_gravity() * delta',
        '''\tvar h_velocity: Vector3 = orientation.origin / delta
\tvar speed_scale := 1.35 if Input.is_action_pressed(&"sprint") and not on_air else 1.0
\tvelocity.x = h_velocity.x * speed_scale
\tvelocity.z = h_velocity.z * speed_scale
\tvelocity += get_gravity() * delta

\t# Drylands wingsuit: preserve the upstream animation/camera controller, then
\t# layer a controllable glide and short boost on top of its airborne physics.
\tif on_air and Input.is_action_pressed(&"glide"):
\t\tvelocity.y = maxf(velocity.y, -2.2)
\t\tvar glide_forward := -camera_z
\t\tvar glide_speed := 7.5
\t\tif Input.is_action_pressed(&"boost") and DrylandsState.consume_boost(delta * 31.0):
\t\t\tglide_speed = 13.5
\t\tvelocity.x += glide_forward.x * glide_speed
\t\tvelocity.z += glide_forward.z * glide_speed''',
        "wingsuit physics",
    )

    text = replace_once(
        text,
        '@rpc("call_local")\n'
        'func hit() -> void:\n'
        '\tadd_camera_shake_trauma(0.75)',
        '@rpc("call_local")\n'
        'func hit() -> void:\n'
        '\tDrylandsState.damage_player(18.0, "RED ROBOT")\n'
        '\tadd_camera_shake_trauma(0.75)',
        "player damage",
    )

    path.write_text(text, encoding="utf-8")


def patch_robot(path: Path) -> None:
    text = path.read_text(encoding="utf-8")

    text = replace_once(
        text,
        'const SHOOT_WAIT: float = 6.0',
        'const SHOOT_WAIT: float = 2.8',
        "robot cadence",
    )

    text = replace_once(
        text,
        'const AIM_TIME: float = 1.0',
        'const AIM_TIME: float = 0.65',
        "robot aim",
    )

    text = replace_once(
        text,
        '\t\texplosion_sound.play()\n'
        '\t\texploded.emit()',
        '\t\texplosion_sound.play()\n'
        '\t\tDrylandsState.record_robot_kill()\n'
        '\t\texploded.emit()',
        "kill scoring",
    )

    text = replace_once(
        text,
        '\t\t\tplayer.add_camera_shake_trauma(13.0)',
        '\t\t\tplayer.hit.rpc()',
        "robot damage",
    )

    path.write_text(text, encoding="utf-8")


def patch_level(path: Path) -> None:
    text = path.read_text(encoding="utf-8")

    text = replace_once(
        text,
        'await get_tree().create_timer(15.0).timeout',
        'await get_tree().create_timer(3.0).timeout',
        "respawn tempo",
    )

    path.write_text(text, encoding="utf-8")


def install(base: Path, overlay: Path) -> None:
    required = [
        base / "project.godot",
        base / "player/player.gd",
        base / "enemies/red_robot/red_robot.gd",
        base / "level/level.gd",
    ]

    missing = [str(p) for p in required if not p.exists()]

    if missing:
        raise RuntimeError(
            "Not a compatible TPS demo checkout. Missing: "
            + ", ".join(missing)
        )

    drylands_src = overlay / "drylands"
    drylands_dst = base / "drylands"

    if drylands_dst.exists():
        shutil.rmtree(drylands_dst)

    shutil.copytree(
        drylands_src,
        drylands_dst,
    )

    shutil.copy2(
        overlay / "drylands/export_presets.cfg",
        base / "export_presets.cfg",
    )

    # export_presets.cfg is project-root configuration, not a runtime resource.
    (drylands_dst / "export_presets.cfg").unlink(missing_ok=True)

    patch_project(
        base / "project.godot"
    )

    patch_player(
        base / "player/player.gd"
    )

    patch_robot(
        base / "enemies/red_robot/red_robot.gd"
    )

    patch_level(
        base / "level/level.gd"
    )

    marker = base / "DRYLANDS_REBUILD.txt"

    marker.write_text(
        "Drylands Relay Godot rebuild overlay installed.\n"
        f"Required upstream TPS demo commit: {PINNED_COMMIT}\n",
        encoding="utf-8",
    )


def main() -> None:
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "project",
        type=Path,
        help="Path to the pinned tps-demo checkout",
    )

    parser.add_argument(
        "--overlay",
        type=Path,
        default=Path(__file__).resolve().parents[1],
    )

    args = parser.parse_args()

    install(
        args.project.resolve(),
        args.overlay.resolve(),
    )

    print(
        f"Drylands overlay installed into "
        f"{args.project.resolve()}"
    )


if __name__ == "__main__":
    main()
