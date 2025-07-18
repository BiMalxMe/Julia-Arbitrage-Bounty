import React, { useState, useEffect } from 'react';
import { Activity, Server, Settings, Database, Cpu, Clock, CheckCircle, XCircle, AlertTriangle } from 'lucide-react';
import { apiService, formatTimestamp } from '../services/api';

const SystemStatus = () => {
  const [status, setStatus] = useState(null);
  const [health, setHealth] = useState(null);
  const [swarmStatus, setSwarmStatus] = useState(null);
  const [config, setConfig] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [lastUpdated, setLastUpdated] = useState(null);

  const fetchAllData = async () => {
    try {
      setLoading(true);
      setError(null);

      const [statusData, healthData, swarmData, configData] = await Promise.all([
        apiService.getStatus(),
        apiService.getHealth(),
        apiService.getSwarmStatus(),
        apiService.getConfig()
      ]);

      setStatus(statusData);
      setHealth(healthData);
      setSwarmStatus(swarmData);
      setConfig(configData);
      setLastUpdated(new Date());
    } catch (err) {
      setError(err.message || 'Failed to fetch system status');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAllData();
    
    // Refresh every 30 seconds
    const interval = setInterval(fetchAllData, 30000);
    return () => clearInterval(interval);
  }, []);

  const getStatusIcon = (isHealthy) => {
    return isHealthy ? (
      <CheckCircle className="w-5 h-5 text-success-500" />
    ) : (
      <XCircle className="w-5 h-5 text-danger-500" />
    );
  };

  const getStatusColor = (isHealthy) => {
    return isHealthy ? 'text-success-500' : 'text-danger-500';
  };

  const getStatusBadge = (isHealthy) => {
    return isHealthy ? (
      <span className="px-2 py-1 bg-success-100 text-success-800 text-xs font-medium rounded-full">
        Healthy
      </span>
    ) : (
      <span className="px-2 py-1 bg-danger-100 text-danger-800 text-xs font-medium rounded-full">
        Unhealthy
      </span>
    );
  };

  const renderMetricCard = (title, value, icon, color = 'text-white') => {
    const Icon = icon;
    return (
      <div className="bg-slate-800 rounded-lg p-4 border border-slate-700">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm text-slate-400">{title}</p>
            <p className={`text-xl font-semibold ${color}`}>{value}</p>
          </div>
          <Icon className="w-8 h-8 text-slate-500" />
        </div>
      </div>
    );
  };

  const renderConfigSection = () => {
    if (!config) return null;

    return (
      <div className="bg-slate-800 rounded-lg p-6 border border-slate-700">
        <h3 className="text-lg font-semibold text-white mb-4 flex items-center space-x-2">
          <Settings className="w-5 h-5" />
          <span>Configuration</span>
        </h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <h4 className="text-sm font-medium text-slate-400 mb-2">Static Configuration</h4>
            <div className="space-y-2">
              {Object.entries(config.static_config || {}).map(([key, value]) => (
                <div key={key} className="flex justify-between text-sm">
                  <span className="text-slate-400">{key}:</span>
                  <span className="text-white font-mono">{String(value)}</span>
                </div>
              ))}
            </div>
          </div>
          
          <div>
            <h4 className="text-sm font-medium text-slate-400 mb-2">Dynamic Configuration</h4>
            <div className="space-y-2">
              {Object.entries(config.dynamic_config || {}).map(([key, value]) => (
                <div key={key} className="flex justify-between text-sm">
                  <span className="text-slate-400">{key}:</span>
                  <span className="text-white font-mono">{String(value)}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  };

  if (loading) {
    return (
      <div className="max-w-6xl mx-auto p-6">
        <div className="flex items-center justify-center h-64">
          <div className="flex items-center space-x-3">
            <Activity className="w-6 h-6 text-primary-500 animate-spin" />
            <span className="text-white">Loading system status...</span>
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
            <XCircle className="w-6 h-6 text-danger-500" />
            <h2 className="text-xl font-semibold text-white">Connection Error</h2>
          </div>
          <p className="text-danger-200 mb-4">{error}</p>
          <button
            onClick={fetchAllData}
            className="px-4 py-2 bg-danger-600 hover:bg-danger-700 text-white rounded-lg transition-colors"
          >
            Retry Connection
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white">System Status</h1>
          <p className="text-slate-400">Monitor ChainGuardian backend health and performance</p>
        </div>
        <div className="flex items-center space-x-3">
          <button
            onClick={fetchAllData}
            className="px-4 py-2 bg-primary-600 hover:bg-primary-700 text-white rounded-lg transition-colors flex items-center space-x-2"
          >
            <Activity className="w-4 h-4" />
            <span>Refresh</span>
          </button>
          {lastUpdated && (
            <div className="text-sm text-slate-400">
              Last updated: {formatTimestamp(lastUpdated)}
            </div>
          )}
        </div>
      </div>

      {/* System Health Overview */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {renderMetricCard(
          'System Status',
          health?.status || 'Unknown',
          Activity,
          health?.status === 'healthy' ? 'text-success-500' : 'text-danger-500'
        )}
        {renderMetricCard(
          'Uptime',
          health?.uptime || 'N/A',
          Clock,
          'text-white'
        )}
        {renderMetricCard(
          'Total Requests',
          health?.total_requests || 0,
          Server,
          'text-white'
        )}
        {renderMetricCard(
          'Active Tasks',
          health?.active_tasks || 0,
          Cpu,
          'text-white'
        )}
      </div>

      {/* Detailed Status Cards */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* System Health */}
        <div className="bg-slate-800 rounded-lg p-6 border border-slate-700">
          <h3 className="text-lg font-semibold text-white mb-4 flex items-center space-x-2">
            <Activity className="w-5 h-5" />
            <span>System Health</span>
          </h3>
          
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-slate-400">Overall Status</span>
              <div className="flex items-center space-x-2">
                {getStatusIcon(health?.status === 'healthy')}
                {getStatusBadge(health?.status === 'healthy')}
              </div>
            </div>
            
            <div className="flex items-center justify-between">
              <span className="text-slate-400">System Running</span>
              <div className="flex items-center space-x-2">
                {getStatusIcon(health?.system_running)}
                <span className={getStatusColor(health?.system_running)}>
                  {health?.system_running ? 'Yes' : 'No'}
                </span>
              </div>
            </div>
            
            <div className="flex items-center justify-between">
              <span className="text-slate-400">Swarm Healthy</span>
              <div className="flex items-center space-x-2">
                {getStatusIcon(health?.swarm_healthy)}
                <span className={getStatusColor(health?.swarm_healthy)}>
                  {health?.swarm_healthy ? 'Yes' : 'No'}
                </span>
              </div>
            </div>
            
            <div className="flex items-center justify-between">
              <span className="text-slate-400">Version</span>
              <span className="text-white font-mono">{health?.version || 'Unknown'}</span>
            </div>
          </div>
        </div>

        {/* Swarm Status */}
        <div className="bg-slate-800 rounded-lg p-6 border border-slate-700">
          <h3 className="text-lg font-semibold text-white mb-4 flex items-center space-x-2">
            <Database className="w-5 h-5" />
            <span>Swarm Status</span>
          </h3>
          
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-slate-400">Swarm Running</span>
              <div className="flex items-center space-x-2">
                {getStatusIcon(swarmStatus?.is_running)}
                <span className={getStatusColor(swarmStatus?.is_running)}>
                  {swarmStatus?.is_running ? 'Yes' : 'No'}
                </span>
              </div>
            </div>
            
            <div className="flex items-center justify-between">
              <span className="text-slate-400">Active Workers</span>
              <span className="text-white">{swarmStatus?.active_workers || 0}</span>
            </div>
            
            <div className="flex items-center justify-between">
              <span className="text-slate-400">Total Workers</span>
              <span className="text-white">{swarmStatus?.total_workers || 0}</span>
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

      {/* Configuration */}
      {renderConfigSection()}

      {/* Agent Information */}
      {status?.agent && (
        <div className="bg-slate-800 rounded-lg p-6 border border-slate-700">
          <h3 className="text-lg font-semibold text-white mb-4">Agent Information</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <h4 className="text-sm font-medium text-slate-400 mb-2">Details</h4>
              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-slate-400">Name:</span>
                  <span className="text-white">{status.agent.name}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-slate-400">Version:</span>
                  <span className="text-white">{status.agent.version}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-slate-400">License:</span>
                  <span className="text-white">{status.agent.license}</span>
                </div>
              </div>
            </div>
            <div>
              <h4 className="text-sm font-medium text-slate-400 mb-2">Capabilities</h4>
              <div className="flex flex-wrap gap-2">
                {status.agent.capabilities?.map((capability, index) => (
                  <span
                    key={index}
                    className="px-2 py-1 bg-primary-100 text-primary-800 text-xs rounded-full"
                  >
                    {capability}
                  </span>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default SystemStatus;