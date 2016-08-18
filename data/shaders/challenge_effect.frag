uniform float u_Time;
uniform sampler2D u_Tex0;
varying vec2 v_TexCoord;

#define intensity 1.8
#define speed 0.0
#define radius 0.09

const vec4 black = vec4(0.0, 0.0,0.0,1.0);
void main() {

	vec2 dir = 0.5 - v_TexCoord;
	dir.x -= 0.02;
	dir.y += 0.02;
    float dist = sqrt(dir.x*dir.x + dir.y*dir.y);
    float scale = 0.8 + dist*0.5;

    float alpha = dist * scale * intensity * (1.0 + sin(speed*u_Time) * radius);
	gl_FragColor=mix(texture2D(u_Tex0, v_TexCoord), black, alpha);
}