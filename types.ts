

export interface StoryPage {
  id: number;
  text: string;
  imagePrompt: string;
  imageUrl?: string; // Base64 or URL
  title?: string;
}

export interface Story {
  id: string; // Unique ID for storage
  createdAt: number;
  title: string;
  childName: string;
  theme: string;
  language: string; // The language of the generated story
  direction: 'ltr' | 'rtl';
  pages: StoryPage[];
  coverImage?: string; // Thumbnail
  lastReadPage?: number;
}

export interface StoryParams {
  name: string;
  age: number;
  gender: string;
  theme: string;
  photoBase64: string;
  language: string;
  customTitle?: string;
  coverImage?: string;
  aspectRatio: string;
}

export enum AppStatus {
  IDLE = 'IDLE',
  GENERATING_TEXT = 'GENERATING_TEXT',
  GENERATING_IMAGES = 'GENERATING_IMAGES',
  EXTENDING = 'EXTENDING',
  COMPLETE = 'COMPLETE',
  ERROR = 'ERROR'
}

export type Tab = 'landing' | 'create' | 'library' | 'settings' | 'admin';

export interface UIStringMap {
  landing: string;
  create: string;
  library: string;
  settings: string;
  
  // Landing Page
  heroTitle: string;
  heroSubtitle: string;
  startJourney: string;
  howItWorks: string;
  step1Title: string;
  step1Desc: string;
  step2Title: string;
  step2Desc: string;
  step3Title: string;
  step3Desc: string;
  featuredStories: string;
  readNow: string;

  // Example Stories
  ex1_title: string;
  ex1_childName: string;
  ex1_p0: string;
  ex1_p1: string;
  ex1_p2: string;
  ex2_title: string;
  ex2_childName: string;
  ex2_p0: string;
  ex2_p1: string;
  ex2_p2: string;

  createTitle: string;
  createSubtitle: string;
  uploadPhoto: string;
  childName: string;
  age: string;
  storyTitle: string;
  storyTitlePlaceholder: string;
  selectLanguage: string;
  selectTheme: string;
  generateButton: string;
  generating: string;
  noStories: string;
  startCreating: string;
  appLanguage: string;
  delete: string;
  download: string;
  back: string;
  next: string;
  previewButton: string;
  previewTitle: string;
  closePreview: string;
  continueStory: string;
  extending: string;
  downloadingPdf: string;
  whatHappensNext: string;
  customPlotPlaceholder: string;
  generateExtension: string;
  cancel: string;
  chapter: string;
  
  // Cover
  storyCover: string;
  generateCover: string;
  uploadCover: string;
  coverGenerated: string;
  creating: string;
  
  // Settings items
  premiumTitle: string;
  premiumDesc: string;
  upgradeNow: string;
  premiumActive: string;
  createStoryAction: string;
  myStoriesAction: string;
  aboutUs: string;
  privacyPolicy: string;
  termsOfService: string;
  restorePurchases: string;
  contactSupport: string;
  legal: string;
  support: string;
  preferences: string;
  quickActions: string;
  
  // Premium Modal
  premiumModalTitle: string;
  unlockUnlimited: string;
  benefit1: string;
  benefit2: string;
  benefit3: string;
  subscribeBtn: string;
  processing: string;
  restore: string;

  // Info Content
  aboutUsContent: string;
  privacyContent: string;
  termsContent: string;
  supportContent: string;
  restoreContent: string;

  // Success
  storyReady: string;
  addedToLibrary: string;

  // Admin
  adminPanel: string;
  totalStories: string;
  totalPages: string;
  avgPagesPerStory: string;
  topThemes: string;
  storageUsed: string;
  resetApp: string;
  recentStories: string;

  // Themes
  themeName_fantasy: string;
  themeDesc_fantasy: string;
  themeName_space: string;
  themeDesc_space: string;
  themeName_jungle: string;
  themeDesc_jungle: string;
  themeName_hero: string;
  themeDesc_hero: string;
  themeName_underwater: string;
  themeDesc_underwater: string;

  // Character Options
  selectGender: string;
  gender_boy: string;
  gender_girl: string;
  gender_other: string;

  // Image Options
  selectAspectRatio: string;

  // Alerts & Progress
  alert_freeLimit: string;
  alert_errorGenerating: string;
  alert_storageFull: string;
  alert_confirmDelete: string;
  alert_uploadPhoto: string;
  alert_coverError: string;
  alert_previewError: string;
  alert_contentSafety: string;
  progress_painting: string;
}

