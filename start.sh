#!/bin/bash

# ChainGuardian Startup Script
# This script starts both the Julia backend and React frontend

echo "🛡️  ChainGuardian - Solana Wallet Risk Analysis dApp"
echo "=================================================="

# Check if Julia is installed
if ! command -v julia &> /dev/null; then
    echo "❌ Julia is not installed. Please install Julia 1.8+ first."
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 16+ first."
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Function to cleanup background processes
cleanup() {
    echo "🛑 Shutting down ChainGuardian..."
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Start backend
echo "🚀 Starting ChainGuardian backend..."
julia chainguardian.jl &
BACKEND_PID=$!

# Wait a moment for backend to start
sleep 3

# Check if backend started successfully
if ! curl -s http://localhost:8080/health > /dev/null; then
    echo "❌ Backend failed to start. Check the logs above."
    exit 1
fi

echo "✅ Backend started successfully on http://localhost:8080"

# Start frontend
echo "🎨 Starting ChainGuardian frontend..."
cd frontend
npm start &
FRONTEND_PID=$!
cd ..

echo "✅ Frontend started successfully on http://localhost:3000"
echo ""
echo "🌐 Access the application:"
echo "   Frontend: http://localhost:3000"
echo "   Backend API: http://localhost:8080"
echo ""
echo "Press Ctrl+C to stop both services"
echo "=================================================="

# Wait for both processes
wait