import React from 'react';
import { motion } from 'framer-motion';
import { Brain, TrendingUp, Database, Zap } from 'lucide-react';

interface LoadingSpinnerProps {
  message?: string;
  stage?: string;
}

const stages = [
  { icon: Database, text: "Collecting NFT data...", color: "text-blue-400" },
  { icon: Brain, text: "Running AI analysis...", color: "text-purple-400" },
  { icon: TrendingUp, text: "Generating predictions...", color: "text-emerald-400" },
  { icon: Zap, text: "Finalizing results...", color: "text-orange-400" },
];

export const LoadingSpinner: React.FC<LoadingSpinnerProps> = ({ 
  message = "Processing prediction...",
  stage 
}) => {
  const [currentStage, setCurrentStage] = React.useState(0);

  React.useEffect(() => {
    const interval = setInterval(() => {
      setCurrentStage((prev) => (prev + 1) % stages.length);
    }, 2000);

    return () => clearInterval(interval);
  }, []);

  const currentStageData = stages[currentStage];
  const IconComponent = currentStageData.icon;

  return (
    <div className="flex flex-col items-center justify-center min-h-[400px] space-y-6">
      {/* Main spinning loader */}
      <motion.div
        className="relative"
        animate={{ rotate: 360 }}
        transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
      >
        <div className="w-16 h-16 border-4 border-gray-700 border-t-emerald-400 rounded-full"></div>
        <motion.div
          className="absolute inset-0 flex items-center justify-center"
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ delay: 0.2 }}
        >
          <IconComponent className={`w-6 h-6 ${currentStageData.color}`} />
        </motion.div>
      </motion.div>

      {/* Stage indicator */}
      <div className="text-center space-y-3">
        <motion.h3
          key={currentStage}
          className={`text-lg font-medium ${currentStageData.color}`}
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -10 }}
        >
          {currentStageData.text}
        </motion.h3>
        
        <p className="text-gray-400 text-sm">{message}</p>
      </div>

      {/* Progress indicators */}
      <div className="flex space-x-2">
        {stages.map((_, index) => (
          <motion.div
            key={index}
            className={`w-2 h-2 rounded-full ${
              index === currentStage ? 'bg-emerald-400' : 'bg-gray-600'
            }`}
            animate={{
              scale: index === currentStage ? 1.2 : 1,
              opacity: index === currentStage ? 1 : 0.5,
            }}
            transition={{ duration: 0.3 }}
          />
        ))}
      </div>

      {/* Julia agents status */}
      <div className="mt-8 grid grid-cols-2 gap-4 text-xs text-gray-500">
        {stages.map((stageData, index) => {
          const StageIcon = stageData.icon;
          return (
            <motion.div
              key={index}
              className={`flex items-center space-x-2 p-2 rounded-lg border ${
                index <= currentStage 
                  ? 'border-emerald-500/30 bg-emerald-500/10' 
                  : 'border-gray-700 bg-gray-800/50'
              }`}
              initial={{ opacity: 0.5 }}
              animate={{ opacity: index <= currentStage ? 1 : 0.5 }}
            >
              <StageIcon className={`w-4 h-4 ${index <= currentStage ? stageData.color : 'text-gray-600'}`} />
              <span className={index <= currentStage ? 'text-gray-300' : 'text-gray-600'}>
                Agent {index + 1}
              </span>
              {index <= currentStage && (
                <motion.div
                  className="w-2 h-2 bg-emerald-400 rounded-full"
                  animate={{ opacity: [1, 0.3, 1] }}
                  transition={{ duration: 1, repeat: Infinity }}
                />
              )}
            </motion.div>
          );
        })}
      </div>
    </div>
  );
};