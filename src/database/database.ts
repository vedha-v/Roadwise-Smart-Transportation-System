import { Pool } from 'pg';

export const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'roadwise',
  user: 'KIRTI',
});

pool.on('error', (err) => {
  console.error('Unexpected PostgreSQL error:', err);
});