#version 330
// JNNGL bloom filter port: native 1.21.11 post UBOs, LDR input converted to
// linear highlights. Preserve Astravia sky/materials; no deferred G-buffer.
uniform sampler2D InSampler;
uniform sampler2D DataSampler;
#moj_import <shader_selector:utils.glsl>
#moj_import <shader_selector:data_reader.glsl>
in vec2 texCoord;
out vec4 fragColor;
vec3 sampleBright(sampler2D samp, vec2 uv) {
    uv = clamp(uv, 0.5 / vec2(textureSize(samp, 0)), 1.0 - 0.5 / vec2(textureSize(samp, 0)));
    vec3 c = texture(samp, uv).rgb;
    return max(pow(c, vec3(2.2)) - vec3(0.72), vec3(0.0));
}
void main() {
    if (readChannel(5) < 0.001) { fragColor = vec4(0.0); return; }
    vec2 stepUV = 3.0 / vec2(textureSize(InSampler, 0));
    float x = stepUV.x;
    float y = stepUV.y;
    vec3 a = sampleBright(InSampler, vec2(texCoord.x - 2 * x, texCoord.y + 2 * y));
    vec3 b = sampleBright(InSampler, vec2(texCoord.x,         texCoord.y + 2 * y));
    vec3 c = sampleBright(InSampler, vec2(texCoord.x + 2 * x, texCoord.y + 2 * y));

    vec3 d = sampleBright(InSampler, vec2(texCoord.x - 2 * x, texCoord.y));
    vec3 e = sampleBright(InSampler, vec2(texCoord.x,         texCoord.y));
    vec3 f = sampleBright(InSampler, vec2(texCoord.x + 2 * x, texCoord.y));

    vec3 g = sampleBright(InSampler, vec2(texCoord.x - 2 * x, texCoord.y - 2 * y));
    vec3 h = sampleBright(InSampler, vec2(texCoord.x,         texCoord.y - 2 * y));
    vec3 i = sampleBright(InSampler, vec2(texCoord.x + 2 * x, texCoord.y - 2 * y));

    vec3 j = sampleBright(InSampler, vec2(texCoord.x - x, texCoord.y + y));
    vec3 k = sampleBright(InSampler, vec2(texCoord.x + x, texCoord.y + y));
    vec3 l = sampleBright(InSampler, vec2(texCoord.x - x, texCoord.y - y));
    vec3 m = sampleBright(InSampler, vec2(texCoord.x + x, texCoord.y - y));

    vec3 color = e * 0.125;
    color += (a + c + g + i) * 0.03125;
    color += (b + d + f + h) * 0.0625;
    color += (j + k + l + m) * 0.125;

    fragColor = vec4(color, 1.0);
}
