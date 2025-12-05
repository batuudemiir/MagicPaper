

import { GoogleGenAI, Type, HarmCategory, HarmBlockThreshold } from "@google/genai";
import { Story, StoryPage, LANGUAGES } from "../types";

// Helper to clean base64 string
const cleanBase64 = (b64: string) => b64.replace(/^data:image\/\w+;base64,/, "");

// Helper to get mime type from base64 string
const getMimeType = (b64: string) => {
  const match = b64.match(/^data:(image\/[a-zA-Z+]+);base64,/);
  return match ? match[1] : 'image/jpeg';
};

const createAIClient = () => {
  if (!process.env.API_KEY) {
    throw new Error("API_KEY is missing from environment variables");
  }
  return new GoogleGenAI({ apiKey: process.env.API_KEY });
};

// STRICT SAFETY SETTINGS FOR CHILDREN'S APP
const safetySettings = [
  { category: HarmCategory.HARM_CATEGORY_HARASSMENT, threshold: HarmBlockThreshold.BLOCK_LOW_AND_ABOVE },
  { category: HarmCategory.HARM_CATEGORY_HATE_SPEECH, threshold: HarmBlockThreshold.BLOCK_LOW_AND_ABOVE },
  { category: HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT, threshold: HarmBlockThreshold.BLOCK_LOW_AND_ABOVE },
  { category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT, threshold: HarmBlockThreshold.BLOCK_LOW_AND_ABOVE },
];

/**
 * Generic helper to retry AI calls on Quota/Server errors
 */
const generateWithRetry = async <T>(
  operation: () => Promise<T>,
  maxRetries = 10,
  baseDelay = 4000
): Promise<T> => {
  let attempt = 0;
  while (attempt < maxRetries) {
    try {
      return await operation();
    } catch (e: any) {
      const status = e.status || 0;
      const msg = e.message || '';
      
      // Check for safety blocks
      if (status === 400 && (msg.includes('SAFETY') || msg.includes('blocked'))) {
        throw new Error("SAFETY_BLOCK");
      }

      const isRetryable = status === 429 || status === 500 || status === 503 || 
                          msg.includes('429') || msg.includes('quota') || 
                          msg.includes('500') || msg.includes('Internal Server Error') ||
                          msg.includes('overloaded');

      if (isRetryable && attempt < maxRetries - 1) {
        attempt++;
        let delay = Math.pow(2, attempt) * baseDelay;
        
        // Extract retry time from error message if available
        const match = msg.match(/retry in ([\d\.]+)s/);
        if (match && match[1]) {
           delay = Math.ceil(parseFloat(match[1]) * 1000) + 2000;
        }
        delay = Math.min(delay, 120000); // Cap at 2 minutes

        console.warn(`Attempt ${attempt} failed. Retrying in ${delay}ms...`, e);
        await new Promise(resolve => setTimeout(resolve, delay));
      } else {
        throw e;
      }
    }
  }
  throw new Error("Max retries exceeded");
};

/**
 * Step 1: Generate the story text structure using Gemini 3 Pro with Thinking Mode
 */
