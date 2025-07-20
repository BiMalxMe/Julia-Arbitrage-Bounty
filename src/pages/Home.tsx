import React from 'react';
import { motion } from 'framer-motion';
import { Brain, TrendingUp, Zap, Shield, Users, BarChart3 } from 'lucide-react';
import { SearchForm } from '../components/SearchForm';
import { usePrediction } from '../hooks/usePrediction';
import { useNavigate } from 'react-router-dom';

export const Home: React.FC = () => {
  const { predict, loading } = usePrediction();
  const navigate = useNavigate();

  const handleSearch = async (address: string) => {
    try {
      const result = await predict(address);
      // Navigate to results page with prediction data
      navigate('/results', { state: { prediction: result } });
    } catch (error) {
      console.error('Prediction failed:', error);
    }
  };

  const features = [
    {
      icon: Brain,
      title: "AI-Powered Analysis",
      description: "Advanced LLM models analyze market sentiment, social trends, and onchain data for comprehensive insights."
    },
    {
      icon: TrendingUp,
      title: "Multi-Timeframe Predictions",
      description: "Get price predictions for 24h, 7d, and 30d periods with confidence scores and risk assessments."
    },
    {
      icon: Zap,
      title: "Real-Time Processing",
      description: "JuliaOS agent swarms process data from multiple sources in real-time for accurate predictions."
    },
    {
      icon: Shield,
      title: "Risk Assessment",
      description: "Comprehensive risk analysis helps you understand potential downsides and market volatility."
    },
    {
      icon: Users,
      title: "Community Insights",
      description: "Social sentiment analysis from Twitter, Discord, and other platforms reveals market mood."
    },
    {
      icon: BarChart3,
      title: "Technical Analysis",
      description: "Chart patterns, volume analysis, and whale movement tracking for complete market view."
    }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900">
      {/* Header */}
      <motion.header
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="container mx-auto px-6 py-8"
      >
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-gradient-to-r from-emerald-500 to-purple-600 rounded-lg flex items-center justify-center">
              <Brain className="w-6 h-6 text-white" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-white">NFT Predictor</h1>
              <p className="text-gray-400 text-sm">Powered by JuliaOS Agents</p>
            </div>
          </div>
          <div className="text-right">
            <div className="text-emerald-400 font-bold">AI Agents Active</div>
            <div className="text-gray-500 text-sm">4/4 Online</div>
          </div>
        </div>
      </motion.header>

      {/* Hero Section */}
      <motion.section
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
        className="container mx-auto px-6 py-16 text-center"
      >
        <h2 className="text-5xl md:text-6xl font-bold text-white mb-6">
          Predict NFT Prices with
          <span className="bg-gradient-to-r from-emerald-400 via-purple-400 to-orange-400 bg-clip-text text-transparent">
            {" "}AI Agents
          </span>
        </h2>
        <p className="text-xl text-gray-300 mb-12 max-w-3xl mx-auto">
          Harness the power of JuliaOS agent swarms to analyze market data, sentiment, and trends. 
          Get accurate NFT price predictions with confidence scores and detailed AI reasoning.
        </p>

        <SearchForm onSearch={handleSearch} loading={loading} />

        {/* Stats */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="grid grid-cols-2 md:grid-cols-4 gap-8 mt-16"
        >
          <div className="text-center">
            <div className="text-3xl font-bold text-emerald-400">85%</div>
            <div className="text-gray-400 text-sm">Prediction Accuracy</div>
          </div>
          <div className="text-center">
            <div className="text-3xl font-bold text-purple-400">12K+</div>
            <div className="text-gray-400 text-sm">Collections Analyzed</div>
          </div>
          <div className="text-center">
            <div className="text-3xl font-bold text-orange-400">2.3s</div>
            <div className="text-gray-400 text-sm">Avg Processing Time</div>
          </div>
          <div className="text-center">
            <div className="text-3xl font-bold text-blue-400">4</div>
            <div className="text-gray-400 text-sm">AI Agents</div>
          </div>
        </motion.div>
      </motion.section>

      {/* Features Section */}
      <motion.section
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.6 }}
        className="container mx-auto px-6 py-16"
      >
        <h3 className="text-3xl font-bold text-white text-center mb-12">
          How Our AI Agents Work
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {features.map((feature, index) => {
            const IconComponent = feature.icon;
            return (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.7 + index * 0.1 }}
                className="bg-gray-800 rounded-xl p-6 border border-gray-700 hover:border-gray-600 transition-all duration-300"
              >
                <div className="flex items-center space-x-3 mb-4">
                  <div className="w-10 h-10 bg-gradient-to-r from-emerald-500 to-purple-600 rounded-lg flex items-center justify-center">
                    <IconComponent className="w-6 h-6 text-white" />
                  </div>
                  <h4 className="text-lg font-semibold text-white">{feature.title}</h4>
                </div>
                <p className="text-gray-300">{feature.description}</p>
              </motion.div>
            );
          })}
        </div>
      </motion.section>

      {/* CTA Section */}
      <motion.section
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 1 }}
        className="container mx-auto px-6 py-16 text-center"
      >
        <div className="bg-gradient-to-r from-emerald-500/20 to-purple-600/20 rounded-2xl p-12 border border-gray-700">
          <h3 className="text-3xl font-bold text-white mb-4">
            Ready to Predict the Future?
          </h3>
          <p className="text-gray-300 mb-8 max-w-2xl mx-auto">
            Join thousands of traders using our AI-powered predictions to make smarter NFT investments.
            Start with any collection address or name.
          </p>
          <motion.button
            onClick={() => document.querySelector('input')?.focus()}
            className="bg-gradient-to-r from-emerald-500 to-emerald-600 text-white px-8 py-3 rounded-lg font-semibold hover:from-emerald-600 hover:to-emerald-700 transition-all duration-200"
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            Start Predicting Now
          </motion.button>
        </div>
      </motion.section>
    </div>
  );
};