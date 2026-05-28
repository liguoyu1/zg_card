import { defineEventHandler } from 'h3';

export default defineEventHandler(() => {
  return { 
    status: 'ok', 
    message: 'Warring States Card API',
    timestamp: new Date().toISOString() 
  };
});
