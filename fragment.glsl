precision highp float;

uniform float uTime;

uniform float uRotationX;
uniform float uRotationY;

uniform vec2 uResolution;



float sphereSDF(vec3 p, vec3 size, float time) {
    float y = (sin((p.x * -24.0) + time * 1.9) / 96.0) + (sin((p.x * 12.0) + time * 0.9) / 32.0) + (cos((p.x * 3.0) + time * 0.5) / 64.0) + (cos((p.z * 15.0) + time * 1.1) / 24.0)+ (sin((p.z * -25.0) + time * 1.3) / 128.0);
    vec3 d = abs(p - vec3(0.0, y, 0.0)) - vec3(10.0, 0.0, 10.0);
    return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), -0.1);
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

// Rotation matrix around the Z axis
mat3 rotationZ(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat3(
        c, -s, 0.0,
        s, c, 0.0,
        0.0, 0.0, 1.0
    );
}

mat3 rotationMatrix(float angleX, float angleY) {
    return rotationY(angleY) * rotationX(angleX); // Combine rotations
}

float raymarch(vec3 ro, vec3 rd, float time) {
    float t = 0.0;
    mat3 combinedRotation = rotationMatrix(uRotationX, uRotationY); // Create the combined rotation matrix
    
    for (int i = 0; i < 100; i++) {
        vec3 p = ro + t * rd;

        // Apply the combined rotation to the point p
        p = combinedRotation * p;

        float d = sphereSDF(p, vec3(0.5), time);
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

    vec3 color = vec3(pow(t, 1.1) * 0.08, t * 0.12, 1.0);
    

    gl_FragColor = vec4(color, 1.0);
}