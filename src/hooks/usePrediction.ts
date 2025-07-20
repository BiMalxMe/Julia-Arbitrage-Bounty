import { useState, useCallback } from 'react';
import { PredictionResponse } from '../types';
import { nftApi } from '../utils/api';

interface UsePredictionState {
  data: PredictionResponse | null;
  loading: boolean;
  error: string | null;
}

export const usePrediction = () => {
  const [state, setState] = useState<UsePredictionState>({
    data: null,
    loading: false,
    error: null,
  });

  const predict = useCallback(async (collectionAddress: string) => {
    setState(prev => ({ ...prev, loading: true, error: null }));
    
    try {
      const response = await nftApi.predictPrice(collectionAddress);
      setState({
        data: response,
        loading: false,
        error: null,
      });
      return response;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Prediction failed';
      setState({
        data: null,
        loading: false,
        error: errorMessage,
      });
      throw error;
    }
  }, []);

  const reset = useCallback(() => {
    setState({
      data: null,
      loading: false,
      error: null,
    });
  }, []);

  return {
    ...state,
    predict,
    reset,
  };
};