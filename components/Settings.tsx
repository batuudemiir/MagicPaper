

import React, { useState } from 'react';
import { LANGUAGES, UIStringMap, Tab } from '../types';
import InfoView from './InfoView';

interface SettingsProps {
  currentLang: string;
  onLanguageChange: (lang: string) => void;
  onNavigate: (tab: Tab) => void;
  isPremium: boolean;
  onUpgrade: () => void;
  t: UIStringMap;
}

type ViewState = 'menu' | 'about' | 'privacy' | 'terms' | 'support' | 'restore';

const Settings: React.FC<SettingsProps> = ({ currentLang, onLanguageChange, onNavigate, isPremium, onUpgrade, t }) => {
  const [devClicks, setDevClicks] = useState(0);
  const [currentView, setCurrentView] = useState<ViewState>('menu');

  const handleVersionClick = () => {
    setDevClicks(prev => prev + 1);
  };

  if (currentView !== 'menu') {
    let title = '';
    let content = '';

    switch (currentView) {
      case 'about': title = t.aboutUs; content = t.aboutUsContent; break;
      case 'privacy': title = t.privacyPolicy; content = t.privacyContent; break;
      case 'terms': title = t.termsOfService; content = t.termsContent; break;
      case 'support': title = t.contactSupport; content = t.supportContent; break;
      case 'restore': title = t.restorePurchases; content = t.restoreContent; break;
    }

    return (
      <InfoView 
        title={title} 
        content={content} 
        onBack={() => setCurrentView('menu')} 
      />
    );
  }

  return (
    <div className="pb-24 space-y-6 animate-fade-in">
      
      {/* Premium Banner */}
      <div className={`rounded-3xl p-6 text-white shadow-xl relative overflow-hidden transition-all duration-500 ${isPremium ? 'bg-gradient-to-br from-indigo-500 to-purple-600' : 'bg-gradient-to-br from-yellow-500 via-orange-400 to-pink-500'}`}>
        <div className="absolute top-0 right-0 p-8 opacity-20">
          <svg className="w-32 h-32 text-white" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" /></svg>
        </div>
        <div className="relative z-10 text-center">
          <h2 className="text-2xl font-bold mb-2 font-serif">
            {isPremium ? t.premiumActive : t.premiumTitle}
          </h2>
          <p className="text-white/90 text-sm mb-4 font-medium">
            {isPremium ? t.premiumDesc.replace('Unlock', 'Enjoying') : t.premiumDesc}
          </p>
          {!isPremium && (
            <button 
              onClick={onUpgrade}
              className="bg-white text-orange-600 px-6 py-3 rounded-xl font-bold shadow-lg active:scale-95 transition-transform w-full"
            >
              {t.upgradeNow}
            </button>
          )}
        </div>
      </div>

      {/* Quick Actions */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        <div className="p-4 border-b border-gray-100 bg-gray-50/50">
          <h2 className="text-sm font-bold text-gray-500 uppercase tracking-wider">{t.quickActions}</h2>
        </div>
        <div className="divide-y divide-gray-100">
          <button 
            onClick={() => onNavigate('create')}
            className="w-full flex items-center gap-4 p-4 hover:bg-gray-50 transition-colors text-left"
          >
            <div className="w-10 h-10 rounded-full bg-indigo-50 text-indigo-600 flex items-center justify-center">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" /></svg>
            </div>
            <span className="font-bold text-gray-800">{t.createStoryAction}</span>
          </button>
          
          <button 
            onClick={() => onNavigate('library')}
            className="w-full flex items-center gap-4 p-4 hover:bg-gray-50 transition-colors text-left"
          >
            <div className="w-10 h-10 rounded-full bg-purple-50 text-purple-600 flex items-center justify-center">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" /></svg>
            </div>
            <span className="font-bold text-gray-800">{t.myStoriesAction}</span>
          </button>
        </div>
      </div>

      {/* Preferences (Language) */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        <div className="p-4 border-b border-gray-100 bg-gray-50/50">
          <h2 className="text-sm font-bold text-gray-500 uppercase tracking-wider">{t.preferences}</h2>
        </div>
        
        <div className="divide-y divide-gray-100">
          {LANGUAGES.map((lang) => (
            <button
              key={lang.id}
              onClick={() => onLanguageChange(lang.id)}
              className="w-full flex items-center justify-between p-4 hover:bg-gray-50 transition-colors"
            >
              <div className="flex items-center gap-3">
                <span className="text-2xl">{lang.flag}</span>
                <span className="font-medium text-gray-700">{lang.name}</span>
              </div>
              
              {currentLang === lang.id && (
                <div className="text-indigo-600">
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" /></svg>
                </div>
              )}
            </button>
          ))}
        </div>
      </div>

      {/* Legal & Support */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
         <div className="p-4 border-b border-gray-100 bg-gray-50/50">
          <h2 className="text-sm font-bold text-gray-500 uppercase tracking-wider">{t.legal} & {t.support}</h2>
        </div>
        <div className="divide-y divide-gray-100">
          <button 
             onClick={() => setCurrentView('about')}
             className="w-full flex items-center justify-between p-4 hover:bg-gray-50 text-left text-gray-700 font-medium"
          >
             {t.aboutUs}
             <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
          </button>
          <button 
             onClick={() => setCurrentView('privacy')}
             className="w-full flex items-center justify-between p-4 hover:bg-gray-50 text-left text-gray-700 font-medium"
          >
             {t.privacyPolicy}
             <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" /></svg>
          </button>
          <button 
             onClick={() => setCurrentView('support')}
             className="w-full flex items-center justify-between p-4 hover:bg-gray-50 text-left text-gray-700 font-medium"
          >
             {t.contactSupport}
             <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" /></svg>
          </button>
          <button 
             onClick={() => setCurrentView('terms')}
             className="w-full flex items-center justify-between p-4 hover:bg-gray-50 text-left text-gray-700 font-medium"
          >
             {t.termsOfService}
             <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>
          </button>
          <button 
             onClick={() => setCurrentView('restore')}
             className="w-full flex items-center justify-between p-4 hover:bg-gray-50 text-left text-gray-700 font-medium"
          >
             {t.restorePurchases}
             <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" /></svg>
          </button>
        </div>
      </div>

      {devClicks >= 5 && (
        <div className="bg-gray-800 rounded-2xl p-4 shadow-lg animate-fade-in">
           <button 
            onClick={() => onNavigate('admin')}
            className="w-full flex items-center justify-between text-white font-bold"
           >
             <span>🛠️ {t.adminPanel}</span>
             <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
           </button>
        </div>
      )}

      <div className="mt-8 text-center pb-8">
        <p className="text-sm text-gray-400 cursor-pointer select-none" onClick={handleVersionClick}>
          MagicPaper v1.0.0 {devClicks > 0 && devClicks < 5 && `(${5 - devClicks})`}
        </p>
      </div>
      <style>{`
        .animate-fade-in { animation: fadeIn 0.3s ease-out forwards; }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
      `}</style>
    </div>
  );
};

export default Settings;