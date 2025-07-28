precision highp float;

uniform float u_resolutionWidth;
uniform float u_resolutionHeight;
uniform float u_time;

out vec4 outputColor;

vec3 mainColor = vec3(0.6, 0.0, 0.3);

float sawtooth(float a, float freq) {
    if (mod(a, freq) < freq * 0.5) return mod(a, freq * 0.5);
    return freq * 0.5 - mod(a, freq * 0.5);
}

void main() {
    vec2 iResolution = vec2(u_resolutionWidth, u_resolutionHeight);
    float iTime = u_time;

    vec2 fragCoord = gl_FragCoord.xy;
    vec2 uv = fragCoord / iResolution.xy;
    float resolutionRatio = iResolution.x / iResolution.y;

    float pxAmt = 256.0;
    uv.x = floor(uv.x * pxAmt) / pxAmt;
    uv.y = floor(uv.y * pxAmt) / pxAmt;

    float pixAmt = 2.0;
    if (mod(fragCoord.y, pixAmt) < pixAmt * 0.5) {
        uv += 0.1 + sin(iTime * 0.2 + uv.y * 8.0) * 0.05;
    } else {
        uv -= 0.1 + sin(iTime * 0.2 + uv.y * 8.0 + 0.5) * 0.05;
    }

    vec2 uv2 = uv;
    vec3 color = vec3(0.1);

    color = vec3(mod(abs(sawtooth(uv.x, 0.6) * resolutionRatio + sawtooth(uv.y, 0.6) + iTime * 0.3), 0.4)) * mainColor;

    if (uv2.x < 0.5) {
        uv2.x = 1.0 - uv2.x;
    }
    if (uv2.y > 0.5) {
        uv2.y = 1.0 - uv2.y;
    }

    uv2.x += sin(uv2.y * 4.0 + iTime) * 0.1;

    if (mod(abs(uv2.x * resolutionRatio + uv2.y + iTime * 0.2), 0.2) < 0.1) {
        vec3 lines = vec3(cos(uv.x * 2.0 + iTime + uv.y * 3.0)) * mainColor * 0.7;
        color = mix(color, lines, 0.3);
    }

    float shortAmt = 10.0;
    color = ceil(color * shortAmt) / shortAmt;

    outputColor = vec4(color, 1.0);
}
