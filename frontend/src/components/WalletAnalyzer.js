import React, { useState } from 'react';
import { Shield, Search, AlertTriangle, CheckCircle, Clock, XCircle } from 'lucide-react';
import { apiService, formatWalletAddress, getRiskColor, getRiskBadgeColor, formatTimestamp, formatNumber } from '../services/api';

const WalletAnalyzer = () => {
  const [walletAddress, setWalletAddress] = useState('');
  const [analysisType, setAnalysisType] = useState('comprehensive');
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);
  const [taskId, setTaskId] = useState(null);

  const analysisTypes = [
    { value: 'comprehensive', label: 'Comprehensive Analysis', description: 'Full wallet risk assessment' },
    { value: 'tokens', label: 'Token Analysis', description: 'Token holdings and risk analysis' },
    { value: 'transactions', label: 'Transaction Analysis', description: 'Transaction history and patterns' },
  ];

  const handleAnalyze = async () => {
    if (!walletAddress.trim()) {
      setError('Please enter a wallet address');
      return;
    }

    setIsAnalyzing(true);
    setError(null);
    setResult(null);
    setTaskId(null);

    try {
      const response = await apiService.analyzeWalletPost({
        wallet_address: walletAddress.trim(),
        analysis_type: analysisType,
        async: true,
        priority: 2
      });

      if (response.status === 'submitted' || response.status === 'processing') {
        setTaskId(response.task_id);
        // Start polling for results
        pollForResults(response.task_id);
      } else {
        setResult(response);
        setIsAnalyzing(false);
      }
    } catch (err) {
      setError(err.response?.data?.error || err.message || 'Analysis failed');
      setIsAnalyzing(false);
    }
  };

  const pollForResults = async (taskId) => {
    try {
      const finalResult = await apiService.pollTaskStatus(taskId, 60, 2000);
      setResult(finalResult);
      setIsAnalyzing(false);
    } catch (err) {
      setError('Analysis timed out or failed');
      setIsAnalyzing(false);
    }
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case 'completed':
        return <CheckCircle className="w-5 h-5 text-success-500" />;
      case 'processing':
        return <Clock className="w-5 h-5 text-warning-500 animate-spin" />;
      case 'failed':
        return <XCircle className="w-5 h-5 text-danger-500" />;
      default:
        return <Clock className="w-5 h-5 text-gray-400" />;
    }
  };

  const renderRiskScore = (score) => {
    const percentage = Math.round(score * 100);
    let color = 'text-success-500';
    let bgColor = 'bg-success-500';
    
    if (percentage > 70) {
      color = 'text-danger-500';
      bgColor = 'bg-danger-500';
    } else if (percentage > 40) {
      color = 'text-warning-500';
      bgColor = 'bg-warning-500';
    }

    return (
      <div className="flex items-center space-x-3">
        <div className="flex-1 bg-slate-700 rounded-full h-3">
          <div 
            className={`h-3 rounded-full transition-all duration-500 ${bgColor}`}
            style={{ width: `${percentage}%` }}
          />
        </div>
        <span className={`text-sm font-mono font-bold ${color}`}>
          {percentage}%
        </span>
      </div>
    );
  };

  const renderAnalysisResult = () => {
    if (!result) return null;

    return (
      <div className="space-y-6 fade-in">
        {/* Overall Risk Assessment */}
        <div className="bg-slate-800 rounded-lg p-6 border border-slate-700">
          <h3 className="text-lg font-semibold text-white mb-4">Risk Assessment</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="text-center">
              <div className="text-2xl font-bold text-white mb-1">
                {result.overall_risk_score ? Math.round(result.overall_risk_score * 100) : 'N/A'}%
              </div>
              <div className="text-sm text-slate-400">Overall Risk</div>
            </div>
            <div className="text-center">
              <div className={`text-lg font-semibold ${getRiskColor(result.risk_level)}`}>
                {result.risk_level || 'Unknown'}
              </div>
              <div className="text-sm text-slate-400">Risk Level</div>
            </div>
            <div className="text-center">
              <div className="text-lg font-semibold text-white">
                {result.analysis_timestamp ? formatTimestamp(result.analysis_timestamp) : 'N/A'}
              </div>
              <div className="text-sm text-slate-400">Analyzed</div>
            </div>
          </div>
        </div>

        {/* Token Analysis */}
        {result.token_analysis && (
          <div className="bg-slate-800 rounded-lg p-6 border border-slate-700">
            <h3 className="text-lg font-semibold text-white mb-4">Token Analysis</h3>
            <div className="space-y-3">
              {result.token_analysis.tokens?.map((token, index) => (
                <div key={index} className="flex items-center justify-between p-3 bg-slate-700 rounded-lg">
                  <div className="flex items-center space-x-3">
                    <div className="w-8 h-8 bg-primary-600 rounded-full flex items-center justify-center">
                      <span className="text-xs font-bold text-white">T</span>
                    </div>
                    <div>
                      <div className="font-medium text-white">{token.symbol || 'Unknown'}</div>
                      <div className="text-sm text-slate-400">{formatWalletAddress(token.mint)}</div>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-sm text-white">{formatNumber(token.balance)}</div>
                    <div className={`text-xs ${getRiskColor(token.risk_level)}`}>
                      {token.risk_level || 'Unknown'}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Transaction Analysis */}
        {result.transaction_analysis && (
          <div className="bg-slate-800 rounded-lg p-6 border border-slate-700">
            <h3 className="text-lg font-semibold text-white mb-4">Transaction Analysis</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="text-center p-4 bg-slate-700 rounded-lg">
                <div className="text-2xl font-bold text-white">{result.transaction_analysis.total_transactions || 0}</div>
                <div className="text-sm text-slate-400">Total Transactions</div>
              </div>
              <div className="text-center p-4 bg-slate-700 rounded-lg">
                <div className={`text-lg font-semibold ${getRiskColor(result.transaction_analysis.risk_level)}`}>
                  {result.transaction_analysis.risk_level || 'Unknown'}
                </div>
                <div className="text-sm text-slate-400">Transaction Risk</div>
              </div>
            </div>
          </div>
        )}

        {/* Recommendations */}
        {result.recommendations && result.recommendations.length > 0 && (
          <div className="bg-slate-800 rounded-lg p-6 border border-slate-700">
            <h3 className="text-lg font-semibold text-white mb-4">Recommendations</h3>
            <div className="space-y-3">
              {result.recommendations.map((rec, index) => (
                <div key={index} className="flex items-start space-x-3 p-3 bg-slate-700 rounded-lg">
                  <AlertTriangle className="w-5 h-5 text-warning-500 mt-0.5 flex-shrink-0" />
                  <div>
                    <div className="font-medium text-white">{rec.title}</div>
                    <div className="text-sm text-slate-400">{rec.description}</div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    );
  };

  return (
    <div className="max-w-4xl mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="text-center">
        <div className="flex items-center justify-center space-x-3 mb-4">
          <Shield className="w-8 h-8 text-primary-500" />
          <h1 className="text-3xl font-bold text-white">Wallet Risk Analysis</h1>
        </div>
        <p className="text-slate-400 max-w-2xl mx-auto">
          Analyze Solana wallet addresses for potential risks, suspicious tokens, and transaction patterns.
          Get comprehensive risk assessments powered by advanced AI algorithms.
        </p>
      </div>

      {/* Analysis Form */}
      <div className="bg-slate-800 rounded-lg p-6 border border-slate-700">
        <div className="space-y-4">
          {/* Wallet Address Input */}
          <div>
            <label className="block text-sm font-medium text-white mb-2">
              Wallet Address
            </label>
            <div className="flex space-x-3">
              <input
                type="text"
                value={walletAddress}
                onChange={(e) => setWalletAddress(e.target.value)}
                placeholder="Enter Solana wallet address..."
                className="flex-1 px-4 py-3 bg-slate-700 border border-slate-600 rounded-lg text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                disabled={isAnalyzing}
              />
              <button
                onClick={handleAnalyze}
                disabled={isAnalyzing || !walletAddress.trim()}
                className="px-6 py-3 bg-primary-600 hover:bg-primary-700 disabled:bg-slate-600 disabled:cursor-not-allowed text-white font-medium rounded-lg transition-colors duration-200 flex items-center space-x-2"
              >
                {isAnalyzing ? (
                  <>
                    <Clock className="w-4 h-4 animate-spin" />
                    <span>Analyzing...</span>
                  </>
                ) : (
                  <>
                    <Search className="w-4 h-4" />
                    <span>Analyze</span>
                  </>
                )}
              </button>
            </div>
          </div>

          {/* Analysis Type Selection */}
          <div>
            <label className="block text-sm font-medium text-white mb-2">
              Analysis Type
            </label>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
              {analysisTypes.map((type) => (
                <label key={type.value} className="flex items-center p-3 bg-slate-700 rounded-lg cursor-pointer hover:bg-slate-600 transition-colors">
                  <input
                    type="radio"
                    name="analysisType"
                    value={type.value}
                    checked={analysisType === type.value}
                    onChange={(e) => setAnalysisType(e.target.value)}
                    className="sr-only"
                  />
                  <div className={`w-4 h-4 rounded-full border-2 mr-3 ${
                    analysisType === type.value 
                      ? 'border-primary-500 bg-primary-500' 
                      : 'border-slate-500'
                  }`} />
                  <div>
                    <div className="font-medium text-white">{type.label}</div>
                    <div className="text-sm text-slate-400">{type.description}</div>
                  </div>
                </label>
              ))}
            </div>
          </div>
        </div>

        {/* Error Display */}
        {error && (
          <div className="mt-4 p-4 bg-danger-900 border border-danger-700 rounded-lg">
            <div className="flex items-center space-x-2">
              <XCircle className="w-5 h-5 text-danger-500" />
              <span className="text-danger-200">{error}</span>
            </div>
          </div>
        )}

        {/* Task Status */}
        {taskId && isAnalyzing && (
          <div className="mt-4 p-4 bg-warning-900 border border-warning-700 rounded-lg">
            <div className="flex items-center space-x-2">
              <Clock className="w-5 h-5 text-warning-500 animate-spin" />
              <span className="text-warning-200">
                Analysis in progress... Task ID: {taskId}
              </span>
            </div>
          </div>
        )}
      </div>

      {/* Results */}
      {renderAnalysisResult()}
    </div>
  );
};

export default WalletAnalyzer;