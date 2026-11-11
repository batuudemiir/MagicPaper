#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Okuyucu kâğıdı (Faz 13): lif greni ve kenarlarda çok hafif koyulaşma.
// Zamana bağlı değil: sayfa kıvrılırken anlık kopya yırtılmaz (`ReaderPaper`).
// Gren konumdan üretilir, karo tekrarı görünmez. Fikir Inferno (MIT) gölgelendiricilerinden;
// kod MagicPaper'ın.

static float mpPaperHash(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

[[ stitchable ]] half4 paperGrain(float2 position, half4 color, float2 size, float strength, float dark) {
    // Yalnızca lifin koyu tarafı: kâğıdın çoğu düz kalır.
    float fiber = smoothstep(0.82, 1.0, mpPaperHash(floor(position)));
    float2 uv = position / max(size, float2(1.0));
    float edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
    float vignette = 1.0 - smoothstep(0.0, 0.06, edge);
    float shade = fiber * strength + vignette * strength * 0.6;
    half3 rgb = dark > 0.5 ? color.rgb + half3(half(shade)) : color.rgb * half(1.0 - shade);
    return half4(rgb, color.a);
}
