shader_type spatial;
uniform vec4 tint : source_color = vec4(.25,.7,.45,1.);
uniform int biome = 0;
varying vec3 surface;
float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
float noise(vec3 p) {
	vec3 i=floor(p); vec3 f=fract(p); f=f*f*(3.-2.*f);
	return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex(){ surface=VERTEX; }
void fragment(){
	vec3 p=normalize(surface);
	float n=noise(p*3.7)*.58+noise(p*8.)*.27+noise(p*19.)*.15;
	vec3 base=tint.rgb*.45;
	if(biome==0){
		base=mix(vec3(.018,.07,.17),mix(vec3(.04,.16,.10),vec3(.19,.29,.13),n),smoothstep(.46,.51,n));
		base=mix(base,vec3(.38,.46,.48),smoothstep(.82,.98,abs(p.y)));
	}
	if(biome==1) base=mix(vec3(.055,.16,.23),vec3(.4,.63,.68),smoothstep(.38,.64,n));
	if(biome==2) base=mix(vec3(.035,.016,.026),vec3(.9,.16,.025),1.-smoothstep(.012,.045,abs(n-.5)));
	if(biome==3) base=mix(vec3(.13,.065,.025),vec3(.43,.29,.11),smoothstep(.28,.69,n));
	if(biome==4) base=mix(vec3(.02,.012,.05),vec3(.31,.055,.65),pow(abs(sin(p.y*44.)*sin(p.x*44.)),16.));
	float clouds=noise(p*13.+vec3(4.))*noise(p*5.);
	if(biome<2) base=mix(base,vec3(.55,.63,.67),smoothstep(.35,.62,clouds)*.28);
	ALBEDO=base;
	ROUGHNESS=.92;
	EMISSION=base*(biome!=2 ? .07 : .25);
}
