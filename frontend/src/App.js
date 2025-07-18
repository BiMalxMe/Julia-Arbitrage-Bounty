import React, { useState, useEffect } from 'react';
import Header from './components/Header';
import Dashboard from './components/Dashboard';
import WalletAnalyzer from './components/WalletAnalyzer';
import SystemStatus from './components/SystemStatus';
import Configuration from './components/Configuration';

function App() {
  const [activeTab, setActiveTab] = useState('dashboard');

  // Handle hash-based navigation
  useEffect(() => {
    const handleHashChange = () => {
      const hash = window.location.hash.slice(1);
      if (hash && ['dashboard', 'analyze', 'status', 'config'].includes(hash)) {
        setActiveTab(hash);
      }
    };

    // Set initial tab based on hash
    handleHashChange();

    // Listen for hash changes
    window.addEventListener('hashchange', handleHashChange);
    return () => window.removeEventListener('hashchange', handleHashChange);
  }, []);

  const handleTabChange = (tab) => {
    setActiveTab(tab);
    window.location.hash = tab;
  };

  const renderActiveComponent = () => {
    switch (activeTab) {
      case 'dashboard':
        return <Dashboard />;
      case 'analyze':
        return <WalletAnalyzer />;
      case 'status':
        return <SystemStatus />;
      case 'config':
        return <Configuration />;
      default:
        return <Dashboard />;
    }
  };

  return (
    <div className="min-h-screen bg-slate-900">
      <Header activeTab={activeTab} onTabChange={handleTabChange} />
      <main className="flex-1">
        {renderActiveComponent()}
      </main>
    </div>
  );
}

export default App;