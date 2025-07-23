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
   * Fetch collection data from OpenSea (now using v2 API for floor price and more)
   */
  async fetchOpenSeaData(collectionSlug) {
    try {
      const headers = {
        'Accept': 'application/json'
      };
      if (process.env.OPENSEA_API_KEY) {
        headers['X-API-KEY'] = process.env.OPENSEA_API_KEY;
      }
      // Use v2 endpoint for stats
      const response = await axios.get(
        `https://api.opensea.io/api/v2/collections/${collectionSlug}/stats`,
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
   * Now tries Alchemy first, then OpenSea v2 for floor price and stats if Alchemy fails or is missing floor price.
   */
  async getCollectionMetadata(contractAddress, collectionSlug = null) {
    const errors = [];
    let meta = null;
    // Try Alchemy first
    try {
      const alchemyData = await this.withRateLimit(
        () => this.fetchAlchemyData(contractAddress),
        'alchemy'
      );
      meta = this.normalizeAlchemyData(alchemyData);
    } catch (error) {
      errors.push(`Alchemy: ${error.message}`);
    }
    // If no meta or missing floor price, try OpenSea v2 if slug is provided
    if ((!meta || meta.floor_price == null) && collectionSlug) {
      try {
        const openSeaStats = await this.fetchOpenSeaData(collectionSlug);
        // Merge OpenSea stats into meta
        meta = {
          ...(meta || {}),
          floor_price: openSeaStats?.total?.floor_price ?? null,
          market_cap: openSeaStats?.total?.market_cap ?? null,
          volume_24h: openSeaStats?.intervals?.find(i => i.interval === 'one_day')?.volume ?? null,
          num_owners: openSeaStats?.total?.num_owners ?? null,
          // Add more fields as needed
        };
      } catch (error) {
        errors.push(`OpenSea: ${error.message}`);
      }
    }
    // Fallback to mock data for demo
    if (!meta) {
      console.warn('All metadata sources failed, using mock data');
      meta = this.generateMockMetadata(contractAddress);
    }
    meta.errors = errors;
    return meta;
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

  /**
   * Fetch collection stats from OpenSea v2 API (dynamic market data)
   */
  async fetchOpenSeaV2Stats(collectionSlug) {
    try {
      const headers = {
        'Accept': 'application/json'
      };
      if (process.env.OPENSEA_API_KEY) {
        headers['X-API-KEY'] = process.env.OPENSEA_API_KEY;
      }
      const response = await axios.get(
        `https://api.opensea.io/api/v2/collections/${collectionSlug}/stats`,
        { headers, timeout: 10000 }
      );
      const stats = response.data;
      return {
        market_cap: stats?.total?.market_cap,
        volume_24h: stats?.total?.volume,
        floor_price: stats?.floor_price
      };
    } catch (error) {
      console.warn('OpenSea v2 API error:', error.message);
      throw error;
    }
  }

  /**
   * Fetch OpenSea collection slug from contract address (v2 API)
   */
  async fetchOpenSeaSlugByAddress(contractAddress) {
    try {
      const headers = {
        'Accept': 'application/json'
      };
      if (process.env.OPENSEA_API_KEY) {
        headers['X-API-KEY'] = process.env.OPENSEA_API_KEY;
      }
      const response = await axios.get(
        `https://api.opensea.io/api/v2/chain/ethereum/contract/${contractAddress}`,
        { headers, timeout: 10000 }
      );
      // The slug is typically in response.data.collection.slug
      return response.data?.collection?.slug;
    } catch (error) {
      console.warn('OpenSea v2 contract lookup error:', error.message);
      throw error;
    }
  }

  /**
   * Fetch OpenSea v2 stats by contract address (address -> slug -> stats)
   */
  async fetchOpenSeaV2StatsByAddress(contractAddress) {
    const slug = await this.fetchOpenSeaSlugByAddress(contractAddress);
    if (!slug) throw new Error('Collection slug not found for contract address');
    return this.fetchOpenSeaV2Stats(slug);
  }
}

export const nftService = new NFTService();