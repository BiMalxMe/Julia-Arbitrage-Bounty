import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Brain, ChevronDown, ChevronUp, TrendingUp, TrendingDown, Minus, AlertCircle } from 'lucide-react';
import { AIReasoningStep } from '../types';

interface AIReasoningDisplayProps {
  reasoning: string;
  reasoningSteps: AIReasoningStep[];
  marketSentiment: 'bullish' | 'bearish' | 'neutral';
  riskFactors: string[];
}

export const AIReasoningDisplay: React.FC<AIReasoningDisplayProps> = ({
  reasoning,
  reasoningSteps,
  marketSentiment,
  riskFactors,
}) => {
  const [expanded, setExpanded] = useState(false);
  const [selectedStep, setSelectedStep] = useState<number | null>(null);

  const getSentimentIcon = () => {
    switch (marketSentiment) {
      case 'bullish':
        return <TrendingUp className="w-5 h-5 text-emerald-400" />;
      case 'bearish':
        return <TrendingDown className="w-5 h-5 text-red-400" />;
      default:
        return <Minus className="w-5 h-5 text-yellow-400" />;
    }
  };

  const getSentimentColor = () => {
    switch (marketSentiment) {
      case 'bullish':
        return 'text-emerald-400';
      case 'bearish':
        return 'text-red-400';
      default:
        return 'text-yellow-400';
    }
  };

  const getImpactIcon = (impact: AIReasoningStep['impact']) => {
    switch (impact) {
      case 'positive':
        return <TrendingUp className="w-4 h-4 text-emerald-400" />;
      case 'negative':
        return <TrendingDown className="w-4 h-4 text-red-400" />;
      default:
        return <Minus className="w-4 h-4 text-yellow-400" />;
    }
  };

  const getImpactColor = (impact: AIReasoningStep['impact']) => {
    switch (impact) {
      case 'positive':
        return 'border-emerald-500/30 bg-emerald-500/10';
      case 'negative':
        return 'border-red-500/30 bg-red-500/10';
      default:
        return 'border-yellow-500/30 bg-yellow-500/10';
    }
  };

  // Split reasoning into points (by line, bullet, or number)
  const insightPoints = reasoning
    .split(/\n|\r|•|\d+\.|\-/)
    .map(s => s.trim())
    .filter(Boolean);

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="bg-black/90 rounded-xl border border-gray-800 p-6 space-y-6 shadow-2xl backdrop-blur-md"
    >
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-3">
          <Brain className="w-6 h-6 text-purple-400" />
          <h3 className="text-xl font-bold text-white">AI Analysis</h3>
        </div>
        <div className="flex items-center space-x-2">
          {getSentimentIcon()}
          <span className={`font-medium capitalize ${getSentimentColor()}`}>
            {marketSentiment}
          </span>
        </div>
      </div>

      {/* Main Reasoning */}
      <div className="space-y-3">
        <h4 className="text-gray-300 font-medium">Key Insights</h4>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {insightPoints.map((point, idx) => (
            <div
              key={idx}
              className="bg-gradient-to-br from-gray-900/80 to-gray-800/80 border border-gray-700 rounded-lg p-4 shadow hover:shadow-lg transition-all duration-200 flex items-start space-x-3"
            >
              <span className="mt-1 w-2 h-2 rounded-full bg-purple-400 flex-shrink-0"></span>
              <span className="text-gray-200 text-sm leading-relaxed">{point}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Reasoning Steps */}
      <div className="space-y-3">
        <button
          onClick={() => setExpanded(!expanded)}
          className="flex items-center justify-between w-full text-left"
        >
          <h4 className="text-gray-300 font-medium">Detailed Analysis</h4>
          {expanded ? (
            <ChevronUp className="w-5 h-5 text-gray-400" />
          ) : (
            <ChevronDown className="w-5 h-5 text-gray-400" />
          )}
        </button>

        <AnimatePresence>
          {expanded && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              className="space-y-3"
            >
              {reasoningSteps.map((step, index) => (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: index * 0.1 }}
                  className={`p-4 rounded-lg border cursor-pointer transition-all duration-200 ${getImpactColor(step.impact)} ${
                    selectedStep === index ? 'ring-2 ring-purple-500' : 'hover:bg-opacity-20'
                  }`}
                  onClick={() => setSelectedStep(selectedStep === index ? null : index)}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-3">
                      {getImpactIcon(step.impact)}
                      <span className="text-white font-medium">{step.factor}</span>
                    </div>
                    <div className="text-right">
                      <div className="text-white font-medium">{step.confidence}%</div>
                      <div className="text-xs text-gray-400">Confidence</div>
                    </div>
                  </div>
                  
                  <AnimatePresence>
                    {selectedStep === index && (
                      <motion.div
                        initial={{ opacity: 0, height: 0 }}
                        animate={{ opacity: 1, height: 'auto' }}
                        exit={{ opacity: 0, height: 0 }}
                        className="mt-3 pt-3 border-t border-gray-600"
                      >
                        <p className="text-gray-300 text-sm">{step.explanation}</p>
                      </motion.div>
                    )}
                  </AnimatePresence>
                </motion.div>
              ))}
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Risk Factors */}
      {riskFactors.length > 0 && (
        <div className="space-y-3">
          <div className="flex items-center space-x-2">
            <AlertCircle className="w-5 h-5 text-orange-400" />
            <h4 className="text-gray-300 font-medium">Risk Factors</h4>
          </div>
          <div className="space-y-2">
            {riskFactors.map((risk, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.1 }}
                className="flex items-center space-x-2 text-orange-300 text-sm"
              >
                <div className="w-1.5 h-1.5 bg-orange-400 rounded-full" />
                <span>{risk}</span>
              </motion.div>
            ))}
          </div>
        </div>
      )}
    </motion.div>
  );
};