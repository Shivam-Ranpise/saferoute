const fs = require('fs');
const path = require('path');

const content = fs.readFileSync(path.join(__dirname, '..', 'supabase', 'migrations', '001_initial_schema.sql'), 'utf8');

const regex = /CREATE TABLE\s+(?:IF NOT EXISTS\s+)?(\w+)/g;
let match;
console.log('Tables defined in 001_initial_schema.sql:');
while ((match = regex.exec(content)) !== null) {
  console.log(' - ' + match[1]);
}
