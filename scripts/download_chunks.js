const https = require('https');
const fs = require('fs');
const path = require('path');
const os = require('os');
const crypto = require('crypto');

function getFileSize(url) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, { method: 'HEAD', agent: new https.Agent({ keepAlive: false }) }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return getFileSize(res.headers.location).then(resolve, reject);
      }
      resolve({
        url: res.headers.location || url,
        size: parseInt(res.headers['content-length'] || '0', 10),
        acceptRanges: res.headers['accept-ranges'] === 'bytes'
      });
    });
    req.on('error', reject);
    req.end();
  });
}

function downloadChunk(url, start, end) {
  return new Promise((resolve, reject) => {
    const options = {
      headers: {
        'Range': `bytes=${start}-${end}`
      },
      agent: new https.Agent({ keepAlive: false })
    };
    const req = https.get(url, options, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return downloadChunk(res.headers.location, start, end).then(resolve, reject);
      }
      const chunks = [];
      res.on('data', chunk => chunks.push(chunk));
      res.on('end', () => resolve(Buffer.concat(chunks)));
      res.on('error', reject);
    });
    req.on('error', reject);
  });
}

async function downloadFileInChunks(url, destPath, chunkSize = 256 * 1024) {
  const info = await getFileSize(url);
  const totalSize = info.size;
  console.log(`\nDownloading ${path.basename(destPath)} (${(totalSize / 1024 / 1024).toFixed(2)} MB in chunks of ${chunkSize / 1024} KB)...`);
  
  const fd = fs.openSync(destPath, 'w');
  let downloaded = 0;

  while (downloaded < totalSize) {
    const start = downloaded;
    const end = Math.min(downloaded + chunkSize - 1, totalSize - 1);
    
    let retries = 10;
    let chunk = null;
    while (retries > 0) {
      try {
        chunk = await downloadChunk(info.url, start, end);
        if (chunk && chunk.length > 0) break;
      } catch (err) {
        retries--;
        if (retries === 0) throw err;
        await new Promise(r => setTimeout(r, 200));
      }
    }
    fs.writeSync(fd, chunk, 0, chunk.length, start);
    downloaded += chunk.length;
    process.stdout.write(`\r  Progress: ${((downloaded / totalSize) * 100).toFixed(1)}%`);
  }
  fs.closeSync(fd);
  console.log(`\n  ✅ Complete: ${destPath}`);
}

async function main() {
  const artifacts = [
    {
      group: 'org.jetbrains.kotlin',
      name: 'kotlin-stdlib',
      version: '2.0.21',
      filename: 'kotlin-stdlib-2.0.21.jar',
      url: 'https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-stdlib/2.0.21/kotlin-stdlib-2.0.21.jar'
    },
    {
      group: 'org.jetbrains.kotlin',
      name: 'kotlin-script-runtime',
      version: '2.0.21',
      filename: 'kotlin-script-runtime-2.0.21.jar',
      url: 'https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-script-runtime/2.0.21/kotlin-script-runtime-2.0.21.jar'
    },
    {
      group: 'org.jetbrains.kotlin',
      name: 'kotlin-reflect',
      version: '2.0.21',
      filename: 'kotlin-reflect-2.0.21.jar',
      url: 'https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-reflect/2.0.21/kotlin-reflect-2.0.21.jar'
    },
    {
      group: 'org.jetbrains.kotlin',
      name: 'kotlin-tooling-core',
      version: '2.0.21',
      filename: 'kotlin-tooling-core-2.0.21.jar',
      url: 'https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-tooling-core/2.0.21/kotlin-tooling-core-2.0.21.jar'
    },
    {
      group: 'org.jetbrains.kotlin',
      name: 'kotlin-build-common',
      version: '2.0.21',
      filename: 'kotlin-build-common-2.0.21.jar',
      url: 'https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-build-common/2.0.21/kotlin-build-common-2.0.21.jar'
    }
  ];

  const userHome = os.homedir();
  const m2Base = path.join(userHome, '.m2', 'repository');

  for (const item of artifacts) {
    const tempDest = path.join(os.tmpdir(), item.filename);
    await downloadFileInChunks(item.url, tempDest);
    
    const buffer = fs.readFileSync(tempDest);
    const sha1 = crypto.createHash('sha1').update(buffer).digest('hex');
    const groupPath = item.group.replace(/\./g, path.sep);
    
    // Cache in Gradle Cache
    const targetDir = path.join(userHome, '.gradle', 'caches', 'modules-2', 'files-2.1', groupPath, item.name, item.version, sha1);
    fs.mkdirSync(targetDir, { recursive: true });
    const targetFile = path.join(targetDir, item.filename);
    fs.writeFileSync(targetFile, buffer);
    console.log(`  🎯 Placed in Gradle Cache: ${targetFile}`);

    // Cache in mavenLocal
    const m2Dir = path.join(m2Base, groupPath, item.name, item.version);
    fs.mkdirSync(m2Dir, { recursive: true });
    fs.copyFileSync(tempDest, path.join(m2Dir, item.filename));
    console.log(`  🎯 Placed in mavenLocal: ${path.join(m2Dir, item.filename)}\n`);
  }
  console.log('🎉 All standard Kotlin libraries cached successfully!');
}

main().catch(err => {
  console.error('Fatal download error:', err);
  process.exit(1);
});
