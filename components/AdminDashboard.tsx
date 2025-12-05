

import React, { useState, useEffect } from 'react';
import { Story, UIStringMap, Tab } from '../types';
import { getAllStories } from '../utils/storage';

interface AdminDashboardProps {
  onNavigate: (tab: Tab) => void;
  t: UIStringMap;
}

interface Stats {
  totalStories: number;
  totalPages: number;
  avgPages: number;
  storageEstimateMB: string;
  topTheme: string;
  themeCounts: Record<string, number>;
}

const AdminDashboard: React.FC<AdminDashboardProps> = ({ onNavigate, t }) => {
  const [stats, setStats] = useState<Stats | null>(null);
  const [recentStories, setRecentStories] = useState<Story[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const loadStats = async () => {
      try {
        const stories = await getAllStories();
        setRecentStories(stories.slice(0, 5));

        const totalStories = stories.length;
        const totalPages = stories.reduce((acc, story) => acc + story.pages.length, 0);
        const avgPages = totalStories > 0 ? (totalPages / totalStories).toFixed(1) : 0;

        // Estimate Storage (very rough char count * 2 bytes)
        const jsonString = JSON.stringify(stories);
        const bytes = jsonString.length * 2; // UTF-16 approximate
        const mb = (bytes / (1024 * 1024)).toFixed(2);

        // Theme Popularity
        const themeCounts: Record<string, number> = {};
        stories.forEach(s => {
          themeCounts[s.theme] = (themeCounts[s.theme] || 0) + 1;
        });

        const topThemeEntry = Object.entries(themeCounts).sort((a, b) => b[1] - a[1])[0];
        const topTheme = topThemeEntry ? topThemeEntry[0] : '-';

        setStats({
          totalStories,
          totalPages,
          avgPages: Number(avgPages),
          storageEstimateMB: mb,
          topTheme,
          themeCounts
        });
      } catch (e) {
        console.error("Failed to load admin stats", e);
      } finally {
        setIsLoading(false);
      }
    };
    loadStats();
  }, []);

  const handleDeleteAll = async () => {
    if (confirm("WARNING: This will delete ALL stories on this device. Cannot be undone. Continue?")) {
      // Direct indexedDB deletion would be needed here, but standard deleteStory is by ID
      // For safety, we won't implement full nuke here without direct access, 
      // but showing intent.
      alert("Feature disabled for safety. Please delete stories individually in Library.");
    }
  }

  if (isLoading) {
    return <div className="p-8 text-center">{t.generating}</div>;
  }

  return (
    <div className="pb-24 animate-fade-in">
      {/* Header */}
      <div className="flex items-center gap-4 mb-6">
        <button 
          onClick={() => onNavigate('settings')}
          className="p-2 bg-gray-100 rounded-full hover:bg-gray-200"
        >
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" /></svg>
        </button>
        <h1 className="text-2xl font-bold">{t.adminPanel}</h1>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-2 gap-4 mb-8">
        <div className="bg-white p-4 rounded-2xl shadow-sm border border-gray-100">
          <div className="text-gray-500 text-xs font-bold uppercase mb-1">{t.totalStories}</div>
          <div className="text-3xl font-bold text-indigo-600">{stats?.totalStories}</div>
        </div>
        <div className="bg-white p-4 rounded-2xl shadow-sm border border-gray-100">
          <div className="text-gray-500 text-xs font-bold uppercase mb-1">{t.totalPages}</div>
          <div className="text-3xl font-bold text-purple-600">{stats?.totalPages}</div>
        </div>
        <div className="bg-white p-4 rounded-2xl shadow-sm border border-gray-100">
          <div className="text-gray-500 text-xs font-bold uppercase mb-1">{t.storageUsed}</div>
          <div className="text-3xl font-bold text-emerald-600">{stats?.storageEstimateMB} MB</div>
        </div>
        <div className="bg-white p-4 rounded-2xl shadow-sm border border-gray-100">
          <div className="text-gray-500 text-xs font-bold uppercase mb-1">{t.avgPagesPerStory}</div>
          <div className="text-3xl font-bold text-amber-600">{stats?.avgPages}</div>
        </div>
      </div>

      {/* Theme Chart */}
      <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 mb-8">
        <h3 className="font-bold text-gray-800 mb-4">{t.topThemes}</h3>
        <div className="space-y-3">
          {stats?.themeCounts && Object.entries(stats.themeCounts)
            .sort((a, b) => b[1] - a[1])
            .map(([theme, count]) => {
              const percentage = (count / stats.totalStories) * 100;
              return (
                <div key={theme}>
                  <div className="flex justify-between text-sm mb-1">
                    <span className="capitalize font-medium text-gray-700">{theme}</span>
                    <span className="text-gray-500">{count}</span>
                  </div>
                  <div className="w-full bg-gray-100 rounded-full h-2">
                    <div 
                      className="bg-indigo-500 h-2 rounded-full" 
                      style={{ width: `${percentage}%` }}
                    />
                  </div>
                </div>
              );
            })}
        </div>
      </div>

      {/* Recent Activity */}
      <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
        <h3 className="font-bold text-gray-800 mb-4">{t.recentStories}</h3>
        <div className="divide-y divide-gray-100">
          {recentStories.map(story => (
            <div key={story.id} className="py-3 flex justify-between items-center">
              <div>
                <div className="font-bold text-sm text-gray-800">{story.title}</div>
                <div className="text-xs text-gray-500">{new Date(story.createdAt).toLocaleString()}</div>
              </div>
              <div className="text-xs bg-gray-100 px-2 py-1 rounded text-gray-600">
                {story.pages.length} p
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="mt-8">
        <button 
          onClick={handleDeleteAll}
          className="w-full py-4 bg-red-50 text-red-600 font-bold rounded-2xl hover:bg-red-100 transition-colors"
        >
          {t.resetApp}
        </button>
      </div>

      <style>{`
        .animate-fade-in { animation: fadeIn 0.3s ease-out forwards; }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
      `}</style>
    </div>
  );
};

export default AdminDashboard;