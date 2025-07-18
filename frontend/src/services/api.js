import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8080';

// Create axios instance with default configuration
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor for logging
api.interceptors.request.use(
  (config) => {
    console.log(`API Request: ${config.method?.toUpperCase()} ${config.url}`);
    return config;
  },
  (error) => {
    console.error('API Request Error:', error);
    return Promise.reject(error);
  }
);

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => {
    console.log(`API Response: ${response.status} ${response.config.url}`);
    return response;
  },
  (error) => {
    console.error('API Response Error:', error);
    return Promise.reject(error);
  }
);

// API Service functions
export const apiService = {
  // System status and health
  getStatus: async () => {
    const response = await api.get('/status');
    return response.data;
  },

  getHealth: async () => {
    const response = await api.get('/health');
    return response.data;
  },

  getConfig: async () => {
    const response = await api.get('/config');
    return response.data;
  },

  updateConfig: async (config) => {
    const response = await api.put('/config', config);
    return response.data;
  },

  // Swarm status
  getSwarmStatus: async () => {
    const response = await api.get('/swarm/status');
    return response.data;
  },

  // Risk analysis
  analyzeWallet: async (walletAddress, options = {}) => {
    const response = await api.get(`/risk/${walletAddress}`, { params: options });
    return response.data;
  },

  analyzeWalletPost: async (data) => {
    const response = await api.post('/risk/analyze', data);
    return response.data;
  },

  // Swarm tasks
  submitSwarmTask: async (taskData) => {
    const response = await api.post('/swarm/submit', taskData);
    return response.data;
  },

  getTaskStatus: async (taskId) => {
    const response = await api.get(`/task/${taskId}`);
    return response.data;
  },

  // Poll task status until completion
  pollTaskStatus: async (taskId, maxAttempts = 60, interval = 1000) => {
    for (let attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        const status = await apiService.getTaskStatus(taskId);
        
        if (status.status === 'completed' || status.status === 'failed') {
          return status;
        }
        
        // Wait before next poll
        await new Promise(resolve => setTimeout(resolve, interval));
      } catch (error) {
        console.error(`Error polling task ${taskId}:`, error);
        if (attempt === maxAttempts - 1) {
          throw error;
        }
      }
    }
    
    throw new Error(`Task ${taskId} timed out after ${maxAttempts} attempts`);
  },
};

// Utility functions
export const formatWalletAddress = (address) => {
  if (!address) return '';
  if (address.length <= 12) return address;
  return `${address.slice(0, 6)}...${address.slice(-6)}`;
};

export const getRiskColor = (riskLevel) => {
  switch (riskLevel?.toLowerCase()) {
    case 'low':
      return 'text-success-500';
    case 'medium':
      return 'text-warning-500';
    case 'high':
      return 'text-danger-500';
    case 'critical':
      return 'text-danger-600';
    default:
      return 'text-gray-400';
  }
};

export const getRiskBadgeColor = (riskLevel) => {
  switch (riskLevel?.toLowerCase()) {
    case 'low':
      return 'bg-success-100 text-success-800 border-success-200';
    case 'medium':
      return 'bg-warning-100 text-warning-800 border-warning-200';
    case 'high':
      return 'bg-danger-100 text-danger-800 border-danger-200';
    case 'critical':
      return 'bg-danger-200 text-danger-900 border-danger-300';
    default:
      return 'bg-gray-100 text-gray-800 border-gray-200';
  }
};

export const formatTimestamp = (timestamp) => {
  if (!timestamp) return 'N/A';
  try {
    return new Date(timestamp).toLocaleString();
  } catch (error) {
    return timestamp;
  }
};

export const formatNumber = (number, decimals = 2) => {
  if (number === null || number === undefined) return 'N/A';
  return Number(number).toLocaleString(undefined, {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  });
};

export default api;