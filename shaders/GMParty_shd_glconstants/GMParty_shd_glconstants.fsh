varying vec2 v_vTexcoord;
varying float v_vVTF;

int cons(in int _index) {
	if (_index == 0)	return gl_MaxTextureImageUnits;
	if (_index == 1)	return gl_MaxCombinedTextureImageUnits;
	if (_index == 2)	return gl_MaxDrawBuffers;
	if (_index == 3)	return gl_MaxFragmentUniformVectors;
	if (_index == 4)	return gl_MaxVaryingVectors;
	if (_index == 5)	return gl_MaxVertexAttribs;
	if (_index == 6)	return gl_MaxVertexTextureImageUnits;
	if (_index == 7)	return gl_MaxVertexUniformVectors;
	if (_index == 8)	return __VERSION__;
	if (_index == 9)	return GL_ES;
	if (_index == 10)	return int(v_vVTF);
	return 0;
}

vec4 enc(in int _val) {
	float fval = float(_val);
	int div = _val / 256;
	return vec4(float(div) / 255.0, (fval - float(div * 256)) / 255.0, 0.0, 1.0);
}

void main()
{
	int _index = int(v_vTexcoord.x) + int(v_vTexcoord.y) * 4;
	gl_FragColor = enc(cons(_index));
}

