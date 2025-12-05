

import React, { useState, useRef, useEffect } from 'react';
import { THEMES, LANGUAGES, ASPECT_RATIOS, UIStringMap, StoryParams } from '../types';
import { generateStoryPreview, generateCover } from '../services/genai';

interface StoryFormProps {
  onSubmit: (data: StoryParams) => void;
  isSubmitting: boolean;
  t: UIStringMap;
  appLang: string;
}

const StoryForm: React.FC<StoryFormProps> = ({ onSubmit, isSubmitting, t, appLang }) => {
  const [name, setName] = useState('');
  const [customTitle, setCustomTitle] = useState('');
  const [age, setAge] = useState<string>('5');
  const [selectedGender, setSelectedGender] = useState<string>('boy');
  const [selectedTheme, setSelectedTheme] = useState<string>(THEMES[0].id);
  const [selectedLanguage, setSelectedLanguage] = useState<string>(appLang);
  const [selectedAspectRatio, setSelectedAspectRatio] = useState<string>(ASPECT_RATIOS[0].id);
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);
  
  // Cover State
  const [coverImage, setCoverImage] = useState<string | null>(null);
  const [isCoverGenerating, setIsCoverGenerating] = useState(false);
  const coverInputRef = useRef<HTMLInputElement>(null);

  const fileInputRef = useRef<HTMLInputElement>(null);

  // Preview State
  const [previewData, setPreviewData] = useState<{ text: string; imageUrl: string } | null>(null);
  const [isPreviewLoading, setIsPreviewLoading] = useState(false);

  // Sync selected language if app language changes
  useEffect(() => {
    // If the supported languages list includes the appLang, switch to it.
    // Otherwise keep default (English or previous selection)
    if (LANGUAGES.some(l => l.id === appLang)) {
        setSelectedLanguage(appLang);
    }
  }, [appLang]);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setPhotoPreview(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };
  
  const handleCoverFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setCoverImage(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleGenerateCover = async () => {
    if (!name || !photoPreview) {
      alert(t.alert_uploadPhoto);
      return;
    }
    setIsCoverGenerating(true);
    try {
      const coverUrl = await generateCover(
        customTitle || `${name}'s Adventure`,
        selectedTheme,
        selectedGender,
        parseInt(age),
        photoPreview
      );
      setCoverImage(coverUrl);
    } catch (e) {
      console.error(e);
      alert(t.alert_coverError);
    } finally {
      setIsCoverGenerating(false);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !photoPreview) return;
    onSubmit({
      name,
      age: parseInt(age),
      gender: selectedGender,
      theme: selectedTheme,
      photoBase64: photoPreview,
      language: selectedLanguage,
      customTitle: customTitle.trim() || undefined,
      coverImage: coverImage || undefined,
      aspectRatio: selectedAspectRatio,
    });
  };

  const handlePreview = async () => {
    if (!name || !photoPreview) return;
    setIsPreviewLoading(true);
    try {
      const data = await generateStoryPreview(
        name, 
        parseInt(age), 
        selectedTheme, 
        selectedLanguage, 
        photoPreview,
        customTitle.trim() || undefined,
        selectedGender
      );
      setPreviewData(data);
    } catch (e) {
      console.error(e);
      alert(t.alert_previewError);
    } finally {
      setIsPreviewLoading(false);
    }
  };

  return (
    <div className="pb-24">
      <form onSubmit={handleSubmit} className="space-y-6">
        
        {/* Photo Upload - Hero Section */}
        <div className="bg-white rounded-3xl p-6 shadow-sm border border-gray-100 text-center relative overflow-hidden group">
          <label className="block text-sm font-bold text-gray-400 uppercase tracking-wider mb-4">{t.uploadPhoto}</label>
          <div 
            className={`relative mx-auto w-40 h-40 rounded-full border-4 transition-all cursor-pointer ${
              photoPreview ? 'border-indigo-500 shadow-xl scale-105' : 'border-dashed border-gray-300 bg-gray-50'
            }`}
            onClick={() => fileInputRef.current?.click()}
          >
            {photoPreview ? (
              <img src={photoPreview} alt="Preview" className="w-full h-full object-cover rounded-full" />
            ) : (
              <div className="flex flex-col items-center justify-center h-full text-gray-400">
                <svg className="w-10 h-10 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" /></svg>
                <span className="text-xs font-semibold">+ Add Photo</span>
              </div>
            )}
            {photoPreview && (
              <div className="absolute bottom-0 right-0 bg-indigo-600 text-white p-2 rounded-full shadow-lg border-2 border-white">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" /></svg>
              </div>
            )}
            <input 
              ref={fileInputRef}
              type="file" 
              accept="image/*" 
              onChange={handleFileChange} 
              className="hidden" 
            />
          </div>
        </div>

        {/* Child Info Card */}
        <div className="bg-white rounded-3xl p-6 shadow-sm border border-gray-100 space-y-4">
          <div>
            <label className="block text-sm font-bold text-gray-700 mb-1 ml-1">{t.childName}</label>
            <input 
              type="text" 
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Charlie"
              className="w-full px-4 py-3 rounded-2xl bg-gray-50 border-transparent focus:bg-white focus:border-indigo-500 focus:ring-0 transition-all text-lg font-semibold text-gray-800"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-bold text-gray-700 mb-1 ml-1">{t.storyTitle}</label>
            <input 
              type="text" 
              value={customTitle}
              onChange={(e) => setCustomTitle(e.target.value)}
              placeholder={t.storyTitlePlaceholder}
              className="w-full px-4 py-3 rounded-2xl bg-gray-50 border-transparent focus:bg-white focus:border-indigo-500 focus:ring-0 transition-all text-lg font-semibold text-gray-800"
            />
          </div>
          
          <div className="flex gap-4">
            <div className="flex-1">
              <label className="block text-sm font-bold text-gray-700 mb-2 ml-1">{t.age}</label>
              <div className="flex gap-2 overflow-x-auto pb-1 no-scrollbar">
                {[3, 4, 5, 6, 7, 8].map(a => (
                  <button
                    key={a}
                    type="button"
                    onClick={() => setAge(a.toString())}
                    className={`flex-shrink-0 w-10 h-10 rounded-full font-bold transition-all ${
                      parseInt(age) === a 
                        ? 'bg-indigo-600 text-white shadow-md' 
                        : 'bg-gray-50 text-gray-500 hover:bg-gray-100'
                    }`}
                  >
                    {a}
                  </button>
                ))}
              </div>
            </div>
          </div>
          
          <div>
               <label className="block text-sm font-bold text-gray-700 mb-2 ml-1">{t.selectGender}</label>
               <div className="flex gap-2">
                 <button
                    type="button"
                    onClick={() => setSelectedGender('boy')}
                    className={`flex-1 px-4 py-3 rounded-xl text-sm font-semibold transition-all border ${
                       selectedGender === 'boy'
                       ? 'bg-blue-100 text-blue-700 border-blue-200 shadow-sm' 
                       : 'bg-gray-50 text-gray-600 border-gray-100'
                    }`}
                  >
                    {t.gender_boy}
                  </button>
                  <button
                    type="button"
                    onClick={() => setSelectedGender('girl')}
                    className={`flex-1 px-4 py-3 rounded-xl text-sm font-semibold transition-all border ${
                       selectedGender === 'girl'
                       ? 'bg-pink-100 text-pink-700 border-pink-200 shadow-sm' 
                       : 'bg-gray-50 text-gray-600 border-gray-100'
                    }`}
                  >
                    {t.gender_girl}
                  </button>
                  <button
                    type="button"
                    onClick={() => setSelectedGender('other')}
                    className={`flex-1 px-4 py-3 rounded-xl text-sm font-semibold transition-all border ${
                       selectedGender === 'other'
                       ? 'bg-purple-100 text-purple-700 border-purple-200 shadow-sm' 
                       : 'bg-gray-50 text-gray-600 border-gray-100'
                    }`}
                  >
                    {t.gender_other}
                  </button>
               </div>
            </div>
        </div>

        {/* Story Language */}
        <div className="bg-white rounded-3xl p-6 shadow-sm border border-gray-100">
           <label className="block text-sm font-bold text-gray-700 mb-3 ml-1">{t.selectLanguage}</label>
           <div className="flex gap-3 overflow-x-auto pb-2 no-scrollbar">
              {LANGUAGES.map((lang) => (
                <button
                  key={lang.id}
                  type="button"
                  onClick={() => setSelectedLanguage(lang.id)}
                  className={`flex-shrink-0 px-4 py-2 rounded-xl border-2 transition-all flex items-center gap-2 ${
                    selectedLanguage === lang.id 
                      ? 'border-indigo-500 bg-indigo-50 text-indigo-700' 
                      : 'border-gray-100 bg-white text-gray-600'
                  }`}
                >
                  <span className="text-xl">{lang.flag}</span>
                  <span className="font-semibold text-sm">{lang.name}</span>
                </button>
              ))}
           </div>
        </div>

        {/* Aspect Ratio */}
        <div className="bg-white rounded-3xl p-6 shadow-sm border border-gray-100">
           <label className="block text-sm font-bold text-gray-700 mb-3 ml-1">{t.selectAspectRatio}</label>
           <div className="flex gap-2 overflow-x-auto pb-2 no-scrollbar">
              {ASPECT_RATIOS.map((ratio) => (
                <button
                  key={ratio.id}
                  type="button"
                  onClick={() => setSelectedAspectRatio(ratio.id)}
                  className={`flex-shrink-0 px-4 py-2 rounded-xl border-2 transition-all flex items-center gap-2 ${
                    selectedAspectRatio === ratio.id 
                      ? 'border-indigo-500 bg-indigo-50 text-indigo-700' 
                      : 'border-gray-100 bg-white text-gray-600'
                  }`}
                >
                  <span className="font-semibold text-sm">{ratio.label}</span>
                </button>
              ))}
           </div>
        </div>

        {/* Theme Selection */}
        <div>
          <label className="block text-sm font-bold text-gray-700 mb-3 ml-4">{t.selectTheme}</label>
          <div className="grid grid-cols-2 gap-3 px-1">
            {THEMES.map((theme) => {
              const themeNameKey = `themeName_${theme.id}` as keyof UIStringMap;
              const themeDescKey = `themeDesc_${theme.id}` as keyof UIStringMap;
              
              return (
                <button
                  key={theme.id}
                  type="button"
                  onClick={() => setSelectedTheme(theme.id)}
                  className={`relative p-4 rounded-2xl text-left transition-all overflow-hidden flex flex-col justify-between ${
                    selectedTheme === theme.id 
                      ? 'ring-2 ring-indigo-500 shadow-md transform scale-[1.02] bg-white' 
                      : 'bg-white border border-gray-100 shadow-sm opacity-90 hover:opacity-100'
                  }`}
                  style={{ minHeight: '140px' }}
                >
                  <div className={`absolute inset-0 bg-gradient-to-br ${theme.color} opacity-10 pointer-events-none`} />
                  
                  <div className="relative z-10 flex justify-between items-start mb-2">
                    <span className="text-4xl filter drop-shadow-sm">{theme.emoji}</span>
                    {selectedTheme === theme.id && (
                      <div className="text-indigo-600 bg-white rounded-full p-1 shadow-sm">
                        <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" /></svg>
                      </div>
                    )}
                  </div>
                  
                  <div className="relative z-10">
                    <span className={`font-bold text-sm block leading-tight mb-1 ${selectedTheme === theme.id ? 'text-gray-900' : 'text-gray-700'}`}>
                      {t[themeNameKey]}
                    </span>
                    <span className="text-xs text-gray-500 leading-tight block line-clamp-2">
                      {t[themeDescKey]}
                    </span>
                  </div>
                </button>
              );
            })}
          </div>
        </div>

        {/* Story Cover Selection */}
        <div className="bg-white rounded-3xl p-6 shadow-sm border border-gray-100">
          <label className="block text-sm font-bold text-gray-700 mb-3 ml-1">{t.storyCover}</label>
          <div className="flex gap-4 items-start">
            <div className="w-24 h-32 bg-gray-100 rounded-lg flex-shrink-0 overflow-hidden border border-gray-200">
               {coverImage ? (
                 <img src={coverImage} alt="Cover" className="w-full h-full object-cover" />
               ) : (
                 <div className="w-full h-full flex items-center justify-center text-gray-300">
                   <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg>
                 </div>
               )}
            </div>
            <div className="flex-1 space-y-2">
               <button 
                 type="button"
                 onClick={handleGenerateCover}
                 disabled={isCoverGenerating || !photoPreview}
                 className={`w-full py-2 px-4 rounded-xl text-sm font-bold flex items-center justify-center gap-2 ${
                    isCoverGenerating 
                    ? 'bg-indigo-50 text-indigo-400 cursor-wait' 
                    : 'bg-indigo-600 text-white hover:bg-indigo-700 shadow-md'
                 }`}
               >
                 {isCoverGenerating ? (
                   <>
                    <div className="w-3 h-3 border-2 border-white/50 border-t-white rounded-full animate-spin"/>
                    <span>{t.creating}</span>
                   </>
                 ) : (
                   <>
                    <span>✨</span> {t.generateCover}
                   </>
                 )}
               </button>
               <button 
                 type="button"
                 onClick={() => coverInputRef.current?.click()}
                 className="w-full py-2 px-4 rounded-xl text-sm font-bold bg-white border border-gray-200 text-gray-600 hover:bg-gray-50"
               >
                 {t.uploadCover}
               </button>
               <input 
                ref={coverInputRef}
                type="file" 
                accept="image/*" 
                onChange={handleCoverFileChange} 
                className="hidden" 
              />
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="grid grid-cols-2 gap-3">
          <button
            type="button"
            onClick={handlePreview}
            disabled={!name || !photoPreview || isSubmitting || isPreviewLoading}
            className={`py-4 rounded-2xl text-lg font-bold border-2 transition-all active:scale-95
              ${!name || !photoPreview || isSubmitting || isPreviewLoading
                ? 'border-gray-200 text-gray-400 cursor-not-allowed bg-gray-50' 
                : 'border-indigo-100 text-indigo-600 bg-white hover:bg-indigo-50 hover:border-indigo-200'
              }`}
          >
            {isPreviewLoading ? (
               <svg className="animate-spin h-5 w-5 mx-auto text-indigo-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
            ) : (
              t.previewButton
            )}
          </button>

          <button
            type="submit"
            disabled={!name || !photoPreview || isSubmitting || isPreviewLoading}
            className={`py-4 rounded-2xl text-lg font-bold text-white shadow-xl transform transition-all active:scale-95
              ${!name || !photoPreview || isSubmitting || isPreviewLoading
                ? 'bg-gray-300 cursor-not-allowed' 
                : 'bg-gradient-to-r from-indigo-600 to-purple-600 shadow-indigo-200'
              }`}
          >
            {isSubmitting ? (
              <span className="flex items-center justify-center gap-2">
                <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                {t.generating}
              </span>
            ) : (
              t.generateButton
            )}
          </button>
        </div>
      </form>

      {/* Preview Modal */}
      {previewData && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fade-in">
          <div className="bg-white rounded-3xl w-full max-w-sm overflow-hidden shadow-2xl animate-scale-in">
            <div className="p-4 bg-gradient-to-r from-indigo-500 to-purple-500 flex justify-between items-center text-white">
              <h3 className="font-bold text-lg">{t.previewTitle}</h3>
              <button onClick={() => setPreviewData(null)} className="p-1 rounded-full hover:bg-white/20">
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
              </button>
            </div>
            
            <div className="relative aspect-square bg-gray-100">
               <img src={previewData.imageUrl} alt="Preview" className="w-full h-full object-cover" />
            </div>
            
            <div className="p-6">
              <p className="text-gray-700 font-serif text-lg leading-relaxed text-center">
                {previewData.text}
              </p>
            </div>

            <div className="p-4 bg-gray-50 text-center">
              <button 
                onClick={() => setPreviewData(null)}
                className="w-full py-3 bg-white border border-gray-200 rounded-xl text-gray-700 font-bold hover:bg-gray-100"
              >
                {t.closePreview}
              </button>
            </div>
          </div>
        </div>
      )}
      <style>{`
        @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
        @keyframes scaleIn { from { transform: scale(0.9); opacity: 0; } to { transform: scale(1); opacity: 1; } }
        .animate-fade-in { animation: fadeIn 0.2s ease-out forwards; }
        .animate-scale-in { animation: scaleIn 0.3s ease-out forwards; }
      `}</style>
    </div>
  );
};

export default StoryForm;