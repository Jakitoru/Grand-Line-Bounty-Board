const fs = require('fs');

try {
  const xml = fs.readFileSync('d:\\Study 2\\Công nghệ mới\\Duancanhan\\temp_docx\\word\\document.xml', 'utf8');
  
  // Extract paragraphs
  const pMatches = xml.match(/<w:p[^>]*>(.*?)<\/w:p>/g);
  if (pMatches) {
    const text = pMatches.map(p => {
      const tMatches = p.match(/<w:t[^>]*>(.*?)<\/w:t>/g);
      if (tMatches) {
        return tMatches.map(t => t.replace(/<[^>]+>/g, '')).join('');
      }
      return '';
    }).filter(p => p.length > 0).join('\n');
    fs.writeFileSync('d:\\Study 2\\Công nghệ mới\\Duancanhan\\one-piece-app\\docx_content.txt', text);
    console.log("Text saved to docx_content.txt");
  } else {
    console.log('No text found');
  }
} catch (e) {
  console.error(e.toString());
}
