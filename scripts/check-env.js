#!/usr/bin/env node

/**
 * Environment Configuration Checker
 * Validates that all required API keys and configuration are properly set
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Color codes for console output
const colors = {
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  reset: '\x1b[0m'
};

function log(color, message) {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function checkEnvFile(filePath, required = []) {
  if (!fs.existsSync(filePath)) {
    log('red', `❌ ${filePath} not found`);
    return false;
  }

  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split('\n');
  const env = {};
  
  // Parse environment variables
  lines.forEach(line => {
    const match = line.match(/^([A-Z_]+)=(.*)$/);
    if (match) {
      env[match[1]] = match[2];
    }
  });

  log('green', `✅ ${filePath} found`);
  
  // Check required variables
  const missing = [];
  const configured = [];
  
  required.forEach(key => {
    if (!env[key] || env[key].includes('your_') || env[key] === '') {
      missing.push(key);
    } else {
      configured.push(key);
    }
  });

  if (configured.length > 0) {
    log('green', `   ✅ Configured: ${configured.join(', ')}`);
  }
  
  if (missing.length > 0) {
    log('yellow', `   ⚠️  Missing: ${missing.join(', ')}`);
  }

  return missing.length === 0;
}

function checkJuliaEnvironment() {
  const agentsPath = path.join(__dirname, '..', 'agents');
  
  // Check if agents directory exists
  if (!fs.existsSync(agentsPath)) {
    log('red', '❌ Agents directory not found');
    return false;
  }

  // Check for Project.toml
  const projectToml = path.join(agentsPath, 'Project.toml');
  if (!fs.existsSync(projectToml)) {
    log('red', '❌ agents/Project.toml not found');
    return false;
  }

  // Check for agent files
  const agentFiles = [
    'data_collector.jl',
    'ai_analyzer.jl', 
    'price_predictor.jl',
    'swarm_coordinator.jl'
  ];

  const missingAgents = agentFiles.filter(file => 
    !fs.existsSync(path.join(agentsPath, file))
  );

  if (missingAgents.length > 0) {
    log('red', `❌ Missing agent files: ${missingAgents.join(', ')}`);
    return false;
  }

  log('green', '✅ Julia environment configured');
  return true;
}

function checkNodeModules() {
  const rootModules = path.join(__dirname, '..', 'node_modules');
  const backendModules = path.join(__dirname, '..', 'backend', 'node_modules');
  
  if (!fs.existsSync(rootModules)) {
    log('red', '❌ Root node_modules not found - run: npm install');
    return false;
  }
  
  if (!fs.existsSync(backendModules)) {
    log('red', '❌ Backend node_modules not found - run: cd backend && npm install');
    return false;
  }
  
  log('green', '✅ Node.js dependencies installed');
  return true;
}

function printSetupInstructions() {
  log('blue', '\n📋 Setup Instructions:');
  console.log('');
  
  log('yellow', '1. Get Free API Keys:');
  console.log('   • OpenSea: https://docs.opensea.io/reference/api-keys');
  console.log('   • Alchemy: https://www.alchemy.com/ (free 300M compute units/month)');
  console.log('   • Hugging Face: https://huggingface.co/settings/tokens (free)');
  console.log('   • Groq: https://console.groq.com/ (free tier)');
  console.log('');
  
  log('yellow', '2. Configure Environment:');
  console.log('   • Edit .env and backend/.env files');
  console.log('   • Add your API keys');
  console.log('   • Keep USE_MOCK_DATA=true for development');
  console.log('');
  
  log('yellow', '4. Start Development:');
  console.log('   npm run setup        # Run setup script');
  console.log('   npm run julia:setup  # Start Julia agents');
  console.log('   npm run backend      # Start backend (new terminal)');
  console.log('   npm run dev          # Start frontend (new terminal)');
  console.log('');
  
  log('yellow', '5. Alternative - Start Everything:');
  console.log('   npm run start:all    # Starts all services');
  console.log('');
}

function main() {
  log('blue', '🔍 JuliaOS NFT Predictor - Environment Check\n');
  
  let allGood = true;
  
  // Check environment files
  const rootEnvGood = checkEnvFile('.env', [
    'OPENSEA_API_KEY',
    'ALCHEMY_API_KEY', 
    'HUGGINGFACE_API_KEY'
  ]);
  
  const backendEnvGood = checkEnvFile('backend/.env', [
    'OPENSEA_API_KEY',
    'ALCHEMY_API_KEY',
    'HUGGINGFACE_API_KEY'
  ]);
  
  // Check Julia environment
  const juliaGood = checkJuliaEnvironment();
  
  // Check Node.js dependencies
  const nodeGood = checkNodeModules();
  
  allGood = rootEnvGood && backendEnvGood && juliaGood && nodeGood;
  
  console.log('');
  
  if (allGood) {
    log('green', '🎉 Environment check passed! Ready to start development.');
    console.log('');
    log('blue', 'Quick start:');
    console.log('   npm run start:all');
  } else {
    log('red', '❌ Environment check failed. Please fix the issues above.');
    printSetupInstructions();
  }
  
  process.exit(allGood ? 0 : 1);
}

main();