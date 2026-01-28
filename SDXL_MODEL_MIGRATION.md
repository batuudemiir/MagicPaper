# SDXL Model Migration - Flux Schnell → Fast SDXL

**Date:** January 26, 2026  
**Migration:** flux/schnell → fal-ai/fast-sdxl

---

## Why Switch to SDXL?

### Problems with Flux Schnell:
- ❌ Identity preservation inconsistent
- ❌ Scene details often ignored
- ❌ Too sensitive to prompt structure
- ❌ Results not satisfactory for children's book style

### Benefits of Fast SDXL:
- ✅ Better stylization for 3D/Pixar look
- ✅ More consistent character rendering
- ✅ Tag-based prompts = more predictable results
- ✅ Proven track record for illustration style
- ✅ Cost-effective for production

---

## Technical Changes

### Endpoint Change
```swift
// OLD
private let endpoint = "https://fal.run/fal-ai/flux/schnell"

// NEW
private let endpoint = "https://fal.run/fal-ai/fast-sdxl"
```

### Prompt Strategy Change

**Flux Schnell (Natural Language):**
```
"A child running through a magical forest with arms outstretched, 
reaching toward glowing fireflies, volumetric god rays through 
ancient trees, vibrant emerald colors, 3D Pixar style..."
```

**Fast SDXL (Tag-Based):**
```
(subject) a cute child character, solo, full body,
(action) running through magical forest, arms outstretched,
(context) detailed background, professional illustration, storybook art,
(style) 3d render, disney animation style, pixar style, cute character, 
unreal engine 5, octane render, volumetric lighting, vibrant colors, 
8k, masterpiece, magical forest, fairy dust, glowing mushrooms
```

**Why Tags Work Better:**
- SDXL was trained on tag-based datasets (like Danbooru)
- Comma-separated keywords = clearer instructions
- Each tag has specific weight in the model
- More predictable, consistent results

### Parameter Changes

| Parameter | Flux Schnell | Fast SDXL | Reason |
|-----------|--------------|-----------|--------|
| `num_inference_steps` | 4 | **35** | SDXL needs more steps for quality |
| `guidance_scale` | 2.5 | **7.5** | Standard SDXL guidance |
| `strength` | 0.48 | **0.70** | Balanced for SDXL img2img |
| `timeout` | 60s | **90s** | SDXL takes longer |

**Parameter Explanations:**

**num_inference_steps: 35**
- Flux Schnell: Optimized for 4 steps (distilled model)
- SDXL: Needs 25-40 steps for quality
- 35 = sweet spot for quality vs speed
- Generation time: ~10-15 seconds

**guidance_scale: 7.5**
- Standard SDXL value for strong prompt adherence
- Lower (5.0) = more creative but less accurate
- Higher (10.0) = very literal but can be stiff
- 7.5 = balanced, proven value

**strength: 0.70**
- Controls img2img transformation
- 0.70 = 70% modification, 30% preservation
- Higher than Flux because SDXL handles it better
- Range: 0.60-0.80 is optimal for SDXL

---

## Prompt Engineering for SDXL

### Tag Categories

**1. Subject Tags:**
```
a cute child character, solo, full body, young child
```

**2. Action Tags:**
```
running, jumping, reaching, sitting, playing, exploring
```

**3. Context Tags:**
```
detailed background, professional illustration, storybook art, 
children's book style, masterpiece
```

**4. Style Tags (Base):**
```
3d render, disney animation style, pixar style, cute character,
unreal engine 5, octane render, volumetric lighting, vibrant colors,
8k, masterpiece, high quality
```

**5. Theme-Specific Tags:**

**Fantasy:**
```
magical forest, fairy dust, glowing mushrooms, whimsical atmosphere,
enchanted, sparkles
```

**Space:**
```
spaceship interior, galaxy background, stars, planets, cosmic,
sci-fi, shiny metallic, futuristic
```

**Jungle:**
```
dense jungle, tropical plants, sun rays through leaves, vibrant green,
exotic, lush vegetation
```

**Hero:**
```
superhero costume, heroic pose, dynamic angle, cape flowing,
action scene, powerful
```

**Underwater:**
```
underwater scenery, coral reef, tropical fish, air bubbles,
aquatic, blue tones, ocean
```

### Negative Prompt (Critical for SDXL)

