import axios from 'axios';

class NFTService {
  constructor() {
    this.openSeaBaseUrl = 'https://api.opensea.io/api/v1';
    this.alchemyBaseUrl = 'https://eth-mainnet.g.alchemy.com/nft/v2';
    this.coinGeckoBaseUrl = 'https://api.coingecko.com/api/v3';
  }

  /**
   * Validate Ethereum address format
   */
  isValidAddress(address) {
    return /^0x[a-fA-F0-9]{40}$/.test(address);
  }

  /**
   * Fetch collection data from OpenSea (free tier)
   */
  async fetchOpenSeaData(collectionSlug) {
    try {
      const headers = {
        'Accept': 'application/json'
      };

      if (process.env.OPENSEA_API_KEY) {
        headers['X-API-KEY'] = process.env.OPENSEA_API_KEY;
      }

      const response = await axios.get(
        `${this.openSeaBaseUrl}/collection/${collectionSlug}/stats`,
        { headers, timeout: 10000 }
      );

      return response.data;
    } catch (error) {
      console.warn('OpenSea API error:', error.message);
      throw error;
    }
  }

  /**
   * Fetch collection data from Alchemy (free tier)
   */
  async fetchAlchemyData(contractAddress) {
    try {
      if (!process.env.ALCHEMY_API_KEY) {
        throw new Error('Alchemy API key not configured');
      }

      const url = `${this.alchemyBaseUrl}/${process.env.ALCHEMY_API_KEY}/getContractMetadata`;
      
      const response = await axios.get(url, {
        params: { contractAddress },
        timeout: 10000
      });

      return response.data;
    } catch (error) {
      console.warn('Alchemy API error:', error.message);
      throw error;
    }
  }

  /**
   * Fetch ETH price from CoinGecko (free tier)
   */
  async fetchEthPrice() {
    try {
      const response = await axios.get(
        `${this.coinGeckoBaseUrl}/simple/price?ids=ethereum&vs_currencies=usd`,
        { timeout: 5000 }
      );

      return response.data.ethereum.usd;
    } catch (error) {
      console.warn('CoinGecko API error:', error.message);
      return 2000; // Fallback ETH price
    }
  }

  /**
   * Generate mock historical data for demo
   */
  generateMockHistory(contractAddress) {
    const now = new Date();
    const days = 30;
    
    const labels = [];
    const prices = [];
    const volumes = [];
    
    const basePrice = 12.5 + (Math.random() - 0.5) * 5;
    
    for (let i = days - 1; i >= 0; i--) {
      const date = new Date(now);
      date.setDate(date.getDate() - i);
      labels.push(date.toISOString().split('T')[0]);
      
      // Generate realistic price movement
      const trend = Math.sin(i / 5) * 2;
      const noise = (Math.random() - 0.5) * 1.5;
      const price = Math.max(0.1, basePrice + trend + noise);
      prices.push(parseFloat(price.toFixed(2)));
      
      // Generate volume data
      const volume = Math.random() * 800 + 200;
      volumes.push(parseFloat(volume.toFixed(1)));
    }
    
    // Generate future predictions
    const predictionPrices = [];
    const confidenceBands = [];
    
    for (let i = 1; i <= 5; i++) {
      const prediction = prices[prices.length - 1] * (1 + (Math.random() - 0.5) * 0.2);
      predictionPrices.push(parseFloat(prediction.toFixed(2)));
      
      const confidence = prediction * 0.1;
      confidenceBands.push([
        parseFloat((prediction - confidence).toFixed(2)),
        parseFloat((prediction + confidence).toFixed(2))
      ]);
    }
    
    return {
      labels,
      prices,
      volumes,
      predictions: {
        prices: predictionPrices,
        confidence_bands: confidenceBands
      }
    };
  }

  /**
   * Validate and clean collection data
   */
  validateCollectionData(data) {
    const required = ['name', 'address', 'floor_price'];
    const missing = required.filter(field => !data[field]);
    
    if (missing.length > 0) {
      throw new Error(`Missing required fields: ${missing.join(', ')}`);
    }
    
    if (!this.isValidAddress(data.address)) {
      throw new Error('Invalid contract address format');
    }
    
    if (typeof data.floor_price !== 'number' || data.floor_price < 0) {
      throw new Error('Invalid floor price');
    }
    
    return true;
  }

  /**
   * Rate limiting for API calls
   */
  async withRateLimit(apiCall, provider = 'default') {
    const rateLimits = {
      opensea: { requests: 4, period: 1000 }, // 4 req/sec
      alchemy: { requests: 5, period: 1000 }, // 5 req/sec
      coingecko: { requests: 10, period: 60000 }, // 10 req/min
      default: { requests: 1, period: 1000 }
    };
    
    const limit = rateLimits[provider] || rateLimits.default;
    
    // Simple rate limiting implementation
    // In production, use Redis or similar
    await new Promise(resolve => setTimeout(resolve, limit.period / limit.requests));
    
    return apiCall();
  }

  /**
   * Get collection metadata with fallbacks
   */
  async getCollectionMetadata(contractAddress) {
    const errors = [];
    
    // Try Alchemy first
    try {
      const alchemyData = await this.withRateLimit(
        () => this.fetchAlchemyData(contractAddress),
        'alchemy'
      );
      return this.normalizeAlchemyData(alchemyData);
    } catch (error) {
      errors.push(`Alchemy: ${error.message}`);
    }
    
    // Fallback to mock data for demo
    console.warn('All metadata sources failed, using mock data');
    return this.generateMockMetadata(contractAddress);
  }

  /**
   * Normalize Alchemy response
   */
  normalizeAlchemyData(data) {
    return {
      name: data.contractMetadata?.name || 'Unknown Collection',
      symbol: data.contractMetadata?.symbol || '',
      description: data.contractMetadata?.description || '',
      image: data.contractMetadata?.image || '',
      total_supply: parseInt(data.contractMetadata?.totalSupply || '0'),
      contract_type: data.contractMetadata?.tokenType || 'ERC721'
    };
  }

  /**
   * Generate mock metadata for demo
   */
  generateMockMetadata(contractAddress) {
    const mockCollections = {
      '0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D': {
        name: 'Bored Ape Yacht Club',
        symbol: 'BAYC',
        description: 'A collection of 10,000 unique Bored Ape NFTs',
        total_supply: 10000
      },
      '0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB': {
        name: 'CryptoPunks',
        symbol: 'PUNK',
        description: 'The original NFT collection of 10,000 unique punks',
        total_supply: 10000
      }
    };
    
    const defaultMock = mockCollections[contractAddress] || {
      name: 'Unknown Collection',
      symbol: 'UNK',
      description: 'NFT Collection',
      total_supply: 0
    };
    
    return {
      ...defaultMock,
      image: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
      contract_type: 'ERC721'
    };
  }
}

export const nftService = new NFTService();