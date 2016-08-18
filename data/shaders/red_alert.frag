uniform float u_Time;
uniform sampler2D u_Tex0;
varying vec2 v_TexCoord;

// red alert fragment shader
void main()
{
    vec4 col = texture2D(u_Tex0, v_TexCoord);
    float d = u_Time * 2.0;
    float diff = max(sin(d*1.3) * 0.06, 0.0);
    col.x += diff;
    col.y -= diff;
    col.z -= diff;
    gl_FragColor = col;
}