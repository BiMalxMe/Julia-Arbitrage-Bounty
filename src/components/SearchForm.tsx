import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Search, Loader2, TrendingUp } from 'lucide-react';
import { SearchResult } from '../types';
import { nftApi } from '../utils/api';

interface SearchFormProps {
  onSearch: (address: string) => void;
  loading?: boolean;
}

export const SearchForm: React.FC<SearchFormProps> = ({ onSearch, loading = false }) => {
  const [query, setQuery] = useState('');
  const [suggestions, setSuggestions] = useState<SearchResult[]>([]);
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [searchLoading, setSearchLoading] = useState(false);

  useEffect(() => {
    const searchCollections = async () => {
      if (query.length < 2) {
        setSuggestions([]);
        setShowSuggestions(false);
        return;
      }

      setSearchLoading(true);
      try {
        const results = await nftApi.searchCollections(query);
        setSuggestions(results);
        setShowSuggestions(true);
      } catch (error) {
        console.error('Search error:', error);
        setSuggestions([]);
      } finally {
        setSearchLoading(false);
      }
    };

    const debounceTimer = setTimeout(searchCollections, 300);
    return () => clearTimeout(debounceTimer);
  }, [query]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (query.trim() && !loading) {
      onSearch(query.trim());
      setShowSuggestions(false);
    }
  };

  const handleSuggestionClick = (suggestion: SearchResult) => {
    setQuery(suggestion.name);
    onSearch(suggestion.address);
    setShowSuggestions(false);
  };

  const popularCollections = [
    { name: "Bored Ape Yacht Club", address: "0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D" },
    { name: "CryptoPunks", address: "0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB" },
    { name: "Azuki", address: "0xED5AF388653567Af2F388E6224dC7C4b3241C544" },
  ];

  return (
    <div className="w-full max-w-2xl mx-auto space-y-6">
      <div className="relative">
        <form onSubmit={handleSubmit} className="relative">
          <div className="relative">
            <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
            <input
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Enter NFT collection name or contract address..."
              className="w-full pl-12 pr-32 py-4 bg-gray-800 border border-gray-700 rounded-xl text-white placeholder-gray-400 focus:ring-2 focus:ring-emerald-500 focus:border-transparent transition-all duration-200"
              disabled={loading}
            />
            <motion.button
              type="submit"
              disabled={loading || !query.trim()}
              className="absolute right-2 top-1/2 transform -translate-y-1/2 bg-gradient-to-r from-emerald-500 to-emerald-600 text-white px-6 py-2 rounded-lg font-medium disabled:opacity-50 disabled:cursor-not-allowed hover:from-emerald-600 hover:to-emerald-700 transition-all duration-200"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              {loading ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                'Predict'
              )}
            </motion.button>
          </div>
        </form>

        {/* Search suggestions dropdown */}
        <AnimatePresence>
          {showSuggestions && suggestions.length > 0 && (
            <motion.div
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              className="absolute top-full left-0 right-0 mt-2 bg-gray-800 border border-gray-700 rounded-xl shadow-2xl z-50 overflow-hidden"
            >
              {searchLoading && (
                <div className="p-4 text-center text-gray-400">
                  <Loader2 className="w-4 h-4 animate-spin mx-auto" />
                </div>
              )}
              {!searchLoading && suggestions.map((suggestion, index) => (
                <motion.div
                  key={suggestion.address}
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: index * 0.05 }}
                  onClick={() => handleSuggestionClick(suggestion)}
                  className="p-4 hover:bg-gray-700 cursor-pointer border-b border-gray-700 last:border-b-0 transition-colors duration-150"
                >
                  <div className="flex items-center justify-between">
                    <div>
                      <h4 className="text-white font-medium">{suggestion.name}</h4>
                      <p className="text-gray-400 text-sm font-mono">
                        {suggestion.address.slice(0, 10)}...{suggestion.address.slice(-8)}
                      </p>
                    </div>
                    {suggestion.floor_price && (
                      <div className="text-right">
                        <p className="text-emerald-400 font-medium">{suggestion.floor_price} ETH</p>
                        <p className="text-gray-500 text-xs">Floor Price</p>
                      </div>
                    )}
                  </div>
                </motion.div>
              ))}
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Popular collections */}
      {!query && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="space-y-3"
        >
          <div className="flex items-center space-x-2 text-gray-400">
            <TrendingUp className="w-4 h-4" />
            <span className="text-sm font-medium">Popular Collections</span>
          </div>
          <div className="flex flex-wrap gap-2">
            {popularCollections.map((collection) => (
              <motion.button
                key={collection.address}
                onClick={() => handleSuggestionClick(collection)}
                className="px-4 py-2 bg-gray-800 hover:bg-gray-700 border border-gray-700 rounded-lg text-gray-300 hover:text-white transition-all duration-200 text-sm"
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                {collection.name}
              </motion.button>
            ))}
          </div>
        </motion.div>
      )}
    </div>
  );
};