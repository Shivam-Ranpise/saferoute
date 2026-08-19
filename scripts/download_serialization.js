const https = require('https');
const fs = require('fs');
const path = require('path');
const os = require('os');

function download(url, dest) {
  return new Promise((resolve, reject) => {
    https.get(url, { agent: new https.Agent({ keepAlive: false }) }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return download(res.headers.location, dest).then(resolve, reject);
      }
      if (res.statusCode !== 200) return reject(new Error(`Status ${res.statusCode}`));
      const file = fs.createWriteStream(dest);
      res.pipe(file);
      file.on('finish', () => file.close(resolve));
    }).on('error', reject);
  });
}

const items = [
  {
    url: 'https://repo1.maven.org/maven2/org/jetbrains/kotlinx/kotlinx-serialization-core-jvm/1.4.0/kotlinx-serialization-core-jvm-1.4.0.jar',
    path: path.join(os.homedir(), '.m2', 'repository', 'org', 'jetbrains', 'kotlinx', 'kotlinx-serialization-core-jvm', '1.4.0', 'kotlinx-serialization-core-jvm-1.4.0.jar')
  },
  {
    url: 'https://repo1.maven.org/maven2/org/jetbrains/kotlinx/kotlinx-serialization-core-jvm/1.4.0/kotlinx-serialization-core-jvm-1.4.0.pom',
    path: path.join(os.homedir(), '.m2', 'repository', 'org', 'jetbrains', 'kotlinx', 'kotlinx-serialization-core-jvm', '1.4.0', 'kotlinx-serialization-core-jvm-1.4.0.pom')
  },
  {
    url: 'https://repo1.maven.org/maven2/org/jetbrains/kotlinx/kotlinx-serialization-json/1.4.0/kotlinx-serialization-json-1.4.0.jar',
    path: path.join(os.homedir(), '.m2', 'repository', 'org', 'jetbrains', 'kotlinx', 'kotlinx-serialization-json', '1.4.0', 'kotlinx-serialization-json-1.4.0.jar')
  },
  {
    url: 'https://repo1.maven.org/maven2/org/jetbrains/kotlinx/kotlinx-serialization-json/1.4.0/kotlinx-serialization-json-1.4.0.pom',
    path: path.join(os.homedir(), '.m2', 'repository', 'org', 'jetbrains', 'kotlinx', 'kotlinx-serialization-json', '1.4.0', 'kotlinx-serialization-json-1.4.0.pom')
  }
];

async function main() {
  for (const item of items) {
    fs.mkdirSync(path.dirname(item.path), { recursive: true });
    try {
      await download(item.url, item.path);
      console.log(`✅ Cached: ${item.path}`);
    } catch (e) {
      console.error(`❌ Failed: ${item.url}`, e.message);
    }
  }
}

main();
