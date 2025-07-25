import express from 'express';
import { juliaService } from '../services/juliaService.js';
import { nftService } from '../services/nftService.js';
import { apiKeyService } from '../services/apiKeyService.js';

const router = express.Router();

// Rate limiting store (in production, use Redis)
const rateLimitStore = new Map();

// Simple rate limiting middleware
const rateLimit = (req, res, next) => {
  // In development, we can bypass the rate limiter for easier testing.
  if (process.env.NODE_ENV === 'development') {
    return next();
  }

  const clientId = req.ip;
  const now = Date.now();
  const windowMs = 15 * 60 * 1000; // 15 minutes
  const maxRequests = 10;

  if (!rateLimitStore.has(clientId)) {
    rateLimitStore.set(clientId, { count: 1, resetTime: now + windowMs });
    return next();
  }

  const clientData = rateLimitStore.get(clientId);
  
  if (now > clientData.resetTime) {
    rateLimitStore.set(clientId, { count: 1, resetTime: now + windowMs });
    return next();
  }

  if (clientData.count >= maxRequests) {
    return res.status(429).json({
      success: false,
      message: 'Too many requests. Please try again later.',
      retryAfter: Math.ceil((clientData.resetTime - now) / 1000)
    });
  }

  clientData.count++;
  next();
};

/**
 * POST /api/predict
 * Main prediction endpoint
 */
router.post('/predict', rateLimit, async (req, res) => {
  try {
    const { collection_address } = req.body;

    // Validate input
    if (!collection_address) {
      return res.status(400).json({
        success: false,
        message: 'Collection address is required'
      });
    }

    // Validate Ethereum address format
    if (!nftService.isValidAddress(collection_address)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid Ethereum address format'
      });
    }

    console.log(`Starting prediction for collection: ${collection_address}`);

    // Execute prediction pipeline using Julia agents
    const startTime = Date.now();
    const result = await juliaService.executePredictionPipeline(collection_address);
    const processingTime = (Date.now() - startTime) / 1000;

    if (!result.success) {
      return res.status(500).json({
        success: false,
        message: 'Prediction pipeline failed',
        errors: result.errors,
        timestamp: new Date().toISOString()
      });
    }

    // Format response
    const response = {
      success: true,
      data: result.data,
      timestamp: new Date().toISOString(),
      processing_time: processingTime
    };

    console.log(`Prediction completed in ${processingTime}s`);
    res.json(response);

  } catch (error) {
    console.error('Prediction endpoint error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error during prediction',
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * GET /api/search
 * Search NFT collections
 */
router.get('/search', async (req, res) => {
  try {
    const { q: query } = req.query;

    if (!query || query.length < 2) {
      return res.status(400).json({
        success: false,
        message: 'Query must be at least 2 characters long'
      });
    }

    console.log(`Searching collections for: ${query}`);

    const results = await juliaService.searchCollections(query);
    
    res.json(results);

  } catch (error) {
    console.error('Search endpoint error:', error);
    res.status(500).json({
      success: false,
      message: 'Search failed',
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * GET /api/health
 * Check agent health status
 */
router.get('/health', async (req, res) => {
  try {
    console.log('Checking agent health status');

    const agentStatus = await juliaService.getAgentHealth();
    
    res.json(agentStatus);

  } catch (error) {
    console.error('Health check error:', error);
    res.status(500).json({
      success: false,
      message: 'Health check failed',
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * GET /api/status
 * Get API and service status
 */
router.get('/status', async (req, res) => {
  try {
    const status = {
      ...juliaService.getStatus(),
      api_providers: apiKeyService.getProviderStatus(),
      timestamp: new Date().toISOString()
    };

    res.json(status);
  } catch (error) {
    console.error('Status endpoint error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get status',
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * GET /api/providers
 * Get available API providers
 */
router.get('/providers', async (req, res) => {
  try {
    const providers = apiKeyService.getAvailableProviders();
    res.json(providers);
  } catch (error) {
    console.error('Providers endpoint error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get providers',
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * GET /api/stats
 * Get API usage statistics
 */
router.get('/stats', (req, res) => {
  try {
    const stats = {
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      active_connections: rateLimitStore.size,
      environment: process.env.NODE_ENV || 'development',
      julia_status: 'active',
      ai_providers: ['openrouter', 'huggingface', 'groq'],
      timestamp: new Date().toISOString()
    };

    res.json(stats);

  } catch (error) {
    console.error('Stats endpoint error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch stats',
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * GET /api/opensea-stats/:slug
 * Fetch OpenSea stats for a given collection slug (dynamic)
 */
router.get('/opensea-stats/:slug', async (req, res) => {
  const { slug } = req.params;
  if (!slug) {
    return res.status(400).json({
      success: false,
      message: 'Collection slug is required',
      timestamp: new Date().toISOString()
    });
  }
  try {
    const stats = await nftService.fetchOpenSeaV2Stats(slug);
    res.json({
      success: true,
      slug,
      stats,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('OpenSea stats endpoint error:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch OpenSea stats',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

export default router;