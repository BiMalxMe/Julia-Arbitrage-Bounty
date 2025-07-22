import React from 'react';
import { motion } from 'framer-motion';
import { TrendingUp, TrendingDown, Minus, Target, AlertTriangle, Clock } from 'lucide-react';
import { Prediction, PredictionTimeframe } from '../types';
import { formatDistanceToNow } from 'date-fns';

interface PredictionCardProps {
  predictions: Prediction;
  confidence: number;
  timestamp: string;
  processingTime: number;
}

export const PredictionCard: React.FC<PredictionCardProps> = ({
  predictions,
  confidence,
  timestamp,
  processingTime,
}) => {
  const getDirectionIcon = (direction: PredictionTimeframe['direction']) => {
    switch (direction) {
      case 'up':
        return <TrendingUp className="w-5 h-5 text-emerald-400" />;
      case 'down':
        return <TrendingDown className="w-5 h-5 text-red-400" />;
      default:
        return <Minus className="w-5 h-5 text-yellow-400" />;
    }
  };

  const getDirectionColor = (direction: PredictionTimeframe['direction']) => {
    switch (direction) {
      case 'up':
        return 'text-emerald-400';
      case 'down':
        return 'text-red-400';
      default:
        return 'text-yellow-400';
    }
  };

  const getConfidenceColor = (conf: number) => {
    if (conf >= 80) return 'text-emerald-400';
    if (conf >= 60) return 'text-yellow-400';
    return 'text-red-400';
  };

  const timeframes = [
    { key: '24h' as const, label: '24 Hours', data: predictions['24h'] },
    { key: '7d' as const, label: '7 Days', data: predictions['7d'] },
    { key: '30d' as const, label: '30 Days', data: predictions['30d'] },
  ];

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="bg-gradient-to-br from-gray-900/80 via-gray-800/80 to-gray-900/80 rounded-xl border border-gray-700 p-6 space-y-6 shadow-xl backdrop-blur-md"
    >
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-3">
          <Target className="w-6 h-6 text-emerald-400" />
          <h3 className="text-xl font-bold text-white tracking-tight">Price Predictions</h3>
        </div>
        <div className="text-right">
          <div className={`text-lg font-bold ${getConfidenceColor(confidence)}`}>
            {confidence}%
          </div>
          <div className="text-xs text-gray-500">Overall Confidence</div>
        </div>
      </div>

      {/* Prediction Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {timeframes.map((timeframe, index) => (
          <motion.div
            key={timeframe.key}
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: index * 0.1 }}
            className="bg-gradient-to-br from-gray-900/90 to-gray-800/90 rounded-lg p-4 border border-gray-700 shadow-lg hover:shadow-2xl transition-shadow duration-300"
          >
            <div className="flex items-center justify-between mb-3">
              <span className="text-gray-400 text-sm font-medium">{timeframe.label}</span>
              {getDirectionIcon(timeframe.data.direction)}
            </div>
            
            <div className="space-y-2">
              <div className={`text-xl font-bold ${getDirectionColor(timeframe.data.direction)}`}>
                {timeframe.data.direction === 'up' ? '+' : timeframe.data.direction === 'down' ? '' : ''}
                {timeframe.data.percentage_change.toFixed(1)}%
              </div>
              
              {timeframe.data.price_target && (
                <div className="text-sm text-gray-300">
                  <span className="font-semibold text-gray-400">Target:</span> <span className="text-white">{timeframe.data.price_target.toFixed(2)} ETH</span>
                </div>
              )}
              
              <div className="flex items-center space-x-2">
                <div className={`text-xs font-medium ${getConfidenceColor(timeframe.data.confidence)}`}>
                  {timeframe.data.confidence}% confident
                </div>
                <div className="flex-1 bg-gray-800 rounded-full h-1.5">
                  <div
                    className={`h-full rounded-full transition-all duration-300 ${
                      timeframe.data.confidence >= 80
                        ? 'bg-emerald-400'
                        : timeframe.data.confidence >= 60
                        ? 'bg-yellow-400'
                        : 'bg-red-400'
                    }`}
                    style={{ width: `${timeframe.data.confidence}%` }}
                  />
                </div>
              </div>
            </div>
          </motion.div>
        ))}
      </div>

      {/* Confidence Warning */}
      {confidence < 60 && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="flex items-center space-x-2 p-3 bg-yellow-500/10 border border-yellow-500/30 rounded-lg"
        >
          <AlertTriangle className="w-5 h-5 text-yellow-400" />
          <span className="text-yellow-400 text-sm">
            Low confidence prediction. Consider additional research before making decisions.
          </span>
        </motion.div>
      )}

      {/* Metadata */}
      <div className="flex items-center justify-between text-xs text-gray-500 pt-3 border-t border-gray-700">
        <div className="flex items-center space-x-1">
          <Clock className="w-3 h-3" />
          <span>Generated {formatDistanceToNow(new Date(timestamp))} ago</span>
        </div>
        <span>Processed in {processingTime.toFixed(1)}s</span>
      </div>
    </motion.div>
  );
};