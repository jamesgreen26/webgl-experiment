precision highp float;

uniform float uTime;
uniform vec2 uResolution;

// Signed distance to cube
float cubeSDF(vec3 p, vec3 size) {
    vec3 d = abs(p) - size;
    return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
}

// Rotation matrix around the Y axis
mat3 rotationY(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat3(
        c, 0.0, -s,
        0.0, 1.0, 0.0,
        s, 0.0, c
    );
}

// Rotation matrix around the X axis
mat3 rotationX(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat3(
        1.0, 0.0, 0.0,
        0.0, c, -s,
        0.0, s, c
    );
}

float raymarch(vec3 ro, vec3 rd, float time) {
    float t = 0.0;
    for (int i = 0; i < 100; i++) {
        vec3 p = ro + t * rd;

        // Rotate the cube in space
        p *= rotationY(time * 0.7);
        p *= rotationX(time * 0.5);

        float d = cubeSDF(p, vec3(0.5));
        if (d < 0.001) break;
        t += d;
        if (t > 10.0) break;
    }
    return t;
}

vec3 getRay(vec2 uv) {
    vec3 ro = vec3(0.0, 0.0, 3.0);
    vec3 target = vec3(0.0);
    vec3 f = normalize(target - ro);
    vec3 r = normalize(cross(vec3(0.0, 1.0, 0.0), f));
    vec3 u = cross(f, r);
    return normalize(uv.x * r + uv.y * u + 1.5 * f);
}



void main() {
    vec2 uv = (gl_FragCoord.xy / uResolution) * 2.0 - 1.0;
    uv.x *= uResolution.x / uResolution.y;

    vec3 ro = vec3(0.0, 0.0, 3.0);
    vec3 rd = getRay(uv);
    float t = raymarch(ro, rd, uTime);

    vec3 color = vec3(t * t * 0.1);
    

    gl_FragColor = vec4(color, 1.0);
}