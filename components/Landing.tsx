import React from 'react';
import { Story, THEMES, UIStringMap, LANGUAGES } from '../types';

interface LandingProps {
  onStartCreate: () => void;
  onOpenStory: (story: Story) => void;
  t: UIStringMap;
  currentLang: string;
}

const Landing: React.FC<LandingProps> = ({ onStartCreate, onOpenStory, t, currentLang }) => {
  
  // Use explicit currentLang prop to determine direction and language ID
  const langDir = LANGUAGES.find(l => l.id === currentLang)?.dir || 'ltr'; 
  
  const featuredStories: Story[] = [
    {
      id: 'example1',
      createdAt: Date.now(),
      title: t.ex1_title,
      childName: t.ex1_childName,
      theme: 'space',
      language: currentLang,
      direction: langDir,
      coverImage: 'https://picsum.photos/seed/rocket/500/500',
      pages: [
        {
          id: 0,
          text: t.ex1_p0,
          imagePrompt: "",
          imageUrl: "https://picsum.photos/seed/rocket/800/800"
        },
        {
          id: 1,
          text: t.ex1_p1,
          imagePrompt: "",
          imageUrl: "https://picsum.photos/seed/stars/800/800"
        },
        {
          id: 2,
          text: t.ex1_p2,
          imagePrompt: "",
          imageUrl: "https://picsum.photos/seed/moon/800/800"
        }
      ]
    },
    {
      id: 'example2',
      createdAt: Date.now(),
      title: t.ex2_title,
      childName: t.ex2_childName,
      theme: 'jungle',
      language: currentLang,
      direction: langDir,
      coverImage: 'https://picsum.photos/seed/jungle/500/500',
      pages: [
        {
          id: 0,
          text: t.ex2_p0,
          imagePrompt: "",
          imageUrl: "https://picsum.photos/seed/jungle/800/800"
        },
        {
          id: 1,
          text: t.ex2_p1,
          imagePrompt: "",
          imageUrl: "https://picsum.photos/seed/lion/800/800"
        },
        {
          id: 2,
          text: t.ex2_p2,
          imagePrompt: "",
          imageUrl: "https://picsum.photos/seed/sunset/800/800"
        }
      ]
    }
  ];

  return (
    <div className="pb-24">
      {/* Hero Section */}
      <div className="relative overflow-hidden rounded-3xl bg-indigo-600 text-white p-8 text-center shadow-xl mb-8">
        <div className="absolute top-0 left-0 w-full h-full bg-[url('https://www.transparenttextures.com/patterns/stardust.png')] opacity-20"></div>
        <div className="relative z-10">
          <h1 className="text-3xl font-bold mb-2 font-serif">{t.heroTitle}</h1>
          <p className="text-indigo-100 mb-6">{t.heroSubtitle}</p>
          <button 
            onClick={onStartCreate}
            className="px-8 py-3 bg-white text-indigo-600 font-bold rounded-full shadow-lg hover:bg-indigo-50 transition-transform active:scale-95"
          >
            {t.startJourney}
          </button>
        </div>
      </div>

      {/* How It Works */}
      <div className="mb-8">
        <h2 className="text-xl font-bold text-gray-800 mb-4 px-2">{t.howItWorks}</h2>
        <div className="grid grid-cols-3 gap-2">
          <div className="bg-white p-3 rounded-2xl border border-gray-100 text-center shadow-sm">
            <div className="w-10 h-10 bg-blue-50 text-blue-500 rounded-full flex items-center justify-center mx-auto mb-2 text-xl">📸</div>
            <h3 className="font-bold text-xs text-gray-800 mb-1">{t.step1Title}</h3>
            <p className="text-[10px] text-gray-500 leading-tight">{t.step1Desc}</p>
          </div>
          <div className="bg-white p-3 rounded-2xl border border-gray-100 text-center shadow-sm">
            <div className="w-10 h-10 bg-purple-50 text-purple-500 rounded-full flex items-center justify-center mx-auto mb-2 text-xl">🏰</div>
            <h3 className="font-bold text-xs text-gray-800 mb-1">{t.step2Title}</h3>
            <p className="text-[10px] text-gray-500 leading-tight">{t.step2Desc}</p>
          </div>
          <div className="bg-white p-3 rounded-2xl border border-gray-100 text-center shadow-sm">
            <div className="w-10 h-10 bg-amber-50 text-amber-500 rounded-full flex items-center justify-center mx-auto mb-2 text-xl">✨</div>
            <h3 className="font-bold text-xs text-gray-800 mb-1">{t.step3Title}</h3>
            <p className="text-[10px] text-gray-500 leading-tight">{t.step3Desc}</p>
          </div>
        </div>
      </div>

      {/* Featured Stories */}
      <div>
        <h2 className="text-xl font-bold text-gray-800 mb-4 px-2">{t.featuredStories}</h2>
        <div className="space-y-4">
          {featuredStories.map(story => {
             const theme = THEMES.find(t => t.id === story.theme) || THEMES[0];
             const themeNameKey = `themeName_${theme.id}` as keyof UIStringMap;
             const localizedThemeName = t[themeNameKey] || theme.name;

             return (
              <div 
                key={story.id}
                onClick={() => onOpenStory(story)}
                className="bg-white rounded-2xl p-4 shadow-sm border border-gray-100 flex gap-4 cursor-pointer hover:shadow-md transition-all active:scale-[0.99]"
              >
                <div className={`w-20 h-20 rounded-xl bg-gray-200 flex-shrink-0 overflow-hidden`}>
                  <img src={story.coverImage} className="w-full h-full object-cover" alt="cover" />
                </div>
                <div className="flex-1 flex flex-col justify-center">
                  <h3 className="font-bold text-gray-900 mb-1">{story.title}</h3>
                  <div className="flex items-center gap-2 mb-2">
                    <span className="text-xs px-2 py-0.5 bg-gray-100 rounded text-gray-600 font-medium">{localizedThemeName}</span>
                  </div>
                  <span className="text-sm text-indigo-600 font-bold flex items-center gap-1">
                    {t.readNow} 
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14 5l7 7m0 0l-7 7m7-7H3" /></svg>
                  </span>
                </div>
              </div>
             );
          })}
        </div>
      </div>
    </div>
  );
};

export default Landing;