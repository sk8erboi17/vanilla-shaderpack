#version 330
uniform sampler2D InSampler;
uniform sampler2D DepthSampler;
uniform sampler2D DataSampler;
#moj_import <shader_selector:utils.glsl>
in vec2 texCoord;
out vec4 fragColor;
float meta(int i){return decodeColor(texelFetch(DataSampler,ivec2(i%5,6+i/5),0));}
void main(){
    vec2 pixel=1.0/vec2(textureSize(InSampler,0));
    float a=meta(2),b=meta(3);
    float centerDepth=texture(DepthSampler,texCoord).r;
    if(centerDepth>=1.0||b>=0.0){fragColor=vec4(1.0);return;}
    float centerZ=-b/(centerDepth*2.0-1.0+a);
    float sum=0.0,weight=0.0;
    for(int y=-1;y<=1;y++)for(int x=-1;x<=1;x++){
        vec2 uv=texCoord+vec2(x,y)*pixel;
        float depth=texture(DepthSampler,uv).r;
        float z=-b/(depth*2.0-1.0+a);
        float w=float((x==0?2:1)*(y==0?2:1))*exp(-abs(z-centerZ)*12.0);
        sum+=texture(InSampler,uv).r*w;weight+=w;
    }
    fragColor=vec4(vec3(sum/max(weight,.00001)),1.0);
}
