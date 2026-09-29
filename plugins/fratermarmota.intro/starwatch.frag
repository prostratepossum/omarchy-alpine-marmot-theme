#version 440
// Starwatch live background: twinkles the stars already painted in the image,
// drifts and pulses the fireflies, and sends an occasional shooting star across the sky.
// Everything is derived from the source image (high-pass detection), so no
// extra art is needed and non-star texture (grass, snow) is left alone.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;        // seconds, wraps
    vec2 texel;        // 1 / texture size in px
    float aspect;      // width / height
};

layout(binding = 1) uniform sampler2D source;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

const vec2 offs[8] = vec2[8](vec2(3.0, 0.0), vec2(-3.0, 0.0), vec2(0.0, 3.0), vec2(0.0, -3.0),
                             vec2(2.1, 2.1), vec2(-2.1, 2.1), vec2(2.1, -2.1), vec2(-2.1, -2.1));

// Fireflies are yellow blobs up to ~20px. A pixel belongs to one when it is
// yellower than the least-yellow sample on a 12px ring, which takes in the
// whole soft glow, not just the core, so the firefly lifts off cleanly.
// Returns mask strength at q; glow is its light above the surroundings, bg
// the (non-yellow) surroundings used to paint over the vacated spot.
float fireflyAt(vec2 q, out vec3 glow, out vec3 bg) {
    vec3 cq = texture(source, q).rgb;
    vec3 acc = vec3(0.0);
    float wsum = 0.0;
    float yMin = 1.0;
    for (int i = 0; i < 8; i++) {
        vec3 s = texture(source, q + texel * offs[i] * 4.0).rgb;
        float ys = min(s.r, s.g) - s.b;
        float w = 1.0 - smoothstep(0.02, 0.10, ys);             // skip yellow samples
        acc += s * w;
        wsum += w;
        yMin = min(yMin, ys);
    }
    bg = wsum > 0.01 ? acc / wsum : cq;
    glow = max(cq - bg, vec3(0.0));
    float yc = min(cq.r, cq.g) - cq.b;
    float inGrass = smoothstep(-0.01, 0.04, bg.g - bg.b);      // not the orange nebula
    return smoothstep(0.04, 0.12, yc) * smoothstep(0.03, 0.10, yc - yMin) * inGrass;
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec3 c = texture(source, uv).rgb;

    // Ring average ~3px out: local "background" around this pixel.
    // Stars/fireflies are isolated points: brighter than every ring sample.
    // Edges (ridge line, grass tips, snow) always have a bright neighbour.
    vec3 ring = vec3(0.0);
    float ringMax = 0.0;
    for (int i = 0; i < 8; i++) {
        vec3 s = texture(source, uv + texel * offs[i]).rgb;
        ring += s;
        ringMax = max(ringMax, luma(s));
    }
    ring *= 0.125;

    vec3 detail = max(c - ring, vec3(0.0));   // bright point-like detail
    float hp = luma(detail);
    float point = smoothstep(0.01, 0.06, luma(c) - ringMax);

    // Per-point identity: coarse cell so a whole star shares one phase.
    vec2 px = uv / texel;
    vec2 cell = floor(px / 6.0);
    float h1 = hash21(cell);
    float h2 = hash21(cell + 17.7);

    // --- Stars: only against dark, blue-dominant sky (excludes grass, snow).
    float sky = step(ring.g, ring.b) * step(ring.r, ring.b) * (1.0 - smoothstep(0.30, 0.45, luma(ring)));
    float starMask = smoothstep(0.03, 0.14, hp) * sky * point;
    float f = 0.35 + 1.1 * h1;                                  // Hz-ish
    float tw = sin(time * f * 6.2831 + h2 * 6.2831)
             * (0.6 + 0.4 * sin(time * (0.13 + 0.2 * h2) * 6.2831 + h1 * 40.0));
    // Mostly gentle; a few stars flare harder.
    float amp = mix(0.45, 1.1, step(0.85, h2));
    c += starMask * detail * amp * tw;

    // --- Fireflies: lift each one off its painted spot and redraw it a few
    // px away on a slow wandering path, with a breathing pulse. The drift
    // field is smooth in space, so a whole firefly moves as one piece while
    // fireflies far apart drift independently.
    vec3 glowHome, bgHome;
    float homeMask = fireflyAt(uv, glowHome, bgHome);
    c = mix(c, bgHome, homeMask);

    vec2 drift = vec2(
        4.0 * sin(time * 0.31 + px.y * 0.011 + px.x * 0.004)
      + 1.5 * sin(time * 0.87 + px.x * 0.023),
        3.0 * cos(time * 0.23 + px.x * 0.009 - px.y * 0.006)
      + 1.5 * sin(time * 1.13 + px.y * 0.019));
    vec2 from = uv - drift * texel;
    vec3 glow, bgFrom;
    float fireMask = fireflyAt(from, glow, bgFrom);
    vec2 fcell = floor(from / texel / 16.0);
    float f1 = hash21(fcell + 5.3);
    float f2 = hash21(fcell + 9.9);
    float fp = 0.5 + 0.5 * sin(time * (0.2 + 0.3 * f1) * 6.2831 + f2 * 6.2831);
    fp = fp * fp;                                               // longer dim, brief glow
    c += fireMask * glow * (0.45 + 1.3 * fp);

    // --- Shooting star: one per ~17s cycle, ~40% of cycles, upper sky only.
    const float period = 17.0;
    float cyc = floor(time / period);
    float lt = time - cyc * period;
    float seed = hash21(vec2(cyc, 3.1));
    if (seed < 0.4 && lt < 1.1) {
        float prog = lt / 1.1;
        vec2 start = vec2(0.25 + 0.6 * hash21(vec2(cyc, 7.3)), 0.04 + 0.18 * hash21(vec2(cyc, 9.1)));
        vec2 dir = normalize(vec2(-0.8 - 0.4 * hash21(vec2(cyc, 1.7)), 0.45));
        vec2 p = vec2(uv.x * aspect, uv.y);
        vec2 s = vec2(start.x * aspect, start.y);
        float len = 0.22;
        vec2 head = s + dir * (0.55 * prog);
        vec2 d = p - head;
        float along = -dot(d, dir);                             // distance behind head
        float across = abs(d.x * dir.y - d.y * dir.x);
        float tail = step(0.0, along) * (1.0 - smoothstep(0.0, len, along));
        float width = 0.0012 + 0.0022 * (1.0 - along / len);
        float streak = tail * (1.0 - smoothstep(0.0, width, across));
        float headGlow = exp(-dot(d, d) / 0.00001);
        float fade = sin(prog * 3.14159);
        float skyHere = 1.0 - smoothstep(0.30, 0.42, uv.y);
        c += vec3(0.85, 0.92, 1.0) * (streak * 0.9 + headGlow * 0.8) * fade * skyHere;
    }

    fragColor = vec4(c, 1.0) * qt_Opacity;
}
