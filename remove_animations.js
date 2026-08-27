const fs = require('fs');
const path = require('path');

// Expression régulière pour attraper .animate() et tous les appels de méthodes chaînés qui suivent
// Ex: .animate().fadeIn(delay: 500.ms).slideX(begin: 0.1)
const animateRegex = /\.animate\(\)(?:\s*\.[a-zA-Z_]+\([^)]*\))*/g;

function removeAnimations(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  if (animateRegex.test(content)) {
    const newContent = content.replace(animateRegex, '');
    fs.writeFileSync(filePath, newContent, 'utf8');
    console.log('Removed animations from: ' + filePath);
  }
}

function walkSync(currentDirPath) {
  fs.readdirSync(currentDirPath).forEach((name) => {
    const filePath = path.join(currentDirPath, name);
    const stat = fs.statSync(filePath);
    if (stat.isFile()) {
      if (filePath.endsWith('.dart')) {
        removeAnimations(filePath);
      }
    } else if (stat.isDirectory()) {
      walkSync(filePath);
    }
  });
}

walkSync('./lib');
