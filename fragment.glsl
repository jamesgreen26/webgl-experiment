precision highp float;

uniform float uTime;

uniform float uRotationX;
uniform float uRotationY;

uniform vec2 uResolution;

const float waveCount = 12.0;


float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

float waveLayer(vec3 p, float time, float i) {
    float r = hash(i);
    float dir = sin(r) * p.z + cos(r) * p.x;
    return (sin((dir * pow(1.2, i) * 2.0) + time * 1.5 * pow(-1.0, i)) * pow(0.7, i)) / 24.0;
}


vec2 waveLayerDeriv(vec3 p, float time, float i) {
    float r = hash(i);
    float sinr = sin(r);
    float cosr = cos(r);

    float A = pow(1.2, i) * 2.0;
    float B = 1.5 * pow(-1.0, i);
    float C = pow(0.7, i) / 24.0;

    float d = sinr * p.z + cosr * p.x;
    float theta = d * A + time * B;
    float cosTheta = cos(theta);

    // ∂y/∂x = cos(theta) * A * cos(r) * C
    // ∂y/∂z = cos(theta) * A * sin(r) * C
    return vec2(cosTheta * A * cosr * C, cosTheta * A * sinr * C);
}

vec3 getAnalyticNormal(vec3 p, float time) {
    float y = 0.0;
    float dydx = 0.0;
    float dydz = 0.0;

    for (float i = 0.0; i < waveCount; i++) {
        y += waveLayer(p, time, i);
        vec2 deriv = waveLayerDeriv(p, time, i);
        dydx += deriv.x;
        dydz += deriv.y;
    }

    // Tangent vectors: (1, dydx, 0) and (0, dydz, 1)
    vec3 tangentX = vec3(1.0, dydx, 0.0);
    vec3 tangentZ = vec3(0.0, dydz, 1.0);
    return normalize(cross(tangentZ, tangentX));
}


float sphereSDF(vec3 p, vec3 size, float time) {
    float y = 0.0;
    for (float i = 0.0; i < waveCount; i++) {
        y += waveLayer(p, time, i);
    }
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
    vec2 pixel = gl_FragCoord.xy;
    vec2 offsets[4];
    offsets[0] = vec2(-0.25, -0.25);
    offsets[1] = vec2( 0.25, -0.25);
    offsets[2] = vec2(-0.25,  0.25);
    offsets[3] = vec2( 0.25,  0.25);

    vec3 finalColor = vec3(0.0);

    for (int i = 0; i < 4; ++i) {
        vec2 uv = ((pixel + offsets[i]) / uResolution) * 2.0 - 1.0;
        uv.x *= uResolution.x / uResolution.y;

        vec3 ro = vec3(0.0, 0.0, 3.0);
        vec3 rd = getRay(uv);
        float scaledTime = uTime * 1.2;

        float t = raymarch(ro, rd, scaledTime);
        vec3 color = vec3(1.0);

        if (t < 10.0) {
            vec3 hitPoint = ro + rd * t;
            mat3 rot = rotationMatrix(uRotationX, uRotationY);
            hitPoint = rot * hitPoint;

            vec3 normal = getAnalyticNormal(hitPoint, scaledTime);
            vec3 viewDir = normalize((rot * ro) - hitPoint);
            vec3 lightDir = normalize(vec3(0.5, 1.0, 1.3));

            float diff = max(dot(normal, lightDir), 0.0);
            float spec = pow(max(dot(normal, normalize(lightDir + viewDir)), 0.0), 64.0);

            float transmission = pow(1.0 - max(dot(viewDir, normal), 0.0), 2.0);
            vec3 transmittedColor = vec3(0.1, 0.6, 0.7) * transmission;

            float fresnel = pow(1.0 - dot(viewDir, normal), 3.0);
            vec3 fresnelColor = mix(vec3(0.1, 0.3, 0.4), vec3(1.0), fresnel);

            color = vec3(0.2, 0.6, 1.0) * diff;
            color += (transmittedColor / 10.0);
            color *= fresnelColor;
            color += vec3(0.9, 1.0, 1.0) * spec * diff;
        }

        finalColor += color;
    }

    finalColor /= 4.0; // average the 4 samples
    gl_FragColor = vec4(finalColor, 1.0);
}