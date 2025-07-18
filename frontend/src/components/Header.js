import React from 'react';
import { Shield, Activity, Settings, BarChart3 } from 'lucide-react';

const Header = ({ activeTab, onTabChange }) => {
  const tabs = [
    { id: 'dashboard', label: 'Dashboard', icon: BarChart3 },
    { id: 'analyze', label: 'Analyze Wallet', icon: Shield },
    { id: 'status', label: 'System Status', icon: Activity },
    { id: 'config', label: 'Configuration', icon: Settings },
  ];

  return (
    <header className="bg-slate-900 border-b border-slate-700">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo and Title */}
          <div className="flex items-center space-x-3">
            <div className="flex items-center justify-center w-10 h-10 bg-primary-600 rounded-lg">
              <Shield className="w-6 h-6 text-white" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-white">ChainGuardian</h1>
              <p className="text-xs text-slate-400">Solana Wallet Risk Analysis</p>
            </div>
          </div>

          {/* Navigation Tabs */}
          <nav className="flex space-x-1">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              const isActive = activeTab === tab.id;
              
              return (
                <button
                  key={tab.id}
                  onClick={() => onTabChange(tab.id)}
                  className={`flex items-center space-x-2 px-4 py-2 rounded-lg text-sm font-medium transition-colors duration-200 ${
                    isActive
                      ? 'bg-primary-600 text-white shadow-lg'
                      : 'text-slate-300 hover:text-white hover:bg-slate-800'
                  }`}
                >
                  <Icon className="w-4 h-4" />
                  <span>{tab.label}</span>
                </button>
              );
            })}
          </nav>

          {/* Version Badge */}
          <div className="flex items-center space-x-2">
            <div className="px-3 py-1 bg-slate-800 rounded-full">
              <span className="text-xs text-slate-300">v2.0.0</span>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;