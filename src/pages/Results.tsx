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

  useEffect(() => {
    if (prediction?.data.collection.address) {
      setLoading(true);
      nftApi.getMarketData(prediction.data.collection.address)
        .then(setMarketData)
        .catch((err) => console.error('Failed to fetch market data:', err))
        .finally(() => setLoading(false));
    }
  }, [prediction]);

  const handleRefresh = async () => {
    if (!prediction?.data.collection.address) return;

    setRefreshing(true);
    try {
      const newPrediction = await nftApi.predictPrice(prediction.data.collection.address);
      setPrediction(newPrediction);
      // Fetch new market data for the same address
      const newMarketData = await nftApi.getMarketData(newPrediction.data.collection.address);
      setMarketData(newMarketData);
    } catch (error) {
      console.error('Failed to refresh prediction or market data:', error);
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

  function formatMarketCap(value: number) {
    if (value >= 1_000_000_000) return (value / 1_000_000_000).toFixed(2) + 'B ETH';
    if (value >= 1_000_000) return (value / 1_000_000).toFixed(2) + 'M ETH';
    if (value >= 1_000) return (value / 1_000).toFixed(2) + 'K ETH';
    return value + ' ETH';
  }

  const floorPrice = marketData?.floor_price ?? collection.floor_price;
  const volume24h = marketData?.volume_24h ?? collection.volume_24h;
  const marketCap = marketData?.market_cap ?? collection.market_cap;
  const totalSupply = marketData?.total_supply ?? collection.total_supply;

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
          {loading && <LoadingSpinner message="Fetching live market data..." />}
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
                  <div className="text-lg font-bold text-emerald-400">
                    {floorPrice !== undefined ? `${floorPrice} ETH` : 'N/A'}
                  </div>
                  <div className="text-xs text-gray-500">Floor Price</div>
                </div>
                <div>
                  <div className="text-lg font-bold text-purple-400">
                    {volume24h !== undefined ? `${volume24h} ETH` : 'N/A'}
                  </div>
                  <div className="text-xs text-gray-500">24h Volume</div>
                </div>
                <div>
                  <div className="text-lg font-bold text-orange-400 flex items-center space-x-1">
                    <span>
                      {marketCap !== undefined ? formatMarketCap(marketCap) : 'N/A'}
                    </span>
                    <span className="text-xs text-gray-500" title="Market Cap = Floor Price × Total Supply">ⓘ</span>
                  </div>
                  <div className="text-xs text-gray-500">Market Cap</div>
                </div>
                <div>
                  <div className="text-lg font-bold text-blue-400">
                    {totalSupply !== undefined ? totalSupply.toLocaleString() : 'N/A'}
                  </div>
                  <div className="text-xs text-gray-500">Total Supply</div>
                </div>
              </div>
            </div>
          </div>
        </motion.div>

        {/* Results Grid */}
        <div className="space-y-8 max-w-3xl mx-auto">
          <PredictionCard
            predictions={predictions}
            confidence={confidence_score}
            timestamp={prediction.timestamp}
            processingTime={prediction.processing_time}
          />
          <AIReasoningDisplay
            reasoning={ai_reasoning}
            reasoningSteps={reasoning_steps}
            marketSentiment={market_sentiment}
            riskFactors={risk_factors}
          />
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