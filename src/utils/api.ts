import axios from 'axios';
import { PredictionResponse, SearchResult, AgentStatus, MarketData } from '../types';

const API_BASE_URL = import.meta.env.VITE_BACKEND_URL || 'http://localhost:3001/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor for logging
api.interceptors.request.use((config) => {
  console.log(`Making request to: ${config.method?.toUpperCase()} ${config.url}`);
  return config;
});

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error.response?.data || error.message);
    throw error;
  }
);

export const nftApi = {
  // Main prediction endpoint
  async predictPrice(collectionAddress: string): Promise<PredictionResponse> {
    const response = await api.post<PredictionResponse>('/predict', {
      collection_address: collectionAddress,
    });
    return response.data;
  },

  // Search collections
  async searchCollections(query: string): Promise<SearchResult[]> {
    const response = await api.get<SearchResult[]>(`/collections/search?q=${encodeURIComponent(query)}`);
    return response.data;
  },

  // Get collection history
  async getCollectionHistory(address: string): Promise<MarketData> {
    const response = await api.get<MarketData>(`/collection/${address}/history`);
    return response.data;
  },

  // Agent health check
  async getAgentStatus(): Promise<AgentStatus[]> {
    const response = await api.get<AgentStatus[]>('/health');
    return response.data;
  },

  // Get API status and configuration
  async getApiStatus() {
    const response = await api.get('/status');
    return response.data;
  },

  // Get available providers
  async getProviders() {
    const response = await api.get('/providers');
    return response.data;
  }
};

export default api;