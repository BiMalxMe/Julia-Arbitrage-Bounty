import React, { useState, useEffect } from 'react';
import { Settings, Save, RefreshCw, AlertTriangle, CheckCircle } from 'lucide-react';
import { apiService } from '../services/api';

const Configuration = () => {
  const [config, setConfig] = useState(null);
  const [dynamicConfig, setDynamicConfig] = useState({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);

  useEffect(() => {
    fetchConfig();
  }, []);

  const fetchConfig = async () => {
    try {
      setLoading(true);
      setError(null);
      const configData = await apiService.getConfig();
      setConfig(configData);
      setDynamicConfig(configData.dynamic_config || {});
    } catch (err) {
      setError(err.message || 'Failed to load configuration');
    } finally {
      setLoading(false);
    }
  };

  const handleConfigChange = (key, value) => {
    setDynamicConfig(prev => ({
      ...prev,
      [key]: value
    }));
  };

  const handleSaveConfig = async () => {
    try {
      setSaving(true);
      setError(null);
      setSuccess(null);

      await apiService.updateConfig(dynamicConfig);
      setSuccess('Configuration updated successfully');
      
      // Refresh config to get updated values
      await fetchConfig();
    } catch (err) {
      setError(err.response?.data?.error || err.message || 'Failed to update configuration');
    } finally {
      setSaving(false);
    }
  };

  const resetToDefaults = () => {
    const defaults = {
      api_rate_limit: 100,
      max_concurrent_tasks: 10,
      cache_enabled: true,
      debug_mode: false
    };
    setDynamicConfig(defaults);
  };

  const renderConfigSection = (title, configData, isEditable = false) => {
    if (!configData) return null;

    return (
      <div className="bg-slate-800 rounded-lg p-6 border border-slate-700">
        <h3 className="text-lg font-semibold text-white mb-4">{title}</h3>
        <div className="space-y-4">
          {Object.entries(configData).map(([key, value]) => (
            <div key={key} className="flex items-center justify-between p-3 bg-slate-700 rounded-lg">
              <div className="flex-1">
                <div className="text-sm font-medium text-white">{key}</div>
                <div className="text-xs text-slate-400">Current value</div>
              </div>
              <div className="flex items-center space-x-3">
                {isEditable ? (
                  <input
                    type={typeof value === 'boolean' ? 'checkbox' : 'text'}
                    checked={typeof value === 'boolean' ? dynamicConfig[key] : undefined}
                    value={typeof value === 'boolean' ? undefined : dynamicConfig[key] || ''}
                    onChange={(e) => {
                      if (typeof value === 'boolean') {
                        handleConfigChange(key, e.target.checked);
                      } else {
                        handleConfigChange(key, e.target.value);
                      }
                    }}
                    className={typeof value === 'boolean' 
                      ? 'w-4 h-4 text-primary-600 bg-slate-600 border-slate-500 rounded focus:ring-primary-500'
                      : 'px-3 py-1 bg-slate-600 border border-slate-500 rounded text-white text-sm focus:outline-none focus:ring-2 focus:ring-primary-500'
                    }
                  />
                ) : (
                  <span className="text-white font-mono text-sm">{String(value)}</span>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  };

  if (loading) {
    return (
      <div className="max-w-6xl mx-auto p-6">
        <div className="flex items-center justify-center h-64">
          <div className="flex items-center space-x-3">
            <Settings className="w-6 h-6 text-primary-500 animate-spin" />
            <span className="text-white">Loading configuration...</span>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white">Configuration</h1>
          <p className="text-slate-400">Manage system settings and dynamic configuration</p>
        </div>
        <div className="flex items-center space-x-3">
          <button
            onClick={fetchConfig}
            className="px-4 py-2 bg-slate-700 hover:bg-slate-600 text-white rounded-lg transition-colors flex items-center space-x-2"
          >
            <RefreshCw className="w-4 h-4" />
            <span>Refresh</span>
          </button>
        </div>
      </div>

      {/* Error/Success Messages */}
      {error && (
        <div className="bg-danger-900 border border-danger-700 rounded-lg p-4">
          <div className="flex items-center space-x-3">
            <AlertTriangle className="w-5 h-5 text-danger-500" />
            <span className="text-danger-200">{error}</span>
          </div>
        </div>
      )}

      {success && (
        <div className="bg-success-900 border border-success-700 rounded-lg p-4">
          <div className="flex items-center space-x-3">
            <CheckCircle className="w-5 h-5 text-success-500" />
            <span className="text-success-200">{success}</span>
          </div>
        </div>
      )}

      {/* Configuration Sections */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Static Configuration */}
        {renderConfigSection('Static Configuration', config?.static_config, false)}

        {/* Dynamic Configuration */}
        <div className="space-y-4">
          {renderConfigSection('Dynamic Configuration', config?.dynamic_config, true)}
          
          {/* Action Buttons */}
          <div className="flex items-center space-x-3">
            <button
              onClick={handleSaveConfig}
              disabled={saving}
              className="px-6 py-2 bg-primary-600 hover:bg-primary-700 disabled:bg-slate-600 disabled:cursor-not-allowed text-white font-medium rounded-lg transition-colors flex items-center space-x-2"
            >
              {saving ? (
                <>
                  <RefreshCw className="w-4 h-4 animate-spin" />
                  <span>Saving...</span>
                </>
              ) : (
                <>
                  <Save className="w-4 h-4" />
                  <span>Save Changes</span>
                </>
              )}
            </button>
            
            <button
              onClick={resetToDefaults}
              className="px-4 py-2 bg-slate-700 hover:bg-slate-600 text-white rounded-lg transition-colors"
            >
              Reset to Defaults
            </button>
          </div>
        </div>
      </div>

      {/* Configuration Information */}
      <div className="bg-slate-800 rounded-lg p-6 border border-slate-700">
        <h3 className="text-lg font-semibold text-white mb-4">Configuration Information</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <h4 className="text-sm font-medium text-slate-400 mb-2">Static Configuration</h4>
            <p className="text-sm text-slate-300">
              Static configuration values are loaded from environment variables and configuration files.
              These settings require a system restart to take effect.
            </p>
          </div>
          <div>
            <h4 className="text-sm font-medium text-slate-400 mb-2">Dynamic Configuration</h4>
            <p className="text-sm text-slate-300">
              Dynamic configuration can be updated at runtime without requiring a system restart.
              Changes take effect immediately.
            </p>
          </div>
        </div>
      </div>

      {/* Configuration Details */}
      {config && (
        <div className="bg-slate-800 rounded-lg p-6 border border-slate-700">
          <h3 className="text-lg font-semibold text-white mb-4">Configuration Details</h3>
          <div className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="text-center p-4 bg-slate-700 rounded-lg">
                <div className="text-2xl font-bold text-white">
                  {Object.keys(config.static_config || {}).length}
                </div>
                <div className="text-sm text-slate-400">Static Settings</div>
              </div>
              <div className="text-center p-4 bg-slate-700 rounded-lg">
                <div className="text-2xl font-bold text-white">
                  {Object.keys(config.dynamic_config || {}).length}
                </div>
                <div className="text-sm text-slate-400">Dynamic Settings</div>
              </div>
              <div className="text-center p-4 bg-slate-700 rounded-lg">
                <div className="text-2xl font-bold text-white">
                  {config.timestamp ? new Date(config.timestamp).toLocaleString() : 'N/A'}
                </div>
                <div className="text-sm text-slate-400">Last Updated</div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Configuration;