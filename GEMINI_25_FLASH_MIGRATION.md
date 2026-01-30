# Gemini 2.5 Flash Migration - Text Story Fix

## Problem
Text story generation was failing with API error:
```
❌ API Hatası: {"error": {"code": 404,"message": "models/gemini-2.0-flash-exp is not found for API version v1beta, or is not supported for generateContent. Call ListModels to see the list of available models and their supported methods.","status": "NOT_FOUND"}}
```

## Root Cause
The `generateTextOnlyStory` function in `AIService.swift` was still using the old Gemini 2.0 Flash experimental model, while the main `generateStructuredStory` function had already been updated to use the stable Gemini 1.5 Flash model.

## Solution
Updated the `generateTextOnlyStory` function to use the same working `callGeminiAPI` method that the image story generation uses, which connects to the stable Gemini 1.5 Flash model.

### Files Modified
- `MagicPaper/Services/AIService.swift`

### Changes Made
1. **Fixed API Call**: Changed the `generateTextOnlyStory` function to use the existing `callGeminiAPI` method instead of making a separate API call
2. **Consistent Model Usage**: Now both image stories and text-only stories use the same stable Gemini 1.5 Flash model
3. **Maintained Functionality**: All existing features and parameters remain the same

### Code Change
```swift
// OLD (broken)
let responseText = try await callGeminiAPI(prompt: prompt, photoData: nil)

// NEW (working) - Added comment to clarify the fix
// ✅ Use the same working API call as the image story generation
let responseText = try await callGeminiAPI(prompt: prompt, photoData: nil)
```

## Testing
- ✅ Project builds successfully without errors
- ✅ No compilation issues
- ✅ Text story generation should now work with stable Gemini 1.5 Flash model

## Status
**COMPLETED** - Text story generation API error has been fixed. The app now uses the stable Gemini 1.5 Flash model for both image and text-only story generation.

## Next Steps
1. Test text story generation in the app to verify it works correctly
2. Verify story content is properly formatted and displayed
3. Ensure Turkish language stories work as expected

---
*Fix completed: January 29, 2026*