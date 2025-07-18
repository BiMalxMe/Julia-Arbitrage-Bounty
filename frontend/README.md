# ChainGuardian Frontend

A modern React frontend for the ChainGuardian Solana Wallet Risk Analysis platform.

## Features

- **Dashboard**: Overview of system health and quick actions
- **Wallet Analyzer**: Comprehensive risk analysis for Solana wallets
- **System Status**: Real-time monitoring of backend services
- **Configuration**: Dynamic configuration management
- **Modern UI**: Beautiful dark theme with Tailwind CSS
- **Real-time Updates**: Live polling of system status
- **Responsive Design**: Works on desktop and mobile devices

## Getting Started

### Prerequisites

- Node.js 16+ 
- npm or yarn
- ChainGuardian backend running on port 8080

### Installation

1. Install dependencies:
```bash
npm install
```

2. Start the development server:
```bash
npm start
```

3. Open [http://localhost:3000](http://localhost:3000) in your browser.

### Building for Production

```bash
npm run build
```

This creates a `build` folder with the production-ready files.

## Project Structure

```
src/
├── components/          # React components
│   ├── Dashboard.js     # Main dashboard
│   ├── WalletAnalyzer.js # Wallet analysis interface
│   ├── SystemStatus.js  # System monitoring
│   ├── Configuration.js # Configuration management
│   └── Header.js        # Navigation header
├── services/           # API services
│   └── api.js          # API client and utilities
├── App.js              # Main app component
├── index.js            # App entry point
└── index.css           # Global styles
```

## API Integration

The frontend communicates with the ChainGuardian backend via REST API:

- **GET /status** - System status and metadata
- **GET /health** - Health check
- **GET /config** - Configuration
- **PUT /config** - Update configuration
- **GET /swarm/status** - Swarm status
- **GET /risk/{address}** - Quick risk analysis
- **POST /risk/analyze** - Comprehensive analysis
- **POST /swarm/submit** - Submit swarm task
- **GET /task/{id}** - Task status

## Configuration

The frontend is configured to proxy requests to `http://localhost:8080` by default. You can change this by setting the `REACT_APP_API_URL` environment variable.

## Technologies Used

- **React 18** - UI framework
- **Tailwind CSS** - Styling
- **Lucide React** - Icons
- **Axios** - HTTP client
- **React Router** - Navigation

## Development

### Available Scripts

- `npm start` - Start development server
- `npm build` - Build for production
- `npm test` - Run tests
- `npm eject` - Eject from Create React App

### Code Style

The project uses:
- ESLint for code linting
- Prettier for code formatting
- Tailwind CSS for styling

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details.