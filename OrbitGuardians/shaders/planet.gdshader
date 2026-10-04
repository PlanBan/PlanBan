shader_type canvas_item;
uniform vec4 tint : source_color = vec4(0.3, 0.8, 0.6, 1.0);
uniform int biome = 0;
uniform float clock = 0.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float fbm(vec2 p) { return noise(p)*0.55+noise(p*2.1)*0.27+noise(p*4.3)*0.13+noise(p*8.2)*0.05; }
void fragment() {
 vec2 p=(UV-0.5)*2.3; float r=length(p);
 float atmosphere=exp(-abs(r-0.99)*28.0)*0.42;
 vec3 surface=tint.rgb*0.4; float alpha=atmosphere;
 if(r<1.0) {
  vec3 n=vec3(p,sqrt(max(0.0,1.0-r*r)));
  vec2 sphere=vec2(atan(n.x,n.z),asin(n.y))*2.8+vec2(clock*0.018,0.0);
  float land=fbm(sphere*3.2);
  if(biome==0) surface=mix(vec3(0.035,0.18,0.26),vec3(0.24,0.56,0.32),smoothstep(0.42,0.57,land));
  if(biome==1) surface=mix(vec3(0.10,0.28,0.45),vec3(0.74,0.91,0.96),smoothstep(0.3,0.65,land));
  if(biome==2) { surface=mix(vec3(0.12,0.055,0.045),vec3(0.42,0.20,0.10),land); surface+=vec3(1.0,0.28,0.04)*pow(max(0.0,1.0-abs(land-0.49)*15.0),8.0); }
  if(biome==3) surface=mix(vec3(0.36,0.20,0.10),vec3(0.84,0.65,0.34),land);
  if(biome==4) { surface=mix(vec3(0.075,0.065,0.15),vec3(0.25,0.17,0.35),land); vec2 grid=abs(fract(sphere*12.0)-0.5); float circuits=step(0.48,max(grid.x,grid.y)); surface+=vec3(0.30,0.18,0.65)*circuits*(0.5+0.5*sin(clock+land*15.0)); }
  float cloud=smoothstep(0.60,0.76,fbm(sphere*4.0+vec2(clock*0.025,0)));
  if(biome<2) surface=mix(surface,vec3(0.9,0.96,1.0),cloud*0.70);
  float light=max(dot(n,normalize(vec3(-0.6,-0.45,0.8))),0.0);
  surface*=0.14+light*0.98;
  surface+=tint.rgb*pow(1.0-n.z,3.5)*0.42;
  alpha=1.0;
 } else surface=tint.rgb;
 COLOR=vec4(surface,alpha*(1.0-smoothstep(1.03,1.15,r)));
}