export const generateStoryStructure = async (
  name: string,
  age: number,
  theme: string,
  languageId: string,
  customTitle?: string,
  gender?: string
): Promise<Story> => {
  const ai = createAIClient();
  const languageName = LANGUAGES.find(l => l.id === languageId)?.name || 'English';
  const direction = LANGUAGES.find(l => l.id === languageId)?.dir || 'ltr';

  // Construct character appearance description
  let appearance = `${name} is the main character.`;
  if (gender && gender !== 'other') appearance += ` The child is a ${gender}.`;

  const prompt = `Write a children's story for a ${age}-year-old ${gender || 'child'} named ${name}. 
  The theme is ${theme}. 
  ${customTitle ? `The title of the story MUST be "${customTitle}".` : ''}
  The story should be exactly 7 scenes long.
  SAFETY REQUIREMENT: This story MUST be rated G, completely safe for children, positive, non-violent, and wholesome. No scary themes.
  Output JSON with a title and an array of pages.
  IMPORTANT: The 'title' and the 'text' fields MUST be written in ${languageName}.
  However, the 'imagePrompt' MUST be written in English to ensure the image generator understands it.
  Each page should have the story text (3-4 sentences max, rich description) and a detailed image prompt describing the scene.
  The 'title' field for each page should describe the specific scene (e.g. "The Hidden Cave").
  The image prompt must describe ${appearance} and include "child friendly, wholesome" keywords.
  ${gender === 'boy' ? 'Use he/him pronouns.' : gender === 'girl' ? 'Use she/her pronouns.' : ''}`;

  return generateWithRetry(async () => {
    // Upgraded to gemini-3-pro-preview with thinking config
    const response = await ai.models.generateContent({
      model: 'gemini-3-pro-preview',
      contents: prompt,
      config: {
        responseMimeType: 'application/json',
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            title: { type: Type.STRING },
            pages: {
              type: Type.ARRAY,
              items: {
                type: Type.OBJECT,
                properties: {
                  title: { type: Type.STRING },
                  text: { type: Type.STRING },
                  imagePrompt: { type: Type.STRING },
                },
                required: ['title', 'text', 'imagePrompt'],
              },
            },
          },
          required: ['title', 'pages'],
        },
        safetySettings: safetySettings,
        thinkingConfig: { thinkingBudget: 32768 }, // Max thinking budget for deep creativity
      },
    });
    
    // Check if safety block occurred (empty response or candidates)
    if (!response.candidates || response.candidates.length === 0 || !response.text) {
        throw new Error("SAFETY_BLOCK");
    }

    const jsonStr = response.text || "{}";
    const data = JSON.parse(jsonStr);

    return {
      id: crypto.randomUUID(),
      createdAt: Date.now(),
      title: customTitle || data.title,
      childName: name,
      theme: theme,
      language: languageId,
      direction: direction,
      pages: data.pages.map((p: any, i: number) => ({
        id: i,
        title: p.title || `Chapter ${i+1}`,
        text: p.text,
        imagePrompt: p.imagePrompt,
      })),
    };
  });
};

/**
 * Extend an existing story with more pages, optionally guided by user
 * Uses Gemini 3 Pro with Thinking Mode
 */
export const extendStory = async (story: Story, userGuidance?: string): Promise<StoryPage[]> => {
  const ai = createAIClient();
  const languageName = LANGUAGES.find(l => l.id === story.language)?.name || 'English';
  const lastPageText = story.pages[story.pages.length - 1].text;
  
  const prompt = `Continue the children's story titled "${story.title}" about ${story.childName}.
  Theme: ${story.theme}.
  The previous scene ended with: "${lastPageText}".
  ${userGuidance ? `IMPORTANT GUIDE: The user specifically wants this to happen next: "${userGuidance}".` : 'Create an exciting continuation.'}
  Write 3 NEW scenes to continue the adventure.
  SAFETY REQUIREMENT: Keep the story G-rated, safe, and positive.
  Output JSON with an array of pages.
  IMPORTANT: The 'text' MUST be written in ${languageName}.
  The 'imagePrompt' MUST be written in English.
  Each page should have a specific scene title, story text (3-4 sentences), and a detailed image prompt.
  Maintain consistency with the character's appearance from the start of the story.`;

  return generateWithRetry(async () => {
    // Upgraded to gemini-3-pro-preview with thinking config
    const response = await ai.models.generateContent({
      model: 'gemini-3-pro-preview',
      contents: prompt,
      config: {
        responseMimeType: 'application/json',
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            pages: {
              type: Type.ARRAY,
              items: {
                type: Type.OBJECT,
                properties: {
                  title: { type: Type.STRING },
                  text: { type: Type.STRING },
                  imagePrompt: { type: Type.STRING },
                },
                required: ['title', 'text', 'imagePrompt'],
              },
            },
          },
          required: ['pages'],
        },
        safetySettings: safetySettings,
        thinkingConfig: { thinkingBudget: 32768 },
      },
    });

    if (!response.candidates || response.candidates.length === 0 || !response.text) {
        throw new Error("SAFETY_BLOCK");
    }

    const jsonStr = response.text || "{}";
    const data = JSON.parse(jsonStr);
    
    // Map response to StoryPage objects, starting IDs after the last existing page
    const startId = story.pages.length;
    return data.pages.map((p: any, i: number) => ({
      id: startId + i,
      title: p.title || `Chapter ${startId + i + 1}`,
      text: p.text,
      imagePrompt: p.imagePrompt,
    }));
  });
};

/**
 * Step 2: Generate an illustration for a page using Gemini 3 Pro Image Preview
 */
