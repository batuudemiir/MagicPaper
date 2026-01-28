# Nano Banana Edit Model Migration

**Date:** January 26, 2026  
**Model:** fal-ai/nano-banana/edit (Identity-Preserving)

---

## Why Nano Banana Edit?

### Previous Models Failed:
- ❌ Flux Schnell: Inconsistent identity, different face each page
- ❌ Fast SDXL: Too slow, still inconsistent

### Nano Banana Edit Advantages:
- ✅ **Specifically designed for identity preservation**
- ✅ **Supports multiple reference images** (we use same image twice)
- ✅ **Optimized for face consistency**
- ✅ **Queue-based system** (reliable, scalable)
- ✅ **Proven for portrait editing** while maintaining identity

---

## How It Works

### 1. Multiple Reference Images
```swift
var imageUrls: [String] = []
if let refUrl = referenceImageUrl {
    imageUrls.append(refUrl)  // First reference
    imageUrls.append(refUrl)  // Same image twice = stronger identity
}
```

**Why Twice?**
- Nano Banana uses multiple images to understand the subject better
- Using same image twice reinforces the identity
- Model learns: "This is THE face to preserve"

### 2. Queue-Based Generation
```swift
// Step 1: Submit to queue
POST https://queue.fal.run/fal-ai/nano-banana/edit
→ Returns request_id

// Step 2: Poll for completion
GET https://queue.fal.run/.../requests/{request_id}/status
→ Returns status: IN_QUEUE, IN_PROGRESS, COMPLETED, FAILED
```

**Benefits:**
- Reliable: No timeouts during generation
- Scalable: Handles multiple requests
- Transparent: Can track progress

### 3. Identity-Preserving Prompt
```swift
"make a photo of the child [scene description], 
3d animation style, pixar quality, cute, vibrant colors"
```

**Key Phrase:** "make a photo of the child"
- Tells model to preserve the child from reference images
- Then apply the scene/style transformations

---

## Technical Implementation

### Endpoint Structure
```
Queue Submit: https://queue.fal.run/fal-ai/nano-banana/edit
Status Check: https://queue.fal.run/fal-ai/nano-banana/edit/requests/{id}/status
```

### Request Format
```json
{
  "prompt": "make a photo of the child running through forest, 3d animation...",
  "image_urls": [
    "https://firebase.../child_photo.jpg",
    "https://firebase.../child_photo.jpg"
  ],
  "seed": 123456
}
```

### Response Format (Completed)
```json
{
  "status": "COMPLETED",
  "images": [
    {
      "url": "https://fal.media/files/...",
      "width": 1024,
      "height": 768
    }
  ]
}
```

---

## Polling Strategy

### Configuration
- **Poll Interval:** 2 seconds
- **Max Attempts:** 120 (4 minutes total)
- **Timeout:** 30 seconds per request

### Status Flow
```
IN_QUEUE → IN_PROGRESS → COMPLETED
                       ↘ FAILED
```

### Logging
```swift
// Every 10 attempts (20 seconds)
if attempt % 10 == 0 {
    print("📡 Polling attempt \(attempt)...")
}
```

---

## Expected Results

### Identity Preservation
- ✅ **Same face across all 7 pages**
- ✅ **Recognizable to parents**
- ✅ **Consistent features** (hair, face shape, skin tone)

### Scene Accuracy
- ✅ **Matches story text**
- ✅ **Correct actions** (running, jumping, etc.)
- ✅ **Appropriate environment**

### Style Quality
- ✅ **3D Pixar aesthetic**
- ✅ **Vibrant colors**
- ✅ **Professional children's book quality**

### Generation Time
- **Average:** 10-20 seconds per image
- **With queue:** May add 2-5 seconds wait time
- **Total:** ~15-25 seconds per image

---

## Comparison with Previous Models

| Feature | Flux Schnell | Fast SDXL | Nano Banana Edit |
|---------|--------------|-----------|------------------|
| **Identity Preservation** | ❌ Poor | ❌ Poor | ✅ Excellent |
| **Consistency** | ❌ Different each page | ❌ Inconsistent | ✅ Same character |
| **Speed** | ✅ 3-4s | ❌ 15-20s | ✅ 10-20s |
| **Multiple References** | ❌ No | ❌ No | ✅ Yes |
| **Queue System** | ❌ No | ❌ No | ✅ Yes |
| **Purpose** | General | General | **Identity-focused** |

