import axios from 'axios';

class ApiKeyService {
  constructor() {
    this.providers = {
      nft_data: {
        opensea: {
          name: 'OpenSea',
          key: process.env.OPENSEA_API_KEY,
          baseUrl: 'https://api.opensea.io/api/v1',
          rateLimit: { requests: 1000, period: 'month' },
          available: !!process.env.OPENSEA_API_KEY
        },
        alchemy: {
          name: 'Alchemy NFT',
          key: process.env.ALCHEMY_API_KEY,
          baseUrl: 'https://eth-mainnet.g.alchemy.com/nft/v2',
          rateLimit: { requests: 300000000, period: 'month' },
          available: !!process.env.ALCHEMY_API_KEY
        },
        moralis: {
          name: 'Moralis',
          key: process.env.MORALIS_API_KEY,
          baseUrl: 'https://deep-index.moralis.io/api/v2',
          rateLimit: { requests: 40000, period: 'month' },
          available: !!process.env.MORALIS_API_KEY
        }
      },
      ai_llm: {
        openrouter: {
          name: 'OpenRouter',
          key: process.env.OPENROUTER_API_KEY,
          baseUrl: 'https://openrouter.ai/api/v1',
          available: !!process.env.OPENROUTER_API_KEY,
          cost: 'free_tier'
        },
        huggingface: {
          name: 'Hugging Face',
          key: process.env.HUGGINGFACE_API_KEY,
          baseUrl: 'https://api-inference.huggingface.co',
          available: !!process.env.HUGGINGFACE_API_KEY,
          cost: 'free'
        },
        groq: {
          name: 'Groq',
          key: process.env.GROQ_API_KEY,
          baseUrl: 'https://api.groq.com/openai/v1',
          available: !!process.env.GROQ_API_KEY,
          cost: 'free_tier'
        },
        together: {
          name: 'Together AI',
          key: process.env.TOGETHER_API_KEY,
          baseUrl: 'https://api.together.xyz/v1',
          available: !!process.env.TOGETHER_API_KEY,
          cost: 'free_tier'
        }
      },
      blockchain: {
        alchemy_eth: {
          name: 'Alchemy Ethereum',
          key: process.env.ALCHEMY_API_KEY,
          baseUrl: 'https://eth-mainnet.g.alchemy.com/v2',
          available: !!process.env.ALCHEMY_API_KEY
        },
        infura: {
          name: 'Infura',
          key: process.env.INFURA_API_KEY,
          projectId: process.env.INFURA_PROJECT_ID,
          baseUrl: 'https://mainnet.infura.io/v3',
          available: !!(process.env.INFURA_API_KEY && process.env.INFURA_PROJECT_ID)
        },
        etherscan: {
          name: 'Etherscan',
          key: process.env.ETHERSCAN_API_KEY,
          baseUrl: 'https://api.etherscan.io/api',
          available: !!process.env.ETHERSCAN_API_KEY
        }
      },
      market_data: {
        coingecko: {
          name: 'CoinGecko',
          key: process.env.COINGECKO_API_KEY,
          baseUrl: 'https://api.coingecko.com/api/v3',
          available: true, // Free tier doesn't require key
          cost: 'free'
        },
        coinmarketcap: {
          name: 'CoinMarketCap',
          key: process.env.COINMARKETCAP_API_KEY,
          baseUrl: 'https://pro-api.coinmarketcap.com/v1',
          available: !!process.env.COINMARKETCAP_API_KEY
        }
      }
    };

    this.usage = new Map(); // Track API usage
    this.initializeUsageTracking();
  }

  /**
   * Initialize usage tracking
   */
  initializeUsageTracking() {
    for (const category of Object.keys(this.providers)) {
      for (const provider of Object.keys(this.providers[category])) {
        this.usage.set(`${category}.${provider}`, {
          requests: 0,
          errors: 0,
          lastUsed: null,
          resetTime: this.getNextResetTime()
        });
      }
    }
  }

