#ifndef ASTRAVIA_SOLAR_PROJECTION
#define ASTRAVIA_SOLAR_PROJECTION
// JNNGL's distorted orthographic shadow projection, scoped to nearby terrain.
// The controller supplies the real celestial angle instead of sampling guesses.
const float SOLAR_RADIUS=128.0;
const float SOLAR_DEPTH=256.0;
// Keep useful texel density at range; the original .1 compressed distant
// two-block pillars into less than one shadow texel on a 720p client.
const float SOLAR_DISTORTION=.5;
const float SOLAR_FADE_START=128.0;
const float SOLAR_FADE_END=160.0;
vec3 solarDirection(float angle){return vec3(-sin(angle),cos(angle),0.0);}
vec4 solarClip(vec3 position,float angle){
    vec3 light=solarDirection(angle);
    vec3 right=normalize(cross(vec3(0.0,0.0,1.0),light));
    vec3 up=cross(light,right);
    vec2 xy=vec2(dot(position,right),dot(position,up))/SOLAR_RADIUS;
    xy/=length(xy)+SOLAR_DISTORTION;
    return vec4(xy,-dot(position,light)/SOLAR_DEPTH,1.0);
}
#endif
