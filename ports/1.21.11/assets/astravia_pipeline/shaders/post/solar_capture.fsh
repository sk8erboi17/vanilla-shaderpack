#version 330
#moj_import <minecraft:globals.glsl>
#moj_import <elytraglide:eg_bus.glsl>
#moj_import <shader_selector:utils.glsl>
uniform sampler2D DataSampler;
#moj_import <shader_selector:data_reader.glsl>
uniform sampler2D DepthSampler;
uniform sampler2D PreviousSampler;
in vec2 texCoord;
out vec4 fragColor;
void main(){
    ivec2 pixel=ivec2(gl_FragCoord.xy);
    EgBus bus=eg_decode_bus(GameTime);
    if(GameTime>=0.0||readChannel(5)<.5){
        fragColor=encodeFloat(pixel.y==0?0.0:1.0);return;
    }
    if(!bus.solar){fragColor=texelFetch(PreviousSampler,pixel,0);return;}
    float value=texture(DepthSampler,texCoord).r;
    if(pixel.y==0){
        value=0.0;
        if(pixel.x==0)value=1.0;
        else if(pixel.x==1)value=bus.solarAngle;
        else if(pixel.x<5)value=float((CameraBlockPos[pixel.x-2]%4096+4096)%4096);
        else if(pixel.x==5)value=ScreenSize.x;
        else if(pixel.x==6)value=ScreenSize.y;
    }
    fragColor=encodeFloat(value);
}
