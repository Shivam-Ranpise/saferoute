const dns = require('dns').promises;

const regions = [
  'ap-south-1',       // Mumbai (India)
  'ap-southeast-1',   // Singapore
  'us-east-1',        // N. Virginia
  'us-west-1',        // N. California
  'eu-central-1',     // Frankfurt
  'eu-west-1',        // Ireland
  'ap-southeast-2',   // Sydney
  'ap-northeast-1',   // Tokyo
  'us-east-2',        // Ohio
];

async function check() {
  for (const r of regions) {
    const host = `aws-0-${r}.pooler.supabase.com`;
    try {
      const addresses = await dns.lookup(host);
      console.log(`Resolved ${host} ->`, addresses.address);
    } catch (e) {
      console.log(`Failed ${host}`);
    }
  }
}

check();