  /**
   * Get next reset time (monthly)
   */
  getNextResetTime() {
    const now = new Date();
    const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);
    return nextMonth;
  }

  /**
   * Get best available provider for a category
   */
  getBestProvider(category) {
    const categoryProviders = this.providers[category];
    if (!categoryProviders) {
      throw new Error(`Unknown provider category: ${category}`);
    }

    // Filter available providers
    const availableProviders = Object.entries(categoryProviders)
      .filter(([_, config]) => config.available)
      .sort((a, b) => {
        // Prioritize by usage (least used first)
        const usageA = this.usage.get(`${category}.${a[0]}`);
        const usageB = this.usage.get(`${category}.${b[0]}`);
        return usageA.requests - usageB.requests;
      });

    if (availableProviders.length === 0) {
      throw new Error(`No available providers for category: ${category}`);
    }

    return {
      name: availableProviders[0][0],
      config: availableProviders[0][1]
    };
  }

  /**
   * Record API usage
   */
  recordUsage(category, provider, success = true) {
    const key = `${category}.${provider}`;
    const usage = this.usage.get(key);
    
    if (usage) {
      usage.requests++;
      usage.lastUsed = new Date();
      if (!success) {
        usage.errors++;
      }
    }
  }

  /**
   * Check if provider is within rate limits
   */
  isWithinRateLimit(category, provider) {
    const key = `${category}.${provider}`;
    const usage = this.usage.get(key);
    const config = this.providers[category]?.[provider];

    if (!usage || !config?.rateLimit) {
      return true; // No rate limit defined
    }

    // Check if we need to reset usage
    if (new Date() > usage.resetTime) {
      usage.requests = 0;
      usage.errors = 0;
      usage.resetTime = this.getNextResetTime();
    }

    return usage.requests < config.rateLimit.requests;
  }

  /**
   * Get provider status
   */
  getProviderStatus() {
    const status = {};
    
    for (const [category, providers] of Object.entries(this.providers)) {
      status[category] = {};
      
      for (const [name, config] of Object.entries(providers)) {
        const usage = this.usage.get(`${category}.${name}`);
        status[category][name] = {
          available: config.available,
          usage: usage ? {
            requests: usage.requests,
            errors: usage.errors,
            lastUsed: usage.lastUsed,
            withinRateLimit: this.isWithinRateLimit(category, name)
          } : null
        };
      }
    }
    
    return status;
  }

  /**
   * Get available providers summary
   */
  getAvailableProviders() {
    const available = {};
    
    for (const [category, providers] of Object.entries(this.providers)) {
      available[category] = Object.entries(providers)
        .filter(([_, config]) => config.available)
        .map(([name, config]) => ({
          name,
          displayName: config.name,
          cost: config.cost || 'paid',
          rateLimit: config.rateLimit
        }));
    }
    
    return available;
  }

  /**
   * Test provider connectivity
   */
  async testProvider(category, provider) {
    const config = this.providers[category]?.[provider];
    if (!config || !config.available) {
      return { success: false, error: 'Provider not available' };
    }

    try {
      switch (category) {
        case 'ai_llm':
          return await this.testLLMProvider(provider, config);
        case 'nft_data':
          return await this.testNFTProvider(provider, config);
        case 'blockchain':
          return await this.testBlockchainProvider(provider, config);
        case 'market_data':
          return await this.testMarketDataProvider(provider, config);
        default:
          return { success: false, error: 'Unknown category' };
      }
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Test LLM provider
   */
  async testLLMProvider(provider, config) {
    if (provider === 'openrouter') {
      try {
        const response = await axios.get(`${config.baseUrl}/`, { timeout: 5000 });
        return { success: true, models: response.data.models?.length || 0 };
      } catch (error) {
        return { success: false, error: 'OpenRouter not responding' };
      }
    }

    // Test other LLM providers with a simple request
    const headers = { 'Authorization': `Bearer ${config.key}` };
    try {
      const response = await axios.get(config.baseUrl, { headers, timeout: 5000 });
      return { success: true };
    } catch (error) {
      return { success: false, error: error.response?.status || error.message };
    }
  }

  /**
   * Test NFT data provider
   */
  async testNFTProvider(provider, config) {
    const headers = {};
    if (config.key) {
      headers['X-API-KEY'] = config.key;
    }

    try {
      // Test with a simple endpoint
      const testUrl = provider === 'opensea' 
        ? `${config.baseUrl}/collections?limit=1`
        : `${config.baseUrl}/${config.key}/getContractMetadata?contractAddress=0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D`;
      
      const response = await axios.get(testUrl, { headers, timeout: 5000 });
      return { success: true, status: response.status };
    } catch (error) {
      return { success: false, error: error.response?.status || error.message };
    }
  }

  /**
   * Test blockchain provider
   */
  async testBlockchainProvider(provider, config) {
    try {
      const testUrl = provider === 'etherscan'
        ? `${config.baseUrl}?module=proxy&action=eth_blockNumber&apikey=${config.key}`
        : `${config.baseUrl}/${config.key || config.projectId}`;
      
      const response = await axios.post(testUrl, {
        jsonrpc: '2.0',
        method: 'eth_blockNumber',
        params: [],
        id: 1
      }, { timeout: 5000 });
      
      return { success: true, blockNumber: response.data.result };
    } catch (error) {
      return { success: false, error: error.response?.status || error.message };
    }
  }

  /**
   * Test market data provider
   */
  async testMarketDataProvider(provider, config) {
    try {
      const headers = {};
      if (config.key) {
        headers['X-CMC_PRO_API_KEY'] = config.key;
      }

      const testUrl = provider === 'coingecko'
        ? `${config.baseUrl}/ping`
        : `${config.baseUrl}/cryptocurrency/listings/latest?limit=1`;
      
      const response = await axios.get(testUrl, { headers, timeout: 5000 });
      return { success: true, status: response.status };
    } catch (error) {
      return { success: false, error: error.response?.status || error.message };
    }
  }

  /**
   * Get LLM providers in priority order
   */
  getLLMProviders() {
    const providers = process.env.LLM_PROVIDERS?.split(',') || ['openrouter', 'huggingface', 'groq', 'together'];
    return providers
      .map(name => ({
        name: name.trim(),
        config: this.providers.ai_llm[name.trim()]
      }))
      .filter(p => p.config?.available);
  }
}

export const apiKeyService = new ApiKeyService();