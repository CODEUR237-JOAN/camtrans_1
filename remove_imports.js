const fs = require('fs');
const path = require('path');

const importRegex = /import\s+'package:flutter_animate\/flutter_animate\.dart';\r?\n?/g;

function removeImports(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  if (importRegex.test(content)) {
    const newContent = content.replace(importRegex, '');
    fs.writeFileSync(filePath, newContent, 'utf8');
    console.log('Removed import from: ' + filePath);
  }
}

function walkSync(currentDirPath) {
  fs.readdirSync(currentDirPath).forEach((name) => {
    const filePath = path.join(currentDirPath, name);
    const stat = fs.statSync(filePath);
    if (stat.isFile()) {
      if (filePath.endsWith('.dart')) {
        removeImports(filePath);
      }
    } else if (stat.isDirectory()) {
      walkSync(filePath);
    }
  });
}

walkSync('./lib');