export const THEMES = [
  { 
    id: 'fantasy', 
    name: 'Magical Kingdom', 
    emoji: '🏰', 
    color: 'from-purple-400 to-pink-500', 
    pageColor: 'bg-fuchsia-50',
    textColor: 'text-fuchsia-950',
    accentColor: 'bg-fuchsia-600 hover:bg-fuchsia-700',
    borderColor: 'border-fuchsia-200'
  },
  { 
    id: 'space', 
    name: 'Space Explorer', 
    emoji: '🚀', 
    color: 'from-blue-400 to-indigo-600', 
    pageColor: 'bg-slate-50',
    textColor: 'text-slate-900',
    accentColor: 'bg-indigo-600 hover:bg-indigo-700',
    borderColor: 'border-indigo-200'
  },
  { 
    id: 'jungle', 
    name: 'Jungle Adventure', 
    emoji: '🦁', 
    color: 'from-green-400 to-emerald-600', 
    pageColor: 'bg-green-50',
    textColor: 'text-green-950',
    accentColor: 'bg-emerald-600 hover:bg-emerald-700',
    borderColor: 'border-green-200'
  },
  { 
    id: 'hero', 
    name: 'Super Hero', 
    emoji: '⚡', 
    color: 'from-red-400 to-yellow-500', 
    pageColor: 'bg-amber-50',
    textColor: 'text-amber-950',
    accentColor: 'bg-red-600 hover:bg-red-700',
    borderColor: 'border-amber-200'
  },
  { 
    id: 'underwater', 
    name: 'Ocean Secrets', 
    emoji: '🐬', 
    color: 'from-cyan-400 to-blue-500', 
    pageColor: 'bg-cyan-50',
    textColor: 'text-cyan-950',
    accentColor: 'bg-cyan-600 hover:bg-cyan-700',
    borderColor: 'border-cyan-200'
  },
];

export const LANGUAGES = [
  { 
    id: 'en', name: 'English', flag: '🇬🇧', dir: 'ltr',
    font: 'font-lora', size: 'text-xl md:text-2xl', tracking: 'tracking-wide', lineHeight: 'leading-loose', pdfSize: 'text-4xl'
  },
  { 
    id: 'es', name: 'Spanish', flag: '🇪🇸', dir: 'ltr',
    font: 'font-lora', size: 'text-xl md:text-2xl', tracking: 'tracking-wide', lineHeight: 'leading-loose', pdfSize: 'text-4xl'
  },
  { 
    id: 'fr', name: 'French', flag: '🇫🇷', dir: 'ltr',
    font: 'font-lora', size: 'text-xl md:text-2xl', tracking: 'tracking-wide', lineHeight: 'leading-loose', pdfSize: 'text-4xl'
  },
  { 
    id: 'de', name: 'German', flag: '🇩🇪', dir: 'ltr',
    font: 'font-lora', size: 'text-xl md:text-2xl', tracking: 'tracking-wide', lineHeight: 'leading-loose', pdfSize: 'text-4xl'
  },
  { 
    id: 'it', name: 'Italian', flag: '🇮🇹', dir: 'ltr',
    font: 'font-lora', size: 'text-xl md:text-2xl', tracking: 'tracking-wide', lineHeight: 'leading-loose', pdfSize: 'text-4xl'
  },
  { 
    id: 'tr', name: 'Turkish', flag: '🇹🇷', dir: 'ltr',
    font: 'font-lora', size: 'text-xl md:text-2xl', tracking: 'tracking-wide', lineHeight: 'leading-loose', pdfSize: 'text-4xl'
  },
  { 
    id: 'ru', name: 'Russian', flag: '🇷🇺', dir: 'ltr',
    font: 'font-lora', size: 'text-xl md:text-2xl', tracking: 'tracking-wide', lineHeight: 'leading-loose', pdfSize: 'text-4xl'
  },
  { 
    id: 'ar', name: 'Arabic', flag: '🇸🇦', dir: 'rtl',
    font: 'font-arabic', size: 'text-2xl md:text-3xl', tracking: 'tracking-normal', lineHeight: 'leading-[2.5]', pdfSize: 'text-5xl'
  },
  { 
    id: 'fa', name: 'Persian', flag: '🇮🇷', dir: 'rtl',
    font: 'font-arabic', size: 'text-2xl md:text-3xl', tracking: 'tracking-normal', lineHeight: 'leading-[2.5]', pdfSize: 'text-5xl'
  },
] as const;

export const ASPECT_RATIOS = [
  { id: '1:1', label: 'Square (1:1)' },
  { id: '3:4', label: 'Portrait (3:4)' },
  { id: '4:3', label: 'Landscape (4:3)' },
  { id: '9:16', label: 'Mobile (9:16)' },
  { id: '16:9', label: 'Cinematic (16:9)' },
] as const;