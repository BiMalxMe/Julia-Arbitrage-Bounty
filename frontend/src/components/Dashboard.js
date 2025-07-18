import React, { useState, useEffect } from 'react';
import { BarChart3, Shield, Activity, Settings, TrendingUp, AlertTriangle, CheckCircle, Clock } from 'lucide-react';
import { apiService, formatTimestamp } from '../services/api';

const Dashboard = () => {
  const [status, setStatus] = useState(null);
  const [health, setHealth] = useState(null);
  const [swarmStatus, setSwarmStatus] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        setLoading(true);
        const [statusData, healthData, swarmData] = await Promise.all([
          apiService.getStatus(),
          apiService.getHealth(),
          apiService.getSwarmStatus()
        ]);
        
        setStatus(statusData);
        setHealth(healthData);
        setSwarmStatus(swarmData);
      } catch (err) {
        setError(err.message || 'Failed to load dashboard data');
      } finally {
        setLoading(false);
      }
    };

    fetchDashboardData();
    const interval = setInterval(fetchDashboardData, 30000);
    return () => clearInterval(interval);
  }, []);

  const getSystemHealthColor = () => {
    if (!health) return 'text-gray-400';
    return health.status === 'healthy' ? 'text-success-500' : 'text-danger-500';
  };

  const getSystemHealthIcon = () => {
    if (!health) return <Clock className="w-6 h-6" />;
    return health.status === 'healthy' ? 
      <CheckCircle className="w-6 h-6 text-success-500" /> : 
      <AlertTriangle className="w-6 h-6 text-danger-500" />;
  };

  const renderMetricCard = (title, value, icon, color = 'text-white', subtitle = '') => {
    const Icon = icon;
    return (
      <div className="bg-slate-800 rounded-lg p-6 border border-slate-700 hover:border-slate-600 transition-colors">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center space-x-3">
            <div className="p-2 bg-slate-700 rounded-lg">
              <Icon className="w-5 h-5 text-primary-400" />
            </div>
            <div>
              <h3 className="text-sm font-medium text-slate-400">{title}</h3>
              {subtitle && <p className="text-xs text-slate-500">{subtitle}</p>}
            </div>
          </div>
        </div>
        <div className={`text-2xl font-bold ${color}`}>{value}</div>
      </div>
    );
  };

  const renderQuickAction = (title, description, icon, onClick, disabled = false) => {
    const Icon = icon;
    return (
      <button
        onClick={onClick}
        disabled={disabled}
        className="w-full p-4 bg-slate-800 rounded-lg border border-slate-700 hover:border-primary-500 hover:bg-slate-700 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed text-left"
      >
        <div className="flex items-center space-x-3">
          <div className="p-2 bg-primary-600 rounded-lg">
            <Icon className="w-5 h-5 text-white" />
          </div>
          <div className="flex-1">
            <h3 className="font-medium text-white">{title}</h3>
            <p className="text-sm text-slate-400">{description}</p>
          </div>
        </div>
      </button>
    );
  };

  if (loading) {
    return (
      <div className="max-w-6xl mx-auto p-6">
        <div className="flex items-center justify-center h-64">
          <div className="flex items-center space-x-3">
            <BarChart3 className="w-6 h-6 text-primary-500 animate-spin" />
            <span className="text-white">Loading dashboard...</span>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="max-w-6xl mx-auto p-6">
        <div className="bg-danger-900 border border-danger-700 rounded-lg p-6">
          <div className="flex items-center space-x-3 mb-4">
            <AlertTriangle className="w-6 h-6 text-danger-500" />
            <h2 className="text-xl font-semibold text-white">Dashboard Error</h2>
          </div>
          <p className="text-danger-200">{error}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto p-6 space-y-6">
      {/* Welcome Header */}
      <div className="bg-gradient-to-r from-primary-900 to-primary-800 rounded-lg p-6 border border-primary-700">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-white mb-2">Welcome to ChainGuardian</h1>
            <p className="text-primary-200">
              Comprehensive Solana wallet risk analysis and monitoring platform
            </p>
          </div>
          <div className="flex items-center space-x-3">
            {getSystemHealthIcon()}
            <div>
              <div className={`text-sm font-medium ${getSystemHealthColor()}`}>
                {health?.status === 'healthy' ? 'System Healthy' : 'System Issues'}
              </div>
              <div className="text-xs text-slate-400">
                {health?.uptime || 'Uptime: N/A'}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Key Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {renderMetricCard(
          'System Status',
          health?.status || 'Unknown',
          Activity,
          health?.status === 'healthy' ? 'text-success-500' : 'text-danger-500'
        )}
        {renderMetricCard(
          'Total Requests',
          health?.total_requests || 0,
          TrendingUp,
          'text-white',
          'API requests processed'
        )}
        {renderMetricCard(
          'Active Tasks',
          health?.active_tasks || 0,
          Clock,
          'text-white',
          'Currently processing'
        )}
        {renderMetricCard(
          'Swarm Workers',
          swarmStatus?.active_workers || 0,
          Shield,
          'text-white',
          'Active workers'
        )}
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="space-y-4">
          <h2 className="text-xl font-semibold text-white">Quick Actions</h2>
          <div className="space-y-3">
            {renderQuickAction(
              'Analyze Wallet',
              'Perform comprehensive risk analysis on a Solana wallet',
              Shield,
              () => window.location.hash = '#analyze'
            )}
            {renderQuickAction(
              'System Status',
              'View detailed system health and performance metrics',
              Activity,
              () => window.location.hash = '#status'
            )}
            {renderQuickAction(
              'Configuration',
              'Manage system configuration and settings',
              Settings,
              () => window.location.hash = '#config'
            )}
          </div>
        </div>

        {/* System Overview */}
        <div className="space-y-4">
          <h2 className="text-xl font-semibold text-white">System Overview</h2>
          <div className="bg-slate-800 rounded-lg p-6 border border-slate-700">
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-slate-400">Swarm Status</span>
                <div className="flex items-center space-x-2">
                  {swarmStatus?.is_running ? 
                    <CheckCircle className="w-4 h-4 text-success-500" /> : 
                    <AlertTriangle className="w-4 h-4 text-danger-500" />
                  }
                  <span className={swarmStatus?.is_running ? 'text-success-500' : 'text-danger-500'}>
                    {swarmStatus?.is_running ? 'Running' : 'Stopped'}
                  </span>
                </div>
              </div>
              
              <div className="flex items-center justify-between">
                <span className="text-slate-400">Active Workers</span>
                <span className="text-white">{swarmStatus?.active_workers || 0} / {swarmStatus?.total_workers || 0}</span>
              </div>
              
              <div className="flex items-center justify-between">
                <span className="text-slate-400">Queued Tasks</span>
                <span className="text-white">{swarmStatus?.queued_tasks || 0}</span>
              </div>
              
              <div className="flex items-center justify-between">
                <span className="text-slate-400">Completed Tasks</span>
                <span className="text-white">{swarmStatus?.completed_tasks || 0}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Recent Activity */}
      <div className="bg-slate-800 rounded-lg p-6 border border-slate-700">
        <h2 className="text-xl font-semibold text-white mb-4">Recent Activity</h2>
        <div className="space-y-3">
          <div className="flex items-center justify-between p-3 bg-slate-700 rounded-lg">
            <div className="flex items-center space-x-3">
              <div className="w-2 h-2 bg-success-500 rounded-full"></div>
              <span className="text-white">System started successfully</span>
            </div>
            <span className="text-sm text-slate-400">
              {status?.timestamp ? formatTimestamp(status.timestamp) : 'N/A'}
            </span>
          </div>
          
          <div className="flex items-center justify-between p-3 bg-slate-700 rounded-lg">
            <div className="flex items-center space-x-3">
              <div className="w-2 h-2 bg-primary-500 rounded-full"></div>
              <span className="text-white">API server running on port {status?.config?.service_port || '8080'}</span>
            </div>
            <span className="text-sm text-slate-400">Active</span>
          </div>
          
          <div className="flex items-center justify-between p-3 bg-slate-700 rounded-lg">
            <div className="flex items-center space-x-3">
              <div className="w-2 h-2 bg-warning-500 rounded-full"></div>
              <span className="text-white">Swarm coordinator initialized</span>
            </div>
            <span className="text-sm text-slate-400">
              {swarmStatus?.active_workers || 0} workers active
            </span>
          </div>
        </div>
      </div>

      {/* Agent Capabilities */}
      {status?.agent?.capabilities && (
        <div className="bg-slate-800 rounded-lg p-6 border border-slate-700">
          <h2 className="text-xl font-semibold text-white mb-4">Available Capabilities</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
            {status.agent.capabilities.map((capability, index) => (
              <div key={index} className="flex items-center space-x-2 p-3 bg-slate-700 rounded-lg">
                <CheckCircle className="w-4 h-4 text-success-500" />
                <span className="text-white text-sm">{capability.replace(/_/g, ' ')}</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default Dashboard;