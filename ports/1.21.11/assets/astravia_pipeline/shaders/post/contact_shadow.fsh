#version 330
// Astravia-compatible JNNGL port: depth-derived AO and visible-geometry contact
// shadows. No shadow map, material replacement, sky LUT, or temporal history.
uniform sampler2D DepthSampler;
uniform sampler2D DataSampler;
#moj_import <minecraft:globals.glsl>
#moj_import <elytraglide:eg_bus.glsl>
#moj_import <shader_selector:utils.glsl>
#moj_import <shader_selector:data_reader.glsl>
#moj_import <astravia_pipeline:contact_trace.glsl>
in vec2 texCoord;
out vec4 fragColor;
vec4 projectionData;
float meta(int i){return decodeColor(texelFetch(DataSampler,ivec2(i%5,6+i/5),0));}
float viewDepth(float depth){return -projectionData.w/(depth*2.0-1.0+projectionData.z);}
vec3 unproject(vec2 uv,float depth){float z=viewDepth(depth);return vec3((uv*2.0-1.0)*(-z)/projectionData.xy,z);}
vec2 project(vec3 pos){return pos.xy*projectionData.xy/(-pos.z)*.5+.5;}
float ambient(vec3 fragPos,vec3 normal){
    const vec3 sampleVectors[] = vec3[](
        vec3(0.20784318, -0.23137254, 0.3019608), vec3(0.427451, 0.27843142, 0.60784316), 
        vec3(-0.16862744, 0.28627455, 0.18431373), vec3(0.3803922, 0.082352996, 0.27058825), 
        vec3(-0.29411763, 0.07450986, 0.043137256), vec3(-0.035294116, -0.18431371, 0.12156863), 
        vec3(0.13725495, 0.30196083, 0.16862746), vec3(-0.0039215684, -0.0039215684, 0.003921569),
        vec3(-0.27843136, 0.27058828, 0.007843138), vec3(-0.4588235, 0.12941182, 0.02745098), 
        vec3(-0.19215685, -0.0745098, 0.4), vec3(-0.019607842, 0.035294175, 0.003921569),
        vec3(0.06666672, 0.19215691, 0.4862745), vec3(0.019607902, 0.09803927, 0.38039216), 
        vec3(0.035294175, -0.0039215684, 0.0627451), vec3(0.019607902, -0.082352936, 0.06666667)
    );


    vec3 randomVector=normalize(vec3(fract(sin(dot(gl_FragCoord.xy,vec2(12.9898,78.233)))*43758.5453)*2.0-1.0,0.71,0.23));
    vec3 tangent=normalize(randomVector-normal*dot(randomVector,normal));
    mat3 tbn=mat3(tangent,cross(normal,tangent),normal);
    float occlusion=0.0;
    for(int i=0;i<16;i++){
        vec3 pos=fragPos+normal*.025+tbn*sampleVectors[i]*1.5;
        vec2 uv=project(pos);
        if(pos.z>=-.05||any(lessThan(uv,vec2(0.0)))||any(greaterThanEqual(uv,vec2(1.0))))continue;
        float depth=texture(DepthSampler,uv).r;
        if(depth>=1.0)continue;
        float currentDepth=viewDepth(depth);
        float weight=smoothstep(0.0,1.0,.75/max(abs(fragPos.z-currentDepth),.001));
        occlusion+=(currentDepth>=pos.z+.035?1.0:0.0)*weight;
    }
    return 1.0-occlusion/16.0;
}
void main(){
    fragColor=vec4(1.0);
    if(GameTime>=0.0||readChannel(5)<.001||eg_decode_bus(GameTime).mask!=0)return;
    projectionData=vec4(meta(0),meta(1),meta(2),meta(3));
    if(projectionData.x<=0.0||projectionData.y<=0.0||projectionData.w>=0.0)return;
    float depth=texture(DepthSampler,texCoord).r;
    if(depth>=1.0)return;
    vec3 pos=unproject(texCoord,depth);
    // Limit work and avoid far-depth precision artefacts.
    if(pos.z>=-.15||pos.z < -64.0)return;
    vec3 normal=normalize(cross(dFdx(pos),dFdy(pos)));
    if(dot(normal,pos)>0.0)normal=-normal;
    float ao=ambient(pos,normal);
    float contact=0.0;
    vec3 sun=vec3(meta(4),meta(5),meta(6));
    if(length(sun)>.5&&meta(7)>.08&&dot(normal,normalize(sun))>.05){
        mat4 projection=mat4(vec4(projectionData.x,0,0,0),vec4(0,projectionData.y,0,0),
                             vec4(0,0,projectionData.z,-1),vec4(0,0,projectionData.w,0));
        vec2 planes=vec2(projectionData.w/(projectionData.z-1.0),projectionData.w/(projectionData.z+1.0));
        vec2 hitPixel;vec3 hitPoint;
        float jitter=fract(dot(gl_FragCoord.xy,vec2(.25,.75)));
        bool hit=traceScreenSpaceRay(DepthSampler,projection,planes,vec2(textureSize(DepthSampler,0)),
                                    pos+normal*.06,normalize(sun),2.0,jitter,24.0,3.0,hitPixel,hitPoint);
        contact=hit?smoothstep(.08,.3,meta(7)):0.0;
    }
    float factor=(1.0-(1.0-ao)*.22)*(1.0-contact*.28);
    fragColor=vec4(vec3(mix(1.0,factor,1.0-smoothstep(48.0,64.0,-pos.z))),1.0);
}
