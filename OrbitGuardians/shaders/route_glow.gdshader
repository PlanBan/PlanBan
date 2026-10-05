shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform vec4 color : source_color = vec4(0.02,0.7,1.0,1.0);
uniform float radius = 0.34;
uniform float strength = 0.6;
void fragment() {
 float d = length(UV-vec2(0.5));
 float ring = exp(-abs(d-radius)*25.0);
 float haze = exp(-d*7.0)*0.16;
 ALBEDO = color.rgb;
 ALPHA = (ring+haze)*strength;
}
