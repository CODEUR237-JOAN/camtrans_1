const fs = require('fs');
const path = require('path');

const emojiRegex = /[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F1E6}-\u{1F1FF}\u{1F004}\u{1F0CF}\u{1F170}-\u{1F251}\u{2B50}\u{2B55}\u{2934}\u{2935}\u{2B05}-\u{2B07}\u{2194}-\u{2199}\u{21A9}-\u{21AA}\u{25AA}-\u{25AB}\u{25B6}\u{25C0}\u{25FB}-\u{25FE}\u{1F004}\u{1F0CF}\u{1F170}-\u{1F251}\u{2B50}\u{2B55}\u{2934}\u{2935}\u{2B05}-\u{2B07}\u{2194}-\u{2199}\u{21A9}-\u{21AA}\u{25AA}-\u{25AB}\u{25B6}\u{25C0}\u{25FB}-\u{25FE}]/gu;

function stripEmojis(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  if (emojiRegex.test(content)) {
    const newContent = content.replace(emojiRegex, '');
    fs.writeFileSync(filePath, newContent, 'utf8');
    console.log('Stripped emojis from: ' + filePath);
  }
}

function walkSync(currentDirPath) {
  fs.readdirSync(currentDirPath).forEach((name) => {
    const filePath = path.join(currentDirPath, name);
    const stat = fs.statSync(filePath);
    if (stat.isFile()) {
      if (filePath.endsWith('.dart') || filePath.endsWith('.js') || filePath.endsWith('.md')) {
        stripEmojis(filePath);
      }
    } else if (stat.isDirectory()) {
      walkSync(filePath);
    }
  });
}

walkSync('./lib');
walkSync('./functions');
