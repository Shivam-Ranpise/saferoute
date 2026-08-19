const https = require('https');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const os = require('os');

const artifacts = [
  {
    group: 'org.jetbrains.kotlin',
    name: 'kotlin-gradle-plugin',
    version: '2.2.20',
    filename: 'kotlin-gradle-plugin-2.2.20-gradle88.jar',
    url: 'https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-gradle-plugin/2.2.20/kotlin-gradle-plugin-2.2.20-gradle88.jar'
  },
  {
    group: 'org.jetbrains.kotlin',
    name: 'kotlin-gradle-plugin-api',
    version: '2.2.20',
    filename: 'kotlin-gradle-plugin-api-2.2.20.jar',
    url: 'https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-gradle-plugin-api/2.2.20/kotlin-gradle-plugin-api-2.2.20.jar'
  },
  {
    group: 'org.jetbrains.kotlin',
    name: 'kotlin-gradle-plugin-idea-proto',
    version: '2.2.20',
    filename: 'kotlin-gradle-plugin-idea-proto-2.2.20.jar',
    url: 'https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-gradle-plugin-idea-proto/2.2.20/kotlin-gradle-plugin-idea-proto-2.2.20.jar'
  },
  {
    group: 'org.jetbrains.kotlin',
    name: 'kotlin-native-utils',
    version: '2.2.20',
    filename: 'kotlin-native-utils-2.2.20.jar',
    url: 'https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-native-utils/2.2.20/kotlin-native-utils-2.2.20.jar'
  },
  {
    group: 'org.jetbrains.kotlinx',
    name: 'kotlinx-coroutines-core-jvm',
    version: '1.8.0',
    filename: 'kotlinx-coroutines-core-jvm-1.8.0.jar',
    url: 'https://repo1.maven.org/maven2/org/jetbrains/kotlinx/kotlinx-coroutines-core-jvm/1.8.0/kotlinx-coroutines-core-jvm-1.8.0.jar'
  },
  {
    group: 'org.jetbrains.kotlin',
    name: 'fus-statistics-gradle-plugin',
    version: '2.2.20',
    filename: 'fus-statistics-gradle-plugin-2.2.20-gradle88.jar',
    url: 'https://repo1.maven.org/maven2/org/jetbrains/kotlin/fus-statistics-gradle-plugin/2.2.20/fus-statistics-gradle-plugin-2.2.20-gradle88.jar'
  },
  {
    group: 'org.jetbrains.kotlin',
    name: 'kotlin-util-klib',
    version: '2.2.20',
    filename: 'kotlin-util-klib-2.2.20.jar',
    url: 'https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-util-klib/2.2.20/kotlin-util-klib-2.2.20.jar'
  },
  {
    group: 'com.google.code.gson',
    name: 'gson',
    version: '2.11.0',
    filename: 'gson-2.11.0.jar',
    url: 'https://repo1.maven.org/maven2/com/google/code/gson/gson/2.11.0/gson-2.11.0.jar'
  }
];

function download(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return download(res.headers.location).then(resolve, reject);
      }
      if (res.statusCode !== 200) {
        return reject(new Error(`Failed to download ${url}: status ${res.statusCode}`));
      }
      const chunks = [];
      res.on('data', chunk => chunks.push(chunk));
      res.on('end', () => resolve(Buffer.concat(chunks)));
      res.on('error', reject);
    }).on('error', reject);
  });
}

async function main() {
  console.log('Downloading Gradle plugin dependencies via Node.js (OpenSSL engine)...');
  const userHome = os.homedir();

  for (const item of artifacts) {
    console.log(`Downloading ${item.filename}...`);
    try {
      const buffer = await download(item.url);
      const sha1 = crypto.createHash('sha1').update(buffer).digest('hex');
      const groupPath = item.group.replace(/\./g, path.sep);
      const targetDir = path.join(userHome, '.gradle', 'caches', 'modules-2', 'files-2.1', groupPath, item.name, item.version, sha1);
      
      fs.mkdirSync(targetDir, { recursive: true });
      const targetFile = path.join(targetDir, item.filename);
      fs.writeFileSync(targetFile, buffer);
      console.log(`  ✅ Cached at: ${targetFile} (SHA1: ${sha1}, Size: ${(buffer.length / 1024 / 1024).toFixed(2)} MB)`);
    } catch (err) {
      console.error(`  ❌ Failed to download ${item.filename}:`, err.message);
    }
  }
  console.log('\n🎉 Pre-caching complete!');
}

main();
