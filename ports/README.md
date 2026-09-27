# Astravia-compatible 1.21.11 port

The original 1.21.4 source stays at the repository root. `1.21.11/` contains the
scoped post-processing components used by the combined Flaps/ShaderSelector fork:

- 13-tap bloom prefilter and 9-tap reconstruction, adapted to linear highlights
  from the current scene without replacing its material renderer;
- ambient occlusion based on JNNGL's hemisphere sample kernel;
- short contact shadows using JNNGL's screen-space DDA, with bounded thickness,
  distance and work;
- a depth-aware spatial filter for the contact/AO result;
- distorted orthographic solar shadow maps, depth comparison with analytical receiver-plane
  bias and PCF, and a retained scene during light-space capture ticks.

The controller sends a per-player opt-in and celestial angle. ShaderSelector
exports the actual projection and light direction for each rendered frame. All
passes default to neutral without a valid controller or marker. Fast/Fancy use
Flaps core; these post passes require **Improved Transparency** to be enabled in the 1.21.11 video settings. On macOS, the Fabulous preset can leave that independent setting disabled.

This port deliberately retains the existing sky and materials. It does not enable
atmospheric scattering, PBR, reflections, water waves or TAA. Shadow mapping uses
nearby submitted terrain and an exact server-supplied solar angle. Captures refresh
once per second; the previous scene remains on screen for the approximately 50 ms
capture tick. Native client terrain culling and a radius of 160 blocks bound the
result. Entities are not map casters. Contact rays see only the current depth image. The
original project's authorship and licensing status are unchanged by this fork;
no new license is applied to its upstream code.