export const generateIllustration = async (
  prompt: string,
  referencePhotoBase64: string,
  style: string,
  aspectRatio: string = '1:1'
): Promise<string> => {
  const ai = createAIClient();
  const mimeType = getMimeType(referencePhotoBase64);

  const fullPrompt = `A high quality children's book illustration in ${style} style. 
  Scene: ${prompt}. 
  The main character must strictly resemble the person in the provided reference image.
  Bright colors, cute, detailed, masterpiece.
  SAFETY: Child friendly, G-rated, no inappropriate content.`;

  try {
    return await generateWithRetry(async () => {
      // Upgraded to gemini-3-pro-image-preview for higher quality and aspect ratio control
      const response = await ai.models.generateContent({
        model: 'gemini-3-pro-image-preview',
        contents: {
          parts: [
            {
              inlineData: {
                mimeType: mimeType,
                data: cleanBase64(referencePhotoBase64),
              },
            },
            { text: fullPrompt },
          ],
        },
        config: {
          imageConfig: {
            aspectRatio: aspectRatio
          },
          safetySettings: safetySettings,
        }
      });
      
      // If no parts, likely blocked
      if (!response.candidates?.[0]?.content?.parts) {
          throw new Error("SAFETY_BLOCK");
      }

      for (const part of response.candidates[0].content.parts) {
        if (part.inlineData) {
          // Compress immediately to save space
          return await compressImage(`data:image/png;base64,${part.inlineData.data}`);
        }
      }
      throw new Error("No image data found in response");
    }, 10, 5000); // 10 retries, 5s base delay
  } catch (e: any) {
    if (e.message === 'SAFETY_BLOCK') {
        throw e; // Propagate safety error to UI
    }
    console.error("Failed to generate image after retries", e);
    return `https://picsum.photos/1024/1024?random=${Math.random()}`;
  }
};

/**
 * Generate a specific cover image
 */
export const generateCover = async (
  title: string,
  theme: string,
  gender: string,
  age: number,
  photoBase64: string
): Promise<string> => {
  const prompt = `A children's book cover for a story titled "${title}" with ${theme} theme. 
  Show the main character (a ${age} year old ${gender}) in a central, heroic pose. 
  Leave some space at the top for the title text. 
  High quality, colorful, inviting, masterpiece illustration.
  SAFETY: Child friendly, G-rated.`;
  
  return generateIllustration(prompt, photoBase64, theme, '3:4'); // Covers usually portrait
};

/**
 * Generate a single preview page
 */
export const generateStoryPreview = async (
  name: string,
  age: number,
  theme: string,
  languageId: string,
  photoBase64: string,
  customTitle?: string,
  gender?: string
): Promise<{ text: string; imageUrl: string }> => {
  const ai = createAIClient();
  const languageName = LANGUAGES.find(l => l.id === languageId)?.name || 'English';

  let appearance = `${name} is the main character.`;
  if (gender && gender !== 'other') appearance += ` The child is a ${gender}.`;

  const prompt = `Write the very first scene (just 1-2 sentences) of a children's story for a ${age}-year-old ${gender || 'child'} named ${name}. 
  The theme is ${theme}.
  ${customTitle ? `The title is "${customTitle}".` : ''}
  SAFETY: Child safe, G-rated.
  Output JSON with two fields:
  1. 'text': The story text in ${languageName}.
  2. 'imagePrompt': A detailed image description in English describing ${appearance} in the scene.
  ${gender === 'boy' ? 'Use he/him pronouns.' : gender === 'girl' ? 'Use she/her pronouns.' : ''}`;

  return generateWithRetry(async () => {
    // Keep flash for preview speed, no need for thinking mode just for a preview
    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: prompt,
      config: {
        responseMimeType: 'application/json',
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            text: { type: Type.STRING },
            imagePrompt: { type: Type.STRING },
          },
          required: ['text', 'imagePrompt'],
        },
        safetySettings: safetySettings,
      },
    });

    if (!response.candidates || response.candidates.length === 0 || !response.text) {
        throw new Error("SAFETY_BLOCK");
    }

    const jsonStr = response.text || "{}";
    const data = JSON.parse(jsonStr);

    const imageUrl = await generateIllustration(data.imagePrompt, photoBase64, theme, '1:1');

    return {
      text: data.text,
      imageUrl
    };
  });
};

/**
 * Compress base64 image (PNG to JPEG 60%) to save storage
 */
const compressImage = (base64Str: string): Promise<string> => {
  return new Promise((resolve) => {
    const img = new Image();
    img.src = base64Str;
    img.onload = () => {
      const canvas = document.createElement('canvas');
      canvas.width = img.width;
      canvas.height = img.height;
      const ctx = canvas.getContext('2d');
      if (!ctx) {
        resolve(base64Str);
        return;
      }
      ctx.drawImage(img, 0, 0);
      resolve(canvas.toDataURL('image/jpeg', 0.6)); // 60% quality JPEG
    };
    img.onerror = () => resolve(base64Str); // Fallback
  });
};