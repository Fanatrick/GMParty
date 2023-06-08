varying vec2 v_vTexcoord;

void main() {
    gl_FragColor = vec4(0.5) + texture2D( gm_BaseTexture, v_vTexcoord).argb / 1.;
	gl_FragColor.rgb = vec3(1.0);
	//gl_FragColor.a = 1.0;
	gl_FragColor = vec4(0.0) + texture2D( gm_BaseTexture, v_vTexcoord).rgba / 1024.;
	//if (gl_FragColor.a < 0.1) {
	//	discard;
	//}	else	{
		gl_FragColor.a = 1.0;
		//gl_FragColor.a = texture2D( gm_BaseTexture, v_vTexcoord).a;
	//}
	
	vec2 dir = texture2D( gm_BaseTexture, v_vTexcoord).xy;
	gl_FragColor.xy = 0.5 + dir / 1280.;
	gl_FragColor.z = 1.0;
	gl_FragColor.a = 1.0;//texture2D( gm_BaseTexture, v_vTexcoord).a;
	//gl_FragColor.xyz = mix(gl_FragColor.xyz, vec3(1.0), length(v_vTexcoord - dir)*10.);
}
