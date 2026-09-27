#version 330
#moj_import <minecraft:globals.glsl>
#moj_import <elytraglide:eg_bus.glsl>
#moj_import <shader_selector:utils.glsl>
uniform sampler2D DataSampler;
#moj_import <shader_selector:data_reader.glsl>
#moj_import <astravia_pipeline:solar_projection.glsl>
uniform sampler2D DepthSampler;
uniform sampler2D ShadowMapSampler;
in vec2 texCoord;
out vec4 fragColor;
float meta(int i){return decodeColor(texelFetch(DataSampler,ivec2(i%5,6+i/5),0));}
float header(int i){return decodeColor(texelFetch(ShadowMapSampler,ivec2(i,0),0));}
vec3 viewPosition(vec2 uv,float depth,vec4 p){
    float z=-p.w/(depth*2.0-1.0+p.z);
    return vec3((uv*2.0-1.0)*(-z)/p.xy,z);
}
vec3 viewAt(vec2 uv,vec4 projection){
    return viewPosition(uv,texture(DepthSampler,uv).r,projection);
}
vec3 receiverNormal(vec3 center,vec4 projection,mat3 inverseView){
    // Choose neighbors on the same surface. Quad derivatives cross sky/terrain
    // edges and made the shallow ground normals fail as the camera retreated.
    vec2 pixel=1.0/vec2(textureSize(DepthSampler,0));
    vec3 left=center-viewAt(texCoord-vec2(pixel.x,0.0),projection);
    vec3 right=viewAt(texCoord+vec2(pixel.x,0.0),projection)-center;
    vec3 down=center-viewAt(texCoord-vec2(0.0,pixel.y),projection);
    vec3 up=viewAt(texCoord+vec2(0.0,pixel.y),projection)-center;
    vec3 dx=abs(left.z)<abs(right.z)?left:right;
    vec3 dy=abs(down.z)<abs(up.z)?down:up;
    vec3 normal=normalize(cross(dx,dy));
    if(dot(normal,center)>0.0)normal=-normal;
    return normalize(inverseView*normal);
}
void main(){
    fragColor=vec4(1.0);
    EgBus bus=eg_decode_bus(GameTime);
    if(GameTime>=0.0||readChannel(5)<.5||bus.solar||bus.mask!=0||header(0)<.5)return;
    vec4 projection=vec4(meta(0),meta(1),meta(2),meta(3));
    if(projection.x<=0.0||projection.y<=0.0||projection.w>=0.0||meta(7)<.08)return;
    float depth=texture(DepthSampler,texCoord).r;
    if(depth>=1.0)return;
    vec3 view=viewPosition(texCoord,depth,projection);
    if(view.z>=-.15||length(view)>SOLAR_FADE_END)return;
    mat4 modelView;
    for(int i=0;i<16;i++)modelView[i/4][i%4]=meta(8+i);
    if(abs(determinant(modelView))<.01)return;
    mat4 inverseView=inverse(modelView);
    vec3 relative=(inverseView*vec4(view,1.0)).xyz-CameraOffset;
    vec3 offset=mod(vec3(CameraBlockPos)-vec3(header(2),header(3),header(4))+2048.0,4096.0)-2048.0;
    if(length(offset)>SOLAR_FADE_END)return;
    vec3 position=relative+offset;
    vec3 normal=receiverNormal(view,projection,mat3(inverseView));
    float angle=header(1);
    vec3 light=solarDirection(angle);
    float daylight=smoothstep(.08,.3,meta(7));
    float NdotL=dot(normal,light);
    if(NdotL<=.025)return;
    // Normal bias is in world blocks, independent of FOV and screen resolution.
    vec3 biasedPosition=position+normal*.065;
    vec3 projected=solarClip(biasedPosition,angle).xyz*.5+.5;
    if(any(lessThanEqual(projected,vec3(0.0)))||any(greaterThanEqual(projected,vec3(1.0))))return;
    vec2 size=vec2(textureSize(ShadowMapSampler,0));
    if(abs(header(5)-size.x)>.5||abs(header(6)-size.y)>.5)return;
    float shade=0.0,weight=0.0;
    vec3 lightRight=normalize(cross(vec3(0.0,0.0,1.0),light));
    vec3 lightUp=cross(light,lightRight);
    vec2 planeOrigin=vec2(dot(biasedPosition,lightRight),dot(biasedPosition,lightUp));
    vec2 planeSlope=vec2(dot(normal,lightRight),dot(normal,lightUp))/NdotL/(2.0*SOLAR_DEPTH);
    for(int y=-1;y<=1;y++)for(int x=-1;x<=1;x++){
        ivec2 p=ivec2(projected.xy*size)+ivec2(x,y);
        if(p.y<=0||any(lessThan(p,ivec2(0)))||any(greaterThanEqual(p,ivec2(size))))continue;
        float nearest=decodeColor(texelFetch(ShadowMapSampler,p,0));
        float w=(x==0?2.0:1.0)*(y==0?2.0:1.0);
        // JNNGL's distortion grows the depth error away from the capture origin.
        // Match the bias to the distorted texel footprint, keeping nearby contact.
        float radius=length(position-light*dot(position,light))/SOLAR_RADIUS+.1;
        float bias=(.00022+.0003*(1.0-NdotL)+.0025*radius*radius)*(128.0/SOLAR_DEPTH);
        // Invert the distorted projection at each sample and intersect the
        // receiver plane analytically. Screen derivatives lose precision at
        // grazing angles and previously washed out distant cast shadows.
        vec2 mapNdc=(vec2(p)+.5)/size*2.0-1.0;
        if(length(mapNdc)>=.999)continue;
        vec2 planeSample=mapNdc*(SOLAR_DISTORTION*SOLAR_RADIUS)/(1.0-length(mapNdc));
        float receiver=projected.z+dot(planeSlope,planeSample-planeOrigin);
        shade+=(receiver-bias>nearest?1.0:0.0)*w;weight+=w;
    }
    shade/=max(weight,1.0);
    float fade=1.0-smoothstep(SOLAR_FADE_START,SOLAR_FADE_END,length(view));
    fragColor=vec4(vec3(1.0-.68*shade*daylight*fade),1.0);
}
