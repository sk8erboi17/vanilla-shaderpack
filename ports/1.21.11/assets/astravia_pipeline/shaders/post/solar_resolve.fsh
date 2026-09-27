#version 330
#moj_import <minecraft:globals.glsl>
#moj_import <elytraglide:eg_bus.glsl>
uniform sampler2D InSampler;
uniform sampler2D HistorySampler;
in vec2 texCoord;
out vec4 fragColor;
void main(){
    vec4 history=texture(HistorySampler,texCoord);
    if(eg_decode_bus(GameTime).solar){
        // Capture frames are never presented as a light-space view to the user.
        fragColor=history.a>.5?history:vec4(0.0,0.0,0.0,1.0);
    }else fragColor=vec4(texture(InSampler,texCoord).rgb,1.0);
}
