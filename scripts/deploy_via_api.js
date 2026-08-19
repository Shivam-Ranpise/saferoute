const fs = require('fs');
const path = require('path');

const PROJECT_REF = process.env.SUPABASE_PROJECT_REF || 'usexaanovsmmzjorlkyu';
const ACCESS_TOKEN = process.env.SUPABASE_ACCESS_TOKEN || '';

async function executeSql(query) {
  const url = `https://api.supabase.com/v1/projects/${PROJECT_REF}/database/query`;
  
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${ACCESS_TOKEN}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ query }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`HTTP ${response.status}: ${text}`);
  }

  return await response.json();
}

async function run() {
  const schemaPath = path.join(__dirname, '../supabase/consolidated_schema_and_migrations.sql');
  console.log(`Reading SQL file from: ${schemaPath}`);
  
  const sql = fs.readFileSync(schemaPath, 'utf8');
  console.log(`SQL file size: ${sql.length} bytes`);
  
  console.log('Sending schema execution request to Supabase API...');
  const result = await executeSql(sql);
  console.log('Execution result:', JSON.stringify(result, null, 2));
  console.log('✅ Schema & Migrations deployed successfully via API!');
}

run().catch(err => {
  console.error('❌ Error executing deployment:', err);
  process.exit(1);
});
