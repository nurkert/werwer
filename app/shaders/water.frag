#version 460 core
// Waves on the painted water of a stage set (task 015): the set's own
// pixels, shifted a little sideways row by row, so the reflections of the
// lights sway. The shift fades out at the water's edges, where the layer
// meets the untouched picture without a seam.
#include <flutter/runtime_effect.glsl>

uniform vec4 uPlate;  // left, top, width, height of the picture on the canvas
uniform vec4 uWater;  // x0, y0, x1, y1 of the water, as fractions of the picture
uniform float uTime;
uniform sampler2D uImage;

out vec4 fragColor;

void main() {
  vec2 uv = (FlutterFragCoord().xy - uPlate.xy) / uPlate.zw;
  float band = clamp((uv.y - uWater.y) / (uWater.w - uWater.y), 0.0, 1.0);
  float edge = sin(3.14159265 * band);
  float sides = smoothstep(uWater.x, uWater.x + 0.05, uv.x) *
      (1.0 - smoothstep(uWater.z - 0.05, uWater.z, uv.x));
  float a = edge * edge * sides;
  // Waves grow nearer the shore: wider and slower further down.
  float k = 330.0 - 150.0 * band;
  float dx = (0.6 * sin(uv.y * k + uTime * 1.6) +
              0.4 * sin(uv.y * k * 2.17 - uTime * 2.4 + uv.x * 9.0)) *
             0.0048 * (0.45 + band) * a;
  float dy = sin(uv.x * 38.0 + uTime * 0.8 + uv.y * 70.0) * 0.0009 * a;
  fragColor = texture(uImage, uv + vec2(dx, dy));
}
