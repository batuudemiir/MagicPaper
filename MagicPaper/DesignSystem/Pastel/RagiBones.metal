#include <metal_stdlib>
using namespace metal;

// Ragi'nin kuklası: tek parça çizimde baş, kuyruk ve kol ayrı oynasın diye bölgesel
// döndürme. Her kemik: `pivot` (x, y) + açı (radyan), `area` merkez (x, y) + yarıçap.
// Değerler nokta cinsinden (`MPRagi.swift`, `RagiRig`). Bölge dışına doğru ağırlık
// yumuşakça söner, gövdeyle birleşim yeri kopmaz.
static float2 applyBone(float2 p, float3 pivot, float3 area) {
    float reach = distance(p, area.xy);
    float weight = 1.0 - smoothstep(area.z * 0.45, area.z, reach);
    float angle = -pivot.z * weight;
    float2 d = p - pivot.xy;
    float s = sin(angle), c = cos(angle);
    return pivot.xy + float2(d.x * c - d.y * s, d.x * s + d.y * c);
}

[[ stitchable ]] float2 ragiBones(float2 position,
                                  float3 headPivot, float3 headArea,
                                  float3 tailPivot, float3 tailArea,
                                  float3 armPivot, float3 armArea) {
    float2 p = position;
    p = applyBone(p, tailPivot, tailArea);
    p = applyBone(p, armPivot, armArea);
    p = applyBone(p, headPivot, headArea);
    return p;
}
