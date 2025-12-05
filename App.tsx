

import React, { useState, useEffect } from 'react';
import StoryForm from './components/StoryForm';
import StoryViewer from './components/StoryViewer';
import LoadingScreen from './components/LoadingScreen';
import BottomNav from './components/BottomNav';
import Library from './components/Library';
import Settings from './components/Settings';
import Landing from './components/Landing';
import AdminDashboard from './components/AdminDashboard';
import UpgradeModal from './components/UpgradeModal';
import { AppStatus, Story, Tab, StoryParams } from './types';
import { generateStoryStructure, generateIllustration, extendStory } from './services/genai';
import { getTranslations } from './utils/translations';
import { getAllStories, saveStoryToDB, deleteStoryFromDB } from './utils/storage';

const App: React.FC = () => {
  // App State
  const [activeTab, setActiveTab] = useState<Tab>('landing');
  const [appLang, setAppLang] = useState('en');
  const [status, setStatus] = useState<AppStatus>(AppStatus.IDLE);
  const [progressMsg, setProgressMsg] = useState('');
  
  // Data State
  const [currentStory, setCurrentStory] = useState<Story | null>(null);
  const [savedStories, setSavedStories] = useState<Story[]>([]);
  
  // Premium State
  const [isPremium, setIsPremium] = useState(false);
  const [showUpgradeModal, setShowUpgradeModal] = useState(false);

  // Load persisted data
  useEffect(() => {
    const initApp = async () => {
      // Load language from localStorage
      const savedLang = localStorage.getItem('magicpaper_lang');
      if (savedLang) setAppLang(savedLang);
      
      // Load premium status
      const savedPremium = localStorage.getItem('magicpaper_premium');
      if (savedPremium === 'true') setIsPremium(true);

      // Load stories from IndexedDB
      try {
        const stories = await getAllStories();
        setSavedStories(stories);
      } catch (e) {
        console.error("Failed to load stories from DB", e);
      }
    };
    
    initApp();
  }, []);

  const t = getTranslations(appLang);

  const handleAppLangChange = (lang: string) => {
    setAppLang(lang);
    localStorage.setItem('magicpaper_lang', lang);
  };

  const handleUpgrade = () => {
    setIsPremium(true);
    localStorage.setItem('magicpaper_premium', 'true');
    setShowUpgradeModal(false);
    alert("Welcome to Premium! 🌟");
  };

  const saveStory = async (story: Story) => {
    try {
      // Optimistic Update
      const existingIndex = savedStories.findIndex(s => s.id === story.id);
      let updatedStories;
      
      if (existingIndex >= 0) {
        updatedStories = [...savedStories];
        updatedStories[existingIndex] = story;
      } else {
        updatedStories = [story, ...savedStories];
      }
      setSavedStories(updatedStories);

      // Persist to IndexedDB
      await saveStoryToDB(story);
    } catch (e) {
      console.error("Storage Error", e);
      alert(t.alert_storageFull);
    }
  };

  const deleteStory = async (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    if(window.confirm(t.alert_confirmDelete)) {
      // Optimistic Update
      const updated = savedStories.filter(s => s.id !== id);
      setSavedStories(updated);

      // Remove from DB
      try {
        await deleteStoryFromDB(id);
      } catch (error) {
        console.error("Failed to delete from DB", error);
      }
    }
  };

  const handleUpdateProgress = async (storyId: string, pageIndex: number) => {
    const storyToUpdate = savedStories.find(s => s.id === storyId);
    if (!storyToUpdate) return;

    const updatedStory = { ...storyToUpdate, lastReadPage: pageIndex };
    
    // Update State
    const updatedList = savedStories.map(s => s.id === storyId ? updatedStory : s);
    setSavedStories(updatedList);

    // Update DB (Debounced slightly ideally, but direct is fine for now)
    try {
      await saveStoryToDB(updatedStory);
    } catch (e) {
      console.error("Failed to save progress", e);
    }
  };

  const generateImagesForPages = async (pages: any[], startIdx = 0, photoBase64: string, theme: string, aspectRatio: string = '1:1') => {
      const pagesWithImages = [];
      
      for (let i = 0; i < pages.length; i++) {
        const page = pages[i];
        setProgressMsg(`${t.progress_painting} ${startIdx + i + 1}...`);
        
        // RATE LIMIT FIX: Add a significant delay (15s) between requests to avoid hitting the RPM limit
        // We ensure we wait *before* the request if it's not the very first one in the batch
        if (i > 0) {
          await new Promise(resolve => setTimeout(resolve, 15000));
        }

        const imageUrl = await generateIllustration(
          page.imagePrompt,
          photoBase64,
          theme,
          aspectRatio
        );
        pagesWithImages.push({ ...page, imageUrl });
      }
      return pagesWithImages;
  }

  const handleGenerate = async (params: StoryParams) => {
    // Check Limits
    if (!isPremium && savedStories.length >= 1) {
      setShowUpgradeModal(true);
      return;
    }

    try {
      setStatus(AppStatus.GENERATING_TEXT);
      setProgressMsg(t.generating);

      const generatedStory = await generateStoryStructure(
        params.name, 
        params.age, 
        params.theme, 
        params.language,
        params.customTitle,
        params.gender
      );
      
      setStatus(AppStatus.GENERATING_IMAGES);
      
      const completedPages = await generateImagesForPages(
        generatedStory.pages, 
        0, 
        params.photoBase64, 
        generatedStory.theme,
        params.aspectRatio
      );

      const finalStory: Story = {
        ...generatedStory,
        pages: completedPages,
        // Priority: Manually selected cover > First page image > Reference photo
        coverImage: params.coverImage || completedPages[0]?.imageUrl || params.photoBase64
      };
      
      await saveStory(finalStory);
      setStatus(AppStatus.COMPLETE);
      
      // Show celebration for 3 seconds, then redirect to library
      setTimeout(() => {
        setStatus(AppStatus.IDLE);
        setActiveTab('library');
      }, 3000);

    } catch (error) {
      console.error(error);
      alert(t.alert_errorGenerating);
      setStatus(AppStatus.IDLE);
    }
  };

  const handleExtend = async (story: Story, userGuidance?: string) => {
    try {
      setStatus(AppStatus.EXTENDING);
      setProgressMsg(t.extending);

      const newPages = await extendStory(story, userGuidance);

      setStatus(AppStatus.GENERATING_IMAGES);
      
      // Need reference photo, try to get from cover or first page
      const refPhoto = story.coverImage || story.pages[0].imageUrl || ""; 
      
      const completedNewPages = await generateImagesForPages(
        newPages,
        story.pages.length,
        refPhoto,
        story.theme,
        '1:1' // Default ratio for extensions if original isn't stored, ideally should store ratio in Story object
      );

      const updatedStory = {
        ...story,
        pages: [...story.pages, ...completedNewPages]
      };

      await saveStory(updatedStory);
      // If we are already in the viewer (currentStory is set), update it.
      if (currentStory && currentStory.id === story.id) {
        setCurrentStory(updatedStory);
      }
      
      setStatus(AppStatus.COMPLETE);
      // Give a delay to show completion animation, but stay on viewer for extension
      setTimeout(() => setStatus(AppStatus.IDLE), 3000);

    } catch (error) {
       console.error(error);
       alert("Could not extend story. Quota may be exceeded.");
       setStatus(AppStatus.IDLE);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 font-sans text-slate-800 flex flex-col">
      {/* Mobile Top Bar */}
      <header className="bg-white/95 backdrop-blur-md sticky top-0 z-30 px-6 py-3 flex items-center justify-between shadow-sm border-b border-gray-100">
        <div className="flex items-center gap-3">
          {activeTab === 'landing' && (
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-600 to-purple-600 flex items-center justify-center text-white shadow-indigo-200 shadow-lg">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" /></svg>
            </div>
          )}
          <div>
            <h1 className={`font-bold tracking-tight bg-clip-text text-transparent bg-gradient-to-r from-indigo-600 to-purple-600 ${activeTab === 'landing' ? 'text-2xl font-serif' : 'text-xl'}`}>
              {activeTab === 'landing' && "MagicPaper"}
              {activeTab === 'create' && t.createTitle}
              {activeTab === 'library' && t.library}
              {activeTab === 'settings' && t.settings}
              {activeTab === 'admin' && t.adminPanel}
            </h1>
            {activeTab === 'create' && <p className="text-xs text-gray-400 font-medium">{t.createSubtitle}</p>}
          </div>
        </div>
        {activeTab === 'landing' && (
           <div className="w-8 h-8 flex items-center justify-center">
             {/* Logo Icon on Right for Landing if needed, or keeping clean */}
           </div>
        )}
      </header>

      {/* Main Content Area */}
      <main className="flex-1 max-w-md mx-auto w-full p-4 relative">
        
        {activeTab === 'landing' && (
          <Landing 
             onStartCreate={() => setActiveTab('create')} 
             onOpenStory={(s) => setCurrentStory(s)}
             t={t}
             currentLang={appLang}
          />
        )}

        {activeTab === 'create' && (
          <StoryForm 
            onSubmit={handleGenerate} 
            isSubmitting={status !== AppStatus.IDLE && status !== AppStatus.COMPLETE} 
            t={t} 
            appLang={appLang}
          />
        )}

        {activeTab === 'library' && (
          <Library 
            stories={savedStories} 
            onSelectStory={(s) => { setCurrentStory(s); }}
            onDeleteStory={deleteStory}
            onExtend={handleExtend}
            t={t}
          />
        )}

        {activeTab === 'settings' && (
          <Settings 
            currentLang={appLang} 
            onLanguageChange={handleAppLangChange}
            onNavigate={(tab) => setActiveTab(tab)}
            isPremium={isPremium}
            onUpgrade={() => setShowUpgradeModal(true)}
            t={t}
          />
        )}

        {activeTab === 'admin' && (
          <AdminDashboard 
            onNavigate={(tab) => setActiveTab(tab)}
            t={t}
          />
        )}
      </main>

      {/* Loading Overlay */}
      {(status !== AppStatus.IDLE) && (
        <LoadingScreen status={status} progressMessage={progressMsg} t={t} />
      )}

      {/* Full Screen Story Viewer (Modal) */}
      {currentStory && (
        <StoryViewer 
          story={currentStory} 
          onClose={() => setCurrentStory(null)}
          // Only allow extension if it's a real story ID that exists in savedStories (not an example)
          onExtend={savedStories.find(s => s.id === currentStory.id) ? handleExtend : undefined}
          onSaveProgress={(page) => handleUpdateProgress(currentStory.id, page)}
          t={t}
        />
      )}

      {/* Upgrade Modal */}
      {showUpgradeModal && (
        <UpgradeModal 
          onUpgrade={handleUpgrade} 
          onClose={() => setShowUpgradeModal(false)}
          t={t}
        />
      )}

      {/* Bottom Navigation */}
      <BottomNav activeTab={activeTab === 'admin' ? 'settings' : activeTab} onTabChange={setActiveTab} t={t} />
    </div>
  );
};

export default App;