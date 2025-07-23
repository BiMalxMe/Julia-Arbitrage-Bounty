import axios from 'axios';
import { PredictionResponse, NFTCollection, AgentStatus, MarketData } from '../types';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

const apiClient = axios.create({
  baseURL: API_URL,
});

// Request interceptor for logging
apiClient.interceptors.request.use((config) => {
  console.log(`Making request to: ${config.method?.toUpperCase()} ${config.url}`);
  return config;
});

// Response interceptor for error handling
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error.response?.data || error.message);
    throw error;
  }
);

export const nftApi = {
  predictPrice: async (collection_address: string): Promise<PredictionResponse> => {
    const response = await apiClient.post('/predict', { collection_address });
    return response.data;
  },

  searchCollections: async (query: string): Promise<NFTCollection[]> => {
    const response = await apiClient.get<NFTCollection[]>('/search', { params: { q: query } });
    return response.data;
  },

  // Agent health check
  async getAgentStatus(): Promise<AgentStatus[]> {
    const response = await apiClient.get<AgentStatus[]>('/health');
    return response.data;
  },

  // Get API status and configuration
  async getApiStatus() {
    const response = await apiClient.get('/status');
    return response.data;
  },

  // Get available providers
  async getProviders() {
    const response = await apiClient.get('/providers');
    return response.data;
  },

  // Fetch OpenSea stats by slug
  async getOpenSeaStats(slug: string) {
    try {
      const response = await apiClient.get(`/opensea-stats/${slug}`);
      return response.data;
    } catch (error) {
      // Error is already logged by interceptor
      throw error;
    }
  }
};

export default apiClient;