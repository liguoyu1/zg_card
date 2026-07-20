import { defineConfig } from '@prisma/client/config';

export default defineConfig({
  earlyAccess: true,
  schema: './prisma/schema.prisma',
  migrate: {
    adapter: async () => {
      const { PrismaPostgres } = await import('@prisma/adapter-pg');
      const { Pool } = await import('pg');
      
      const connectionString = process.env.DATABASE_URL || 'postgresql://postgres:password@localhost:5432/railway';
      const pool = new Pool({ connectionString });
      
      return new PrismaPostgres(pool);
    },
  },
});