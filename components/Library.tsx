

import React from 'react';
import { Story, THEMES, UIStringMap } from '../types';

interface LibraryProps {
  stories: Story[];
  onSelectStory: (story: Story) => void;
  onDeleteStory: (id: string, e: React.MouseEvent) => void;
  onExtend: (story: Story) => void;
  t: UIStringMap;
}

const Library: React.FC<LibraryProps> = ({ stories, onSelectStory, onDeleteStory, onExtend, t }) => {
  if (stories.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-[60vh] text-center p-6">
        <div className="w-24 h-24 bg-indigo-50 rounded-full flex items-center justify-center mb-6">
          <span className="text-4xl">📚</span>
        </div>
        <h3 className="text-xl font-bold text-gray-800 mb-2">{t.noStories}</h3>
        <p className="text-gray-500">{t.startCreating}</p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 gap-4 pb-24">
      {stories.map((story) => {
        const theme = THEMES.find(t => t.id === story.theme) || THEMES[0];
        const coverImage = story.coverImage || story.pages[0]?.imageUrl;
        const themeNameKey = `themeName_${theme.id}` as keyof UIStringMap;
        const localizedThemeName = t[themeNameKey] || theme.name;

        return (
          <div 
            key={story.id}
            onClick={() => onSelectStory(story)}
            className="bg-white rounded-2xl p-4 shadow-sm border border-gray-100 flex gap-4 hover:shadow-md transition-shadow cursor-pointer relative overflow-hidden group"
          >
            {/* Cover Thumbnail */}
            <div className={`w-24 h-24 rounded-xl flex-shrink-0 overflow-hidden bg-gradient-to-br ${theme.color}`}>
              {coverImage ? (
                <img src={coverImage} alt="Cover" className="w-full h-full object-cover" />
              ) : (
                <div className="w-full h-full flex items-center justify-center text-2xl">
                  {theme.emoji}
                </div>
              )}
            </div>

            {/* Info */}
            <div className="flex-1 min-w-0 flex flex-col justify-center">
              <h3 className="font-bold text-lg text-gray-900 truncate mb-1">{story.title}</h3>
              <p className="text-gray-500 text-sm mb-2">{story.childName} • {new Date(story.createdAt).toLocaleDateString()}</p>
              
              <div className="flex items-center gap-2">
                <span className="text-xs px-2 py-1 bg-gray-100 rounded-md text-gray-600 font-medium">
                  {localizedThemeName}
                </span>
                <span className="text-xs px-2 py-1 bg-gray-100 rounded-md text-gray-600 font-medium uppercase">
                  {story.language}
                </span>
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex flex-col gap-2 justify-center ml-2">
               {/* Extend Story Button */}
               <button 
                  onClick={(e) => { e.stopPropagation(); onExtend(story); }}
                  className="p-2 bg-indigo-50 text-indigo-600 rounded-full hover:bg-indigo-100 active:scale-95 transition-transform"
                  title={t.continueStory}
               >
                 <span className="text-lg">✨</span>
               </button>

               {/* Delete Button */}
               <button 
                onClick={(e) => onDeleteStory(story.id, e)}
                className="p-2 bg-red-50 text-red-400 rounded-full hover:bg-red-100 hover:text-red-500 active:scale-95 transition-transform"
                title={t.delete}
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
              </button>
            </div>
          </div>
        );
      })}
    </div>
  );
};

export default Library;