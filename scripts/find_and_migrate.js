const fs = require('fs');
const path = require('path');
const { Client } = require('pg');

const regions = [
  'ap-south-1',       // Mumbai (India)
  'ap-southeast-1',   // Singapore
  'us-east-1',        // N. Virginia
  'eu-central-1',     // Frankfurt
  'us-west-1',        // N. California
  'eu-west-1',        // Ireland
  'ap-southeast-2',   // Sydney
  'ap-northeast-1',   // Tokyo
  'us-east-2',        // Ohio
];

async function tryMigrate() {
  const sqlPath = path.join(__dirname, '..', 'supabase', 'consolidated_schema_and_migrations.sql');
  const sqlContent = fs.readFileSync(sqlPath, 'utf8');

  for (const r of regions) {
    const host = `aws-0-${r}.pooler.supabase.com`;
    console.log(`\nTesting connection to region [${r}] (${host})...`);

    const client = new Client({
      host: host,
      port: 65432, // Session pooler port
      database: 'postgres',
      user: 'postgres.usexaanovsmmzjorlkyu',
      password: 'ShivDnya@2708',
      ssl: { rejectUnauthorized: false },
      connectionTimeoutMillis: 5000,
    });

    try {
      await client.connect();
      console.log(`>>> CONNECTED TO SUPABASE POSTGRESQL IN REGION: ${r} <<<`);
      console.log('Executing consolidated migrations (this may take 10-20 seconds)...');
      
      await client.query(sqlContent);
      console.log('\n=== ALL MIGRATIONS EXECUTED SUCCESSFULLY ON REMOTE DB ===');

      // Verify created tables
      const res = await client.query(`
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        ORDER BY table_name;
      `);

      console.log('\nVerified Created Tables in Supabase:');
      res.rows.forEach(row => console.log('  [OK] ' + row.table_name));

      // Verify seed organizations
      const orgs = await client.query(`SELECT id, name FROM organizations;`);
      console.log('\nVerified Seed Organizations:');
      orgs.rows.forEach(o => console.log(`  [OK] ${o.name} (${o.id})`));

      await client.end();
      return;
    } catch (err) {
      console.log(`Region ${r} connection failed: ${err.message}`);
      try { await client.end(); } catch (e) {}
    }
  }

  console.error('\nCould not connect automatically across standard regions.');
}

tryMigrate();
