const fs = require('fs');
const path = require('path');

function walk(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    list.forEach(file => {
        file = path.join(dir, file);
        const stat = fs.statSync(file);
        if (stat && stat.isDirectory()) {
            results = results.concat(walk(file));
        } else {
            if (file.endsWith('.dart')) results.push(file);
        }
    });
    return results;
}

const files = walk('./lib');
let modifiedCount = 0;

for (const file of files) {
    const content = fs.readFileSync(file, 'utf8');
    if (content.includes('animate') && !content.includes('package:flutter_animate/flutter_animate.dart')) {
        const importStatement = "import 'package:flutter_animate/flutter_animate.dart';\n";
        
        // Find the last import
        const lines = content.split('\n');
        let lastImportIndex = -1;
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].trim().startsWith('import ')) {
                lastImportIndex = i;
            }
        }
        
        if (lastImportIndex !== -1) {
            lines.splice(lastImportIndex + 1, 0, importStatement);
        } else {
            lines.unshift(importStatement);
        }
        
        fs.writeFileSync(file, lines.join('\n'), 'utf8');
        modifiedCount++;
        console.log(`Added import to ${file}`);
    }
}

console.log(`Modified ${modifiedCount} files.`);
