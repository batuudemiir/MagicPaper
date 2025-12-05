
import React from 'react';

interface InfoViewProps {
  title: string;
  content: string;
  onBack: () => void;
}

const InfoView: React.FC<InfoViewProps> = ({ title, content, onBack }) => {
  return (
    <div className="flex flex-col h-full bg-white rounded-3xl overflow-hidden shadow-sm border border-gray-100 animate-fade-in">
      {/* Header */}
      <div className="p-4 border-b border-gray-100 flex items-center gap-3 bg-gray-50/50">
        <button 
          onClick={onBack}
          className="p-2 -ml-2 rounded-full hover:bg-gray-100 transition-colors"
        >
          <svg className="w-6 h-6 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
        </button>
        <h2 className="text-xl font-bold text-gray-800">{title}</h2>
      </div>
      
      {/* Scrollable Content */}
      <div className="flex-1 overflow-y-auto p-6">
        <div className="prose prose-indigo max-w-none">
          {content.split('\n').map((paragraph, index) => (
             paragraph.trim() ? (
               <p key={index} className="mb-4 text-gray-600 leading-relaxed">
                 {paragraph}
               </p>
             ) : <br key={index} />
          ))}
        </div>
        
        {/* Placeholder Button for Restore Purchases */}
        {title.includes('Restore') && (
           <div className="mt-8 text-center">
             <button 
               onClick={() => alert("Checking for purchases...")}
               className="px-6 py-3 bg-indigo-600 text-white font-bold rounded-xl shadow-lg active:scale-95 transition-transform"
             >
               Restore Now
             </button>
           </div>
        )}
      </div>
      
      <style>{`
        .animate-fade-in { animation: fadeIn 0.3s ease-out forwards; }
        @keyframes fadeIn { from { opacity: 0; transform: translateX(10px); } to { opacity: 1; transform: translateX(0); } }
      `}</style>
    </div>
  );
};

export default InfoView;
