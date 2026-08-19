const fs = require('fs');
const path = require('path');
const { Client } = require('pg');

async function run() {
  const connectionConfig = {
    host: 'db.usexaanovsmmzjorlkyu.supabase.co',
    port: 5432,
    database: 'postgres',
    user: 'postgres',
    password: 'ShivDnya@2708',
    ssl: {
      rejectUnauthorized: false,
    },
  };

  console.log('Connecting to Supabase PostgreSQL at:', connectionConfig.host);
  const client = new Client(connectionConfig);

  try {
    await client.connect();
    console.log('Successfully connected to Supabase PostgreSQL!');

    const sqlPath = path.join(__dirname, '..', 'supabase', 'consolidated_schema_and_migrations.sql');
    console.log('Reading migration file:', sqlPath);
    const sqlContent = fs.readFileSync(sqlPath, 'utf8');

    console.log('Executing consolidated migrations (this may take 5-15 seconds)...');
    await client.query(sqlContent);
    console.log('=== MIGRATIONS EXECUTED SUCCESSFULLY ===');

    // Verify tables created
    const res = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name;
    `);

    console.log('\nVerified Created Tables:');
    res.rows.forEach(r => console.log(' - ' + r.table_name));

    // Verify organization seed
    const orgs = await client.query(`SELECT id, name FROM organizations;`);
    console.log('\nVerified Seed Organizations:');
    orgs.rows.forEach(o => console.log(` - ${o.name} (${o.id})`));

  } catch (err) {
    console.error('Error applying migrations:', err);
    process.exit(1);
  } finally {
    await client.end();
  }
}

run();