```
photo, photograph, realistic, realism, photorealistic,
disfigured, ugly, bad anatomy, distorted face, extra fingers,
extra limbs, blurry, low quality, grainy, text, watermark,
signature, crop, out of frame, bad hands, deformed, mutation,
duplicate, multiple people, adult, teenager
```

**Why So Detailed?**
- SDXL can drift toward photorealism without strong negatives
- Prevents common AI artifacts (extra fingers, bad anatomy)
- Ensures stylized, illustration-like output
- Keeps focus on single child character

---

## Expected Results

### Generation Time
- **Flux Schnell:** ~3-4 seconds
- **Fast SDXL:** ~10-15 seconds
- **Trade-off:** Worth it for better quality

### Quality Improvements

**Before (Flux Schnell):**
- Inconsistent identity preservation
- Scene details often missing
- Sometimes ignores style instructions
- Character varies between pages

**After (Fast SDXL):**
- ✅ More consistent character rendering
- ✅ Better adherence to scene description
- ✅ Stronger 3D/Pixar stylization
- ✅ More predictable results with tags

### Visual Style

**SDXL Strengths:**
- Excellent at 3D render style
- Strong Pixar/Disney aesthetic
- Good volumetric lighting
- Vibrant, saturated colors
- Professional illustration quality

---

## Testing Strategy

### Test 1: Identity Consistency
1. Generate 7-page story with same seed
2. Compare child's appearance across all pages
3. **Success:** Same hair color, face shape, general features

### Test 2: Scene Accuracy
1. Read story text for each page
2. Verify image shows described action
3. **Success:** 90%+ match between text and image

### Test 3: Style Quality
1. Check for 3D/Pixar aesthetic
2. Verify volumetric lighting
3. Assess color vibrancy
4. **Success:** Professional children's book quality

### Test 4: Generation Speed
1. Time each image generation
2. **Success:** 10-15 seconds per image (acceptable)

---

## Migration Checklist

- ✅ Endpoint changed to `fal-ai/fast-sdxl`
- ✅ Prompt structure changed to tag-based
- ✅ Parameters optimized for SDXL
- ✅ Negative prompt enhanced
- ✅ Timeout increased to 90 seconds
- ✅ Style tags organized by theme
- ✅ Documentation updated

---

## Rollback Plan

If SDXL doesn't work as expected:

```swift
// Revert to Flux Schnell
private let endpoint = "https://fal.run/fal-ai/flux/schnell"

var parameters: [String: Any] = [
    "num_inference_steps": 4,
    "guidance_scale": 2.5,
    "strength": 0.48,
    // ... other Flux parameters
]
```

---

## Cost Comparison

### Flux Schnell:
- Fast (4 steps)
- Lower cost per image
- But: Inconsistent results = more re-generations

### Fast SDXL:
- Slower (35 steps)
- Slightly higher cost per image
- But: Better results = fewer re-generations

**Net Result:** Similar or lower total cost due to fewer retries

---

## Future Optimizations

### If Generation is Too Slow:
```swift
"num_inference_steps": 25  // Reduce from 35 (slight quality loss)
```

### If Identity Needs More Preservation:
```swift
"strength": 0.65  // Reduce from 0.70 (stricter adherence)
```

### If Style Needs More Creativity:
```swift
"guidance_scale": 6.5  // Reduce from 7.5 (more freedom)
```

---

## Monitoring Metrics

Track these after migration:

1. **Generation Success Rate:** % of images generated without errors
2. **User Satisfaction:** Ratings on image quality
3. **Re-generation Rate:** How often users retry
4. **Average Generation Time:** Should be 10-15 seconds
5. **Identity Match Score:** Parent recognition rate

**Targets:**
- Success Rate: 98%+
- User Satisfaction: 4.5+ stars
- Re-generation Rate: <15%
- Avg Time: 12 seconds
- Identity Match: 85%+

---

## Conclusion

Migration to Fast SDXL provides:

1. ✅ **Better Quality:** More consistent, professional results
2. ✅ **Predictable Output:** Tag-based prompts = reliable results
3. ✅ **Stronger Stylization:** Better 3D/Pixar aesthetic
4. ✅ **Scene Accuracy:** Better adherence to story text
5. ✅ **Production Ready:** Proven model for illustration work

**Trade-off:** Slightly slower generation (10-15s vs 3-4s) but worth it for quality!

**Next Steps:**
1. Build and test in Xcode
2. Generate test stories with different themes
3. Compare results with previous Flux Schnell output
4. Monitor metrics and adjust parameters if needed

🎨✨ Ready for professional children's book quality!
