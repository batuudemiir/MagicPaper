

import React from 'react';
import { Tab, UIStringMap } from '../types';

interface BottomNavProps {
  activeTab: Tab;
  onTabChange: (tab: Tab) => void;
  t: UIStringMap;
}

const BottomNav: React.FC<BottomNavProps> = ({ activeTab, onTabChange, t }) => {
  return (
    <div className="fixed bottom-0 left-0 right-0 bg-white/95 backdrop-blur-lg border-t border-gray-200 pb-safe pt-2 px-6 z-40 shadow-[0_-5px_10px_rgba(0,0,0,0.02)]">
      <div className="flex justify-between items-center max-w-md mx-auto">
        
        {/* Landing (Home) */}
        <button
          onClick={() => onTabChange('landing')}
          className={`flex flex-col items-center gap-1 p-2 transition-all duration-300 ${
            activeTab === 'landing' ? 'text-indigo-600 scale-105' : 'text-gray-400 hover:text-indigo-400'
          }`}
        >
          <svg className="w-6 h-6" fill={activeTab === 'landing' ? "currentColor" : "none"} stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
          </svg>
          <span className="text-[10px] font-bold">{t.landing}</span>
        </button>

        {/* Create (Form) */}
        <button
          onClick={() => onTabChange('create')}
          className={`flex flex-col items-center gap-1 p-2 transition-all duration-300 ${
            activeTab === 'create' ? 'text-indigo-600 scale-105' : 'text-gray-400 hover:text-indigo-400'
          }`}
        >
          <div className={`p-1 rounded-full ${activeTab === 'create' ? 'bg-indigo-50' : ''}`}>
            <svg className="w-6 h-6" fill={activeTab === 'create' ? "currentColor" : "none"} stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z" />
            </svg>
          </div>
          <span className="text-[10px] font-bold">{t.create}</span>
        </button>

        {/* Library */}
        <button
          onClick={() => onTabChange('library')}
          className={`flex flex-col items-center gap-1 p-2 transition-all duration-300 ${
            activeTab === 'library' ? 'text-indigo-600 scale-105' : 'text-gray-400 hover:text-indigo-400'
          }`}
        >
          <svg className="w-6 h-6" fill={activeTab === 'library' ? "currentColor" : "none"} stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
          </svg>
          <span className="text-[10px] font-bold">{t.library}</span>
        </button>

        {/* Settings */}
        <button
          onClick={() => onTabChange('settings')}
          className={`flex flex-col items-center gap-1 p-2 transition-all duration-300 ${
            activeTab === 'settings' ? 'text-indigo-600 scale-105' : 'text-gray-400 hover:text-indigo-400'
          }`}
        >
          <svg className="w-6 h-6" fill={activeTab === 'settings' ? "currentColor" : "none"} stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
            <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
          <span className="text-[10px] font-bold">{t.settings}</span>
        </button>
      </div>
    </div>
  );
};

export default BottomNav;
