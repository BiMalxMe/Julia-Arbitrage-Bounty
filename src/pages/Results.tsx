import React, { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { useLocation, useNavigate } from 'react-router-dom';
import { ArrowLeft, ExternalLink, Loader2, RefreshCw } from 'lucide-react';
import { PredictionResponse, MarketData } from '../types';
import { PredictionCard } from '../components/PredictionCard';
import { AIReasoningDisplay } from '../components/AIReasoningDisplay';
import { LoadingSpinner } from '../components/LoadingSpinner';
import { nftApi } from '../utils/api';

export const Results: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const [prediction, setPrediction] = useState<PredictionResponse | null>(
    location.state?.prediction || null
  );
  const [marketData, setMarketData] = useState<MarketData | null>(null);
  const [loading, setLoading] = useState(false);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    if (!prediction) {
      navigate('/');
    }
  }, [prediction, navigate]);

  const handleRefresh = async () => {
    if (!prediction?.data.collection.address) return;

    setRefreshing(true);
    try {
      const newPrediction = await nftApi.predictPrice(prediction.data.collection.address);
      setPrediction(newPrediction);
    } catch (error) {
      console.error('Failed to refresh prediction:', error);
    } finally {
      setRefreshing(false);
    }
  };

  if (!prediction) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900">
        <LoadingSpinner message="Loading prediction results..." />
      </div>
    );
  }

  const { collection, predictions, ai_reasoning, reasoning_steps, risk_factors, market_sentiment, confidence_score } = prediction.data;

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900">
      {/* Header */}
      <motion.header
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="container mx-auto px-6 py-6"
      >
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <motion.button
              onClick={() => navigate('/')}
              className="flex items-center space-x-2 text-gray-400 hover:text-white transition-colors duration-200"
              whileHover={{ x: -2 }}
            >
              <ArrowLeft className="w-5 h-5" />
              <span>Back to Search</span>
            </motion.button>
          </div>
          <motion.button
            onClick={handleRefresh}
            disabled={refreshing}
            className="flex items-center space-x-2 bg-gray-800 hover:bg-gray-700 text-gray-300 px-4 py-2 rounded-lg border border-gray-600 transition-all duration-200"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            {refreshing ? (
              <Loader2 className="w-4 h-4 animate-spin" />
            ) : (
              <RefreshCw className="w-4 h-4" />
            )}
            <span>Refresh</span>
          </motion.button>
        </div>
      </motion.header>

      <div className="container mx-auto px-6 pb-12">
        {/* Collection Info */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-gray-800 rounded-xl border border-gray-700 p-6 mb-8"
        >
          <div className="flex items-start space-x-6">
            {collection.image && (
              <div className="w-20 h-20 rounded-lg overflow-hidden bg-gray-700">
                <img
                  src={collection.image}
                  alt={collection.name}
                  className="w-full h-full object-cover"
                />
              </div>
            )}
            <div className="flex-1">
              <div className="flex items-center justify-between mb-2">
                <h1 className="text-2xl font-bold text-white">{collection.name}</h1>
                <a
                  href={`https://opensea.io/collection/${collection.address}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center space-x-1 text-emerald-400 hover:text-emerald-300 transition-colors duration-200"
                >
                  <span className="text-sm">View on OpenSea</span>
                  <ExternalLink className="w-4 h-4" />
                </a>
              </div>
              <p className="text-gray-400 text-sm font-mono mb-4">
                {collection.address.slice(0, 10)}...{collection.address.slice(-8)}
              </p>
              {collection.description && (
                <p className="text-gray-300 text-sm mb-4">{collection.description}</p>
              )}
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div>
                  <div className="text-lg font-bold text-emerald-400">{collection.floor_price} ETH</div>
                  <div className="text-xs text-gray-500">Floor Price</div>
                </div>
                {collection.volume_24h && (
                  <div>
                    <div className="text-lg font-bold text-purple-400">{collection.volume_24h} ETH</div>
                    <div className="text-xs text-gray-500">24h Volume</div>
                  </div>
                )}
                {collection.market_cap && (
                  <div>
                    <div className="text-lg font-bold text-orange-400">{(collection.market_cap / 1000).toFixed(1)}K ETH</div>
                    <div className="text-xs text-gray-500">Market Cap</div>
                  </div>
                )}
                {collection.total_supply && (
                  <div>
                    <div className="text-lg font-bold text-blue-400">{collection.total_supply.toLocaleString()}</div>
                    <div className="text-xs text-gray-500">Total Supply</div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </motion.div>

        {/* Results Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div className="space-y-8">
            <PredictionCard
              predictions={predictions}
              confidence={confidence_score}
              timestamp={prediction.timestamp}
              processingTime={prediction.processing_time}
            />
          </div>
          
          <div className="space-y-8">
            <AIReasoningDisplay
              reasoning={ai_reasoning}
              reasoningSteps={reasoning_steps}
              marketSentiment={market_sentiment}
              riskFactors={risk_factors}
            />
          </div>
        </div>

        {/* Disclaimer */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="mt-12 p-6 bg-yellow-500/10 border border-yellow-500/30 rounded-xl"
        >
          <h4 className="text-yellow-400 font-medium mb-2">Important Disclaimer</h4>
          <p className="text-yellow-300 text-sm">
            This prediction is for informational purposes only and should not be considered financial advice. 
            NFT markets are highly volatile and unpredictable. Always do your own research and never invest 
            more than you can afford to lose.
          </p>
        </motion.div>
      </div>
    </div>
  );
};