shader_type spatial;
render_mode cull_disabled;
uniform vec4 tint : source_color = vec4(0.015,0.28,0.34,1.0);
uniform float hot = 0.0;
varying vec3 local_pos;
void vertex() { local_pos = VERTEX; }
void fragment() {
 float ripple = sin(local_pos.z*27.0+local_pos.x*12.0-TIME*2.6)*0.5+0.5;
 float current = pow(sin(local_pos.z*8.0+local_pos.x*23.0-TIME*1.8)*0.5+0.5,12.0);
 ALBEDO = tint.rgb*(0.65+ripple*0.28)+vec3(0.13,0.38,0.42)*current*0.4;
 METALLIC = 0.5;
 ROUGHNESS = 0.19+ripple*0.09;
 EMISSION = tint.rgb*(hot*1.3+current*0.24);
}
