

import React, { useState, useRef, useEffect } from 'react';
import { Story, THEMES, LANGUAGES, UIStringMap } from '../types';
import { jsPDF } from "jspdf";
import html2canvas from "html2canvas";
import { playPageTurnSound } from '../utils/audio';

interface StoryViewerProps {
  story: Story;
  onClose: () => void;
  onExtend?: (story: Story, guidance?: string) => void;
  onSaveProgress?: (pageIndex: number) => void;
  t: UIStringMap;
}

// Sub-component for Theme-specific ambient effects
const ThemeEffects: React.FC<{ themeId: string }> = ({ themeId }) => {
  // Generate random positions for particles once on mount to avoid re-renders causing jumps
  const particles = useRef([...Array(12)].map(() => ({
    left: `${Math.random() * 100}%`,
    top: `${Math.random() * 100}%`,
    delay: `${Math.random() * 5}s`,
    duration: `${3 + Math.random() * 5}s`,
    size: `${Math.random() * 10 + 5}px`
  }))).current;

  switch (themeId) {
    case 'space':
      return (
        <div className="absolute inset-0 overflow-hidden pointer-events-none z-10">
          {particles.map((p, i) => (
            <div 
              key={i}
              className="absolute bg-white rounded-full opacity-0 animate-twinkle"
              style={{
                left: p.left,
                top: p.top,
                width: Math.random() > 0.5 ? '2px' : '4px',
                height: Math.random() > 0.5 ? '2px' : '4px',
                animationDelay: p.delay,
                animationDuration: p.duration,
                boxShadow: '0 0 4px 1px rgba(255, 255, 255, 0.8)'
              }}
            />
          ))}
        </div>
      );
    case 'underwater':
      return (
        <div className="absolute inset-0 overflow-hidden pointer-events-none z-10">
          {particles.map((p, i) => (
            <div 
              key={i}
              className="absolute border border-white/40 rounded-full animate-float-up opacity-0"
              style={{
                left: p.left,
                bottom: '-20px', // Start below
                width: p.size,
                height: p.size,
                animationDelay: p.delay,
                animationDuration: `${5 + Math.random() * 5}s`
              }}
            />
          ))}
        </div>
      );
    case 'fantasy':
      return (
        <div className="absolute inset-0 overflow-hidden pointer-events-none z-10">
          {particles.map((p, i) => (
            <div 
              key={i}
              className="absolute bg-yellow-200 rounded-full animate-pulse-glow opacity-0"
              style={{
                left: p.left,
                top: p.top,
                width: '3px',
                height: '3px',
                animationDelay: p.delay,
                animationDuration: '2s',
                boxShadow: '0 0 6px 2px rgba(253, 224, 71, 0.6)'
              }}
            />
          ))}
        </div>
      );
    case 'jungle':
      return (
        <div className="absolute inset-0 overflow-hidden pointer-events-none z-10">
          {particles.map((p, i) => (
            <div 
              key={i}
              className="absolute bg-green-200/60 rounded-full animate-wander"
              style={{
                left: p.left,
                top: p.top,
                width: '4px',
                height: '4px',
                animationDelay: p.delay,
                animationDuration: '8s',
              }}
            />
          ))}
        </div>
      );
    case 'hero':
      return (
        <div className="absolute inset-0 overflow-hidden pointer-events-none z-10">
          <div className="absolute inset-0 bg-gradient-to-tr from-amber-500/10 to-transparent animate-pulse-slow"></div>
        </div>
      );
    default:
      return null;
  }
};

