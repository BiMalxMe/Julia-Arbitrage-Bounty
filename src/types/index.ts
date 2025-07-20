export interface NFTCollection {
  name: string;
  address: string;
  description?: string;
  image?: string;
  floor_price: number;
  market_cap?: number;
  volume_24h?: number;
  total_supply?: number;
}

export interface PredictionTimeframe {
  direction: 'up' | 'down' | 'stable';
  percentage_change: number;
  confidence: number;
  price_target?: number;
}

export interface Prediction {
  '24h': PredictionTimeframe;
  '7d': PredictionTimeframe;
  '30d': PredictionTimeframe;
}

export interface AIReasoningStep {
  factor: string;
  impact: 'positive' | 'negative' | 'neutral';
  confidence: number;
  explanation: string;
}

export interface PredictionResponse {
  success: boolean;
  data: {
    collection: NFTCollection;
    predictions: Prediction;
    ai_reasoning: string;
    reasoning_steps: AIReasoningStep[];
    risk_factors: string[];
    market_sentiment: 'bullish' | 'bearish' | 'neutral';
    confidence_score: number;
    data_quality: number;
  };
  timestamp: string;
  processing_time: number;
}

export interface SearchResult {
  name: string;
  address: string;
  image?: string;
  floor_price?: number;
}

export interface AgentStatus {
  name: string;
  status: 'active' | 'inactive' | 'error';
  last_update: string;
  performance_score: number;
}

export interface MarketData {
  labels: string[];
  prices: number[];
  volumes: number[];
  predictions?: {
    prices: number[];
    confidence_bands: number[][];
  };
}