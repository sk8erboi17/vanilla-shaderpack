# Astravia-compatible 1.21.11 port

The original 1.21.4 source stays at the repository root. `1.21.11/` contains the
scoped post-processing components used by the combined Flaps/ShaderSelector fork:

- 13-tap bloom prefilter and 9-tap reconstruction, adapted to linear highlights
  from the current scene without replacing its material renderer;
- ambient occlusion based on JNNGL's hemisphere sample kernel;
- short contact shadows using JNNGL's screen-space DDA, with bounded thickness,
  distance and work;
- a depth-aware spatial filter for the contact/AO result.

The controller sends a per-player opt-in and celestial angle. ShaderSelector
exports the actual projection and light direction for each rendered frame. All
passes default to neutral without a valid controller or marker. Fast/Fancy use
Flaps core; these post passes require Fabulous.

This port deliberately retains the existing sky and materials. It does not enable
upstream shadow mapping, atmospheric scattering, PBR, reflections, water waves or
TAA. Screen-space contact shadows cannot see occluders outside the image. The
original project's authorship and licensing status are unchanged by this fork;
no new license is applied to its upstream code.