const StoryViewer: React.FC<StoryViewerProps> = ({ story, onClose, onExtend, onSaveProgress, t }) => {
  const [currentPage, setCurrentPage] = useState(story.lastReadPage || 0);
  const [isDownloading, setIsDownloading] = useState(false);
  const [downloadProgress, setDownloadProgress] = useState('');
  const [isSaving, setIsSaving] = useState(false);
  const [showExtensionInput, setShowExtensionInput] = useState(false);
  const [extensionPrompt, setExtensionPrompt] = useState('');
  const [isImageLoaded, setIsImageLoaded] = useState(false);
  
  const activeTheme = THEMES.find(t => t.id === story.theme) || THEMES[0];
  const langConfig = LANGUAGES.find(l => l.id === story.language) || LANGUAGES[0];
  
  const isRtl = story.direction === 'rtl';

  useEffect(() => {
    setIsImageLoaded(false);
    // Play sound on page turn
    playPageTurnSound();
  }, [currentPage]);

  const handleSaveProgress = () => {
    setIsSaving(true);
    if (onSaveProgress) {
      onSaveProgress(currentPage);
    }
    setTimeout(() => setIsSaving(false), 1000);
  };

  /**
   * Helper to highlight child name in text
   */
  const getHighlightedTextHTML = (text: string, childName: string, themeColor: string) => {
    if (!text) return '';
    const parts = text.split(new RegExp(`(${childName})`, 'gi'));
    return parts.map(part => {
      if (part.toLowerCase() === childName.toLowerCase()) {
        return `<span style="color: #ec4899; font-weight: bold;">${part}</span>`;
      }
      return part;
    }).join('');
  };

  /**
   * Robust PDF Generator
   * Creates a temporary DOM element, renders pages one by one, captures them, and saves.
   */
  const handleDownloadPdf = async () => {
    setIsDownloading(true);
    
    try {
      const doc = new jsPDF({
        orientation: "portrait",
        unit: "mm",
        format: "a4"
      });
      
      const pageWidth = 210;
      const pageHeight = 297;

      // Create a temporary container for rendering
      const container = document.createElement('div');
      container.style.position = 'fixed';
      container.style.top = '0';
      container.style.left = '-10000px'; // Off-screen
      container.style.width = '794px'; // ~A4 width at 96 DPI
      container.style.height = '1123px'; // ~A4 height at 96 DPI
      container.style.backgroundColor = '#ffffff';
      // Use specific fonts for PDF matching the app
      container.style.fontFamily = (langConfig.id === 'ar' || langConfig.id === 'fa') 
        ? "'Noto Naskh Arabic', serif" 
        : "'Lora', serif";
      
      document.body.appendChild(container);

      for (let i = 0; i < story.pages.length; i++) {
        setDownloadProgress(`${t.downloadingPdf} (${i + 1}/${story.pages.length})`);
        const page = story.pages[i];

        // Construct HTML for this page
        const titleHtml = `<h2 class="text-3xl font-bold mb-8 text-center" style="color: #333; margin-top: 20px;">${page.title || (i === 0 ? story.title : `${t.chapter} ${i + 1}`)}</h2>`;
        
        const textContent = getHighlightedTextHTML(page.text, story.childName, activeTheme.color);

        container.innerHTML = `
          <div style="width: 100%; height: 100%; display: flex; flex-direction: column; background-color: ${activeTheme.pageColor === 'bg-slate-50' ? '#f8fafc' : '#fffbeb'};">
            <div style="height: 55%; width: 100%; background-color: #f3f4f6; position: relative; overflow: hidden;">
              ${page.imageUrl ? `<img src="${page.imageUrl}" style="width: 100%; height: 100%; object-fit: cover;" crossorigin="anonymous" />` : ''}
            </div>
            <div style="flex: 1; padding: 40px; display: flex; flex-direction: column; align-items: center; text-align: ${isRtl ? 'right' : 'center'};" dir="${story.direction}">
              ${titleHtml}
              <p style="font-size: 24px; line-height: 2.2; color: #333;">
                ${textContent}
              </p>
              <div style="margin-top: auto; color: #9ca3af; font-weight: bold;">${i + 1}</div>
            </div>
          </div>
        `;

        // Wait for image to load if present
        const img = container.querySelector('img');
        if (img) {
          await new Promise((resolve) => {
            if (img.complete) resolve(true);
            else {
              img.onload = () => resolve(true);
              img.onerror = () => resolve(true);
            }
          });
        }

        // Capture
        const canvas = await html2canvas(container, {
          scale: 2,
          useCORS: true,
          logging: false
        });

        const imgData = canvas.toDataURL('image/jpeg', 0.8);
        
        if (i > 0) doc.addPage();
        doc.addImage(imgData, 'JPEG', 0, 0, pageWidth, pageHeight);
      }

      // Cleanup
      document.body.removeChild(container);
      
      const cleanTitle = story.title.replace(/[^a-z0-9]/gi, '_').toLowerCase();
      doc.save(`${cleanTitle}.pdf`);

    } catch (e) {
      console.error("PDF Error:", e);
      alert("Could not generate PDF. Please try again.");
    } finally {
      setIsDownloading(false);
      setDownloadProgress('');
    }
  };

  /**
   * Renders text with the child's name styled colorfully for the UI.
   */
  const renderStoryText = (text: string, childName: string) => {
    if (!text) return null;
    const parts = text.split(new RegExp(`(${childName})`, 'gi'));
    return (
      <span>
        {parts.map((part, i) => {
          if (part.toLowerCase() === childName.toLowerCase()) {
            return (
              <span 
                key={i} 
                className={`font-bold text-transparent bg-clip-text bg-gradient-to-r ${activeTheme.color}`}
              >
                {part}
              </span>
            );
          }
          return <span key={i}>{part}</span>;
        })}
      </span>
    );
  };

  const totalPages = story.pages.length;
  const activePage = story.pages[currentPage];

  return (
    <div className="fixed inset-0 z-50 bg-white flex flex-col animate-fade-in font-sans">
      <style>{`
        @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
        @keyframes scaleIn { from { transform: scale(0.9); opacity: 0; } to { transform: scale(1); opacity: 1; } }
        .animate-fade-in { animation: fadeIn 0.3s ease-out forwards; }
        .animate-scale-in { animation: scaleIn 0.3s ease-out forwards; }

        /* LTR Turn */
        @keyframes turnLtr {
          0% { transform: rotateY(-20deg); opacity: 0.5; box-shadow: inset 60px 0 60px -30px rgba(0,0,0,0.3); }
          100% { transform: rotateY(0); opacity: 1; box-shadow: inset 0 0 0 0 rgba(0,0,0,0); }
        }
        /* RTL Turn */
        @keyframes turnRtl {
          0% { transform: rotateY(20deg); opacity: 0.5; box-shadow: inset -60px 0 60px -30px rgba(0,0,0,0.3); }
          100% { transform: rotateY(0); opacity: 1; box-shadow: inset 0 0 0 0 rgba(0,0,0,0); }
        }
        .perspective-container { perspective: 1500px; }
        .animate-turn-ltr { transform-origin: left center; animation: turnLtr 0.8s cubic-bezier(0.2, 0.8, 0.2, 1) forwards; }
        .animate-turn-rtl { transform-origin: right center; animation: turnRtl 0.8s cubic-bezier(0.2, 0.8, 0.2, 1) forwards; }

        /* Ambient Effects */
        @keyframes subtleZoom {
          0% { transform: scale(1); }
          100% { transform: scale(1.1); }
        }
        .animate-subtle-zoom { animation: subtleZoom 20s ease-out forwards; }

        @keyframes twinkle {
          0%, 100% { opacity: 0.2; transform: scale(0.8); }
          50% { opacity: 1; transform: scale(1.2); }
        }
        .animate-twinkle { animation: twinkle 3s ease-in-out infinite; }

        @keyframes floatUp {
          0% { transform: translateY(0) scale(0.5); opacity: 0; }
          20% { opacity: 0.6; }
          100% { transform: translateY(-100vh) scale(1); opacity: 0; }
        }
        .animate-float-up { animation: floatUp linear infinite; }

        @keyframes pulseGlow {
          0%, 100% { opacity: 0.4; transform: scale(1); }
          50% { opacity: 1; transform: scale(1.5); }
        }
        .animate-pulse-glow { animation: pulseGlow infinite ease-in-out; }

        @keyframes wander {
          0% { transform: translate(0, 0); opacity: 0; }
          20% { opacity: 0.8; }
          80% { opacity: 0.8; }
          100% { transform: translate(30px, -50px); opacity: 0; }
        }
        .animate-wander { animation: wander infinite ease-out; }

        @keyframes pulseSlow {
          0%, 100% { opacity: 0.3; }
          50% { opacity: 0.6; }
        }
        .animate-pulse-slow { animation: pulseSlow 4s ease-in-out infinite; }
      `}</style>
      
      {/* Immersive Header */}
      <div className={`absolute top-0 left-0 right-0 p-4 z-30 flex justify-between items-center text-white bg-gradient-to-b from-black/60 to-transparent pb-16 pointer-events-none`}>
        <div className="pointer-events-auto flex gap-2">
           <button onClick={onClose} className="p-2 bg-white/20 backdrop-blur-md rounded-full hover:bg-white/30 transition-colors shadow-lg border border-white/10">
             <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
           </button>
        </div>

        <div className="pointer-events-auto flex gap-2">
          {/* Save Button */}
          {onSaveProgress && (
            <button 
              onClick={handleSaveProgress}
              className={`p-2 backdrop-blur-md rounded-full transition-all shadow-lg border border-white/10 flex items-center gap-2 ${isSaving ? 'bg-green-500/80 text-white' : 'bg-white/20 hover:bg-white/30'}`}
            >
              {isSaving ? (
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" /></svg>
              ) : (
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" /></svg>
              )}
            </button>
          )}

          {/* Download Button */}
          <button onClick={handleDownloadPdf} disabled={isDownloading} className="p-2 bg-white/20 backdrop-blur-md rounded-full hover:bg-white/30 transition-colors shadow-lg border border-white/10 flex items-center gap-2">
             {isDownloading ? (
               <>
                <div className="w-4 h-4 border-2 border-white/50 border-t-white rounded-full animate-spin"/>
                <span className="text-xs font-bold">{downloadProgress}</span>
               </>
             ) : (
               <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>
             )}
          </button>
        </div>
      </div>

      {/* Main Content Area - Book Page */}
      <div className={`flex-1 overflow-hidden flex flex-col ${activeTheme.pageColor} perspective-container relative`}>
        <div className={`absolute top-0 bottom-0 z-20 w-8 pointer-events-none ${isRtl ? 'right-0 bg-gradient-to-l' : 'left-0 bg-gradient-to-r'} from-black/10 to-transparent mix-blend-multiply`}></div>

        <div 
          key={currentPage} 
          className={`flex-1 flex flex-col h-full shadow-2xl overflow-hidden ${isRtl ? 'animate-turn-rtl' : 'animate-turn-ltr'} bg-white`}
        >
          {/* Top Half: Image */}
          <div className="h-[50vh] relative w-full bg-gray-100 flex-shrink-0 group flex items-center justify-center overflow-hidden">
            
            {/* Loading Placeholder */}
            {!isImageLoaded && (
              <div className="absolute inset-0 z-20 bg-gray-50 flex items-center justify-center">
                 {/* Themed Pulse Background */}
                 <div className={`absolute inset-0 bg-gradient-to-br ${activeTheme.color} opacity-20 animate-pulse`}></div>
                 {/* Icon */}
                 <div className="relative z-10 flex flex-col items-center animate-bounce">
                    <svg className={`w-12 h-12 ${activeTheme.textColor} opacity-60`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                    </svg>
                    <span className={`mt-3 text-xs font-bold uppercase tracking-wider ${activeTheme.textColor} opacity-70`}>{t.generating}</span>
                 </div>
              </div>
            )}

            {/* Ambient Effects Layer - Only show when loaded and not downloading PDF */}
            {isImageLoaded && !isDownloading && <ThemeEffects themeId={story.theme} />}

            {activePage.imageUrl && (
              <img 
                src={activePage.imageUrl} 
                alt="Story illustration" 
                className={`w-full h-full object-cover transition-all duration-700 ease-in-out ${isImageLoaded ? 'opacity-100 blur-0 animate-subtle-zoom' : 'opacity-0 blur-xl scale-110'}`} 
                onLoad={() => setIsImageLoaded(true)}
              />
            )}

            <div className="absolute inset-0 bg-gradient-to-b from-white/10 to-transparent opacity-50 pointer-events-none"></div>
            <div className="absolute bottom-6 left-1/2 transform -translate-x-1/2 bg-black/40 backdrop-blur-md px-4 py-1.5 rounded-full text-white text-xs font-bold tracking-wide shadow-lg border border-white/10 z-20">
              {currentPage + 1} / {totalPages}
            </div>
          </div>

          {/* Bottom Half: Text */}
          <div className="flex-1 p-6 md:p-8 relative -mt-6 bg-white rounded-t-[2.5rem] shadow-[0_-10px_40px_rgba(0,0,0,0.1)] z-10 flex flex-col min-h-0">
            <div className="w-16 h-1.5 bg-gray-200 rounded-full mx-auto mb-6 opacity-60 flex-shrink-0"></div>
            <div className="flex-1 overflow-y-auto no-scrollbar pb-12" dir={story.direction}>
              <div className="space-y-6">
                <h2 className={`text-2xl font-bold font-serif leading-tight ${activeTheme.textColor} ${story.direction === 'rtl' ? 'text-right' : 'text-left'}`}>
                  {activePage.title || (currentPage === 0 ? story.title : `${t.chapter} ${currentPage + 1}`)}
                </h2>
                <p className={`${langConfig.size} ${langConfig.lineHeight} ${langConfig.tracking} ${langConfig.font} ${activeTheme.textColor} ${story.direction === 'rtl' ? 'text-right' : 'text-left'}`}>
                  {renderStoryText(activePage.text, story.childName)}
                </p>
              </div>
              
              {currentPage === totalPages - 1 && onExtend && (
                <div className="mt-8 mb-4 flex justify-center">
                  <button 
                    onClick={() => setShowExtensionInput(true)}
                    className={`px-8 py-4 font-bold rounded-2xl transition-all flex items-center gap-3 text-white shadow-xl hover:shadow-2xl hover:scale-105 active:scale-95 ${activeTheme.accentColor}`}
                  >
                     <span className="text-xl">✨</span>
                     <span className="text-lg">{t.continueStory}</span>
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Navigation Footer */}
      <div className="p-4 bg-white/95 backdrop-blur border-t border-gray-100 flex gap-4 z-40 pb-safe">
        <button 
          onClick={() => setCurrentPage(Math.max(0, currentPage - 1))}
          disabled={currentPage === 0}
          className={`flex-1 py-4 rounded-2xl border-2 font-bold disabled:opacity-30 disabled:cursor-not-allowed hover:bg-gray-50 active:scale-[0.98] transition-all ${activeTheme.borderColor} ${activeTheme.textColor}`}
        >
          {story.direction === 'rtl' ? t.next : t.back}
        </button>
        <button 
          onClick={() => setCurrentPage(Math.min(totalPages - 1, currentPage + 1))}
          disabled={currentPage === totalPages - 1}
          className={`flex-1 py-4 rounded-2xl text-white font-bold disabled:opacity-30 disabled:cursor-not-allowed shadow-lg hover:opacity-90 active:scale-[0.98] transition-all ${activeTheme.accentColor}`}
        >
          {story.direction === 'rtl' ? t.back : t.next}
        </button>
      </div>

      {/* Extension Input Modal */}
      {showExtensionInput && (
        <div className="absolute inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4 animate-fade-in">
          <div className={`bg-white rounded-3xl shadow-2xl p-6 w-full max-w-sm border-4 animate-scale-in ${activeTheme.borderColor}`}>
             <h3 className={`font-bold text-xl mb-3 ${activeTheme.textColor}`}>{t.whatHappensNext}</h3>
             
             <div className="mb-4 text-gray-500 text-sm bg-gray-50 p-3 rounded-xl border border-gray-100">
               <p className="mb-1">💡 <span className="font-semibold">Optional:</span> Guide the adventure!</p>
               <p className="text-xs">Tell the AI what should happen, or leave it blank for a surprise.</p>
             </div>

             <textarea
               className={`w-full p-4 border rounded-xl mb-4 focus:ring-2 focus:border-transparent outline-none resize-none h-32 text-lg ${activeTheme.borderColor} ${activeTheme.textColor} ${activeTheme.pageColor}`}
               placeholder={t.customPlotPlaceholder}
               value={extensionPrompt}
               onChange={e => setExtensionPrompt(e.target.value)}
             />
             <div className="flex gap-2">
               <button onClick={() => setShowExtensionInput(false)} className="flex-1 py-3 text-gray-500 font-bold hover:bg-gray-50 rounded-xl transition-colors">{t.cancel}</button>
               <button
                 onClick={() => { if(onExtend) onExtend(story, extensionPrompt); setShowExtensionInput(false); }}
                 className={`flex-1 py-3 text-white font-bold rounded-xl shadow-lg transition-transform active:scale-95 ${activeTheme.accentColor}`}
               >
                 {t.generateExtension}
               </button>
             </div>
          </div>
        </div>
      )}

    </div>
  );
};

export default StoryViewer;