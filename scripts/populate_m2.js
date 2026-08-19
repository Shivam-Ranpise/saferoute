const fs = require('fs');
const path = require('path');
const os = require('os');
const https = require('https');

const m2Base = path.join(os.homedir(), '.m2', 'repository');

const artifacts = [
  {
    group: 'org.jetbrains.kotlin',
    name: 'kotlin-compiler-embeddable',
    version: '2.0.21',
    filename: 'kotlin-compiler-embeddable-2.0.21.jar'
  },
  {
    group: 'org.jetbrains.kotlin',
    name: 'kotlin-gradle-plugin',
    version: '2.0.21',
    filename: 'kotlin-gradle-plugin-2.0.21-gradle85.jar'
  },
  {
    group: 'org.jetbrains.kotlin',
    name: 'kotlin-gradle-plugin-api',
    version: '2.0.21',
    filename: 'kotlin-gradle-plugin-api-2.0.21-gradle85.jar'
  },
  {
    group: 'org.jetbrains.kotlin',
    name: 'kotlin-gradle-plugin-idea-proto',
    version: '2.0.21',
    filename: 'kotlin-gradle-plugin-idea-proto-2.0.21.jar'
  },
  {
    group: 'org.jetbrains.kotlin',
    name: 'kotlin-daemon-client',
    version: '2.0.21',
    filename: 'kotlin-daemon-client-2.0.21.jar'
  },
  {
    group: 'org.jetbrains.kotlin',
    name: 'kotlin-daemon-embeddable',
    version: '2.0.21',
    filename: 'kotlin-daemon-embeddable-2.0.21.jar'
  }
];

function downloadPom(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return downloadPom(res.headers.location).then(resolve, reject);
      }
      if (res.statusCode !== 200) return resolve(null);
      const chunks = [];
      res.on('data', c => chunks.push(c));
      res.on('end', () => resolve(Buffer.concat(chunks)));
      res.on('error', () => resolve(null));
    }).on('error', () => resolve(null));
  });
}

async function main() {
  console.log('Populating local Maven repository (.m2)...');
  for (const item of artifacts) {
    const groupPath = item.group.replace(/\./g, path.sep);
    const targetDir = path.join(m2Base, groupPath, item.name, item.version);
    fs.mkdirSync(targetDir, { recursive: true });

    // Copy JAR from temp
    const tempFile = path.join(os.tmpdir(), item.filename);
    if (fs.existsSync(tempFile)) {
      const destJar = path.join(targetDir, item.filename);
      fs.copyFileSync(tempFile, destJar);
      console.log(`  ✅ Copied JAR to mavenLocal: ${destJar}`);
    }

    // Download POM
    const pomUrl = `https://repo1.maven.org/maven2/${item.group.replace(/\./g, '/')}/${item.name}/${item.version}/${item.name}-${item.version}.pom`;
    const pomBuffer = await downloadPom(pomUrl);
    if (pomBuffer) {
      const pomPath = path.join(targetDir, `${item.name}-${item.version}.pom`);
      fs.writeFileSync(pomPath, pomBuffer);
      console.log(`  ✅ Wrote POM to mavenLocal: ${pomPath}`);
    }
  }
  console.log('🎉 mavenLocal populated successfully!');
}

main();