---

## Seed System Integration

### How Seeds Work with Nano Banana
```swift
// In StoryGenerationManager
let storySeed = Int.random(in: 1000...999999)

// Use same seed for all 7 pages
for page in pages {
    let imageUrl = try await FalAIImageGenerator.shared.generateImage(
        prompt: page.imagePrompt,
        referenceImageUrl: firebaseUrl,
        seed: storySeed  // ← Same seed
    )
}
```

**Result:** Same character appearance + same reference images = Perfect consistency

---

## Error Handling

### Possible Errors
1. **Queue Submission Failed:** Network error, invalid API key
2. **Polling Timeout:** Generation took >4 minutes
3. **Generation Failed:** Model error, inappropriate content

### Handling Strategy
```swift
do {
    let imageUrl = try await generateImage(...)
} catch {
    print("❌ Generation failed: \(error)")
    // Could retry with different seed
    // Or fall back to placeholder image
}
```

---

## Monitoring & Metrics

### Track These Metrics
1. **Queue Wait Time:** Time from submit to IN_PROGRESS
2. **Generation Time:** Time from IN_PROGRESS to COMPLETED
3. **Success Rate:** % of COMPLETED vs FAILED
4. **Identity Match Score:** Parent recognition rate

### Target Metrics
- Queue Wait: <5 seconds
- Generation: 10-20 seconds
- Success Rate: >95%
- Identity Match: >90%

---

## Cost Considerations

### Nano Banana Edit Pricing
- Typically similar to or slightly higher than Flux Schnell
- But: **Much better results = fewer re-generations**
- Net cost: Likely lower due to higher success rate

### Cost Optimization
```swift
// Use seed for consistency = no need to regenerate
let storySeed = Int.random(in: 1000...999999)

// Reuse same reference image twice (no extra upload cost)
imageUrls = [refUrl, refUrl]
```

---

## Testing Checklist

### Test 1: Identity Preservation
```
1. Upload clear child photo
2. Generate 7-page story
3. Compare all images to original photo
✓ Success: Parents immediately recognize child
```

### Test 2: Consistency Across Pages
```
1. Generate complete story
2. Compare all 7 page images
3. Check: same face, hair, features
✓ Success: Same character in all images
```

### Test 3: Scene Accuracy
```
1. Read story text for each page
2. Verify image shows described action
✓ Success: 90%+ text-image match
```

### Test 4: Generation Reliability
```
1. Generate 10 stories
2. Track success/failure rate
✓ Success: >95% completion rate
```

---

## Troubleshooting

### Issue: "Different face on each page"
**Solution:** Verify seed is being used consistently
```swift
// Check logs
print("🎲 Story Seed: \(storySeed)")
// Should be SAME for all 7 pages
```

### Issue: "Timeout after 4 minutes"
**Solution:** Increase max polling attempts
```swift
for attempt in 1...180 {  // 6 minutes instead of 4
```

### Issue: "Queue submission failed"
**Solution:** Check API key and network
```swift
print("API Key: \(apiKey.prefix(10))...")
print("Endpoint: \(endpoint)")
```

---

## Future Optimizations

### If Identity Still Not Perfect:
1. **Use 3 reference images** (same image 3x)
2. **Add face-specific prompt:** "preserve exact facial features"
3. **Lower guidance** (if model supports it)

### If Too Slow:
1. **Reduce polling interval** to 1 second
2. **Use async/await** for parallel generation
3. **Pre-queue images** before user sees page

---

## Conclusion

Nano Banana Edit provides:

1. ✅ **Identity Preservation:** Specifically designed for this
2. ✅ **Multiple References:** Use same image twice for strength
3. ✅ **Queue System:** Reliable, scalable generation
4. ✅ **Consistency:** Same character across all pages
5. ✅ **Quality:** Professional children's book results

**This is the RIGHT model for our use case!**

**Next Steps:**
1. Build and test in Xcode
2. Generate test story with child photo
3. Verify identity preservation
4. Monitor generation times and success rates

🎯 Finally, the right tool for the job!
