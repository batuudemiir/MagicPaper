
import React from 'react';
import { AppStatus, UIStringMap } from '../types';

interface LoadingScreenProps {
  status: AppStatus;
  progressMessage: string;
  t: UIStringMap;
}

const LoadingScreen: React.FC<LoadingScreenProps> = ({ status, progressMessage, t }) => {
  const isComplete = status === AppStatus.COMPLETE;
  
  return (
    <div className="fixed inset-0 z-50 flex flex-col items-center justify-center bg-amber-50/95 backdrop-blur-sm p-4">
      <div className="w-full max-w-md bg-white rounded-3xl shadow-2xl p-8 text-center border-4 border-indigo-100 relative overflow-hidden">
        
        {/* Success Background Effect */}
        {isComplete && (
          <div className="absolute inset-0 bg-gradient-to-br from-indigo-50 via-white to-purple-50 opacity-50 z-0"></div>
        )}

        <div className="relative z-10">
            {/* Animated Icon based on status */}
            <div className="mb-8 relative h-32 flex items-center justify-center">
            {status === AppStatus.GENERATING_TEXT && (
                <div className="text-6xl animate-bounce">✍️</div>
            )}
            {status === AppStatus.GENERATING_IMAGES && (
                <div className="text-6xl animate-pulse">🎨</div>
            )}
            {status === AppStatus.EXTENDING && (
                <div className="text-6xl animate-pulse">✨</div>
            )}
            {isComplete && (
                <div className="relative">
                    {/* Burst Effect */}
                    <div className="absolute inset-0 bg-yellow-200 rounded-full blur-xl opacity-60 animate-ping"></div>
                    <div className="text-7xl animate-bounce relative z-10">📖</div>
                    <div className="absolute -bottom-2 -right-2 text-4xl animate-bounce z-20" style={{ animationDelay: '0.2s' }}>✅</div>
                </div>
            )}
            </div>

            {isComplete ? (
            <div className="animate-fade-in">
                <h3 className="text-3xl font-bold text-indigo-600 mb-2">{t.storyReady}</h3>
                <p className="text-gray-500 font-medium">{t.addedToLibrary}</p>
            </div>
            ) : (
            <>
                <h3 className="text-2xl font-bold text-gray-800 mb-2">{t.generating}</h3>
                <p className="text-indigo-600 font-medium mb-6">{progressMessage}</p>

                {/* Progress Bar */}
                <div className="w-full bg-gray-100 rounded-full h-4 overflow-hidden mb-4">
                <div 
                    className="h-full bg-gradient-to-r from-indigo-500 to-purple-500 transition-all duration-500 ease-out"
                    style={{ 
                    width: 
                        status === AppStatus.GENERATING_TEXT ? '30%' :
                        status === AppStatus.GENERATING_IMAGES ? '80%' : 
                        status === AppStatus.EXTENDING ? '40%' : '10%'
                    }}
                />
                </div>
                
                <p className="text-sm text-gray-400 italic">
                Magic takes a moment...
                </p>
            </>
            )}
        </div>
      </div>
      <style>{`
        .animate-fade-in { animation: fadeIn 0.5s ease-out forwards; }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
      `}</style>
    </div>
  );
};

export default LoadingScreen;
