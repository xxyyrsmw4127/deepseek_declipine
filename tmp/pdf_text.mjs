import fs from 'node:fs';
const t = fs.readFileSync('D:/deepseek_dsh/tmp/pdf_streams.txt', 'latin1');

// 抽取括号字符串
const strs = [];
let i = 0;
while (i < t.length) {
  if (t[i] === '(') {
    let depth = 1, j = i + 1, s = '';
    while (j < t.length && depth > 0) {
      const c = t[j];
      if (c === '\\') { s += t[j + 1] ?? ''; j += 2; continue; }
      if (c === '(') depth++;
      else if (c === ')') { depth--; if (depth === 0) break; }
      s += c; j++;
    }
    if (s.length > 0) strs.push(s);
    i = j + 1;
  } else i++;
}
const sample = strs.slice(0, 60).join(' | ');
fs.writeFileSync('D:/deepseek_dsh/tmp/pdf_paren.txt', sample, 'latin1');
console.log('paren strings:', strs.length);
console.log('first 800:', sample.slice(0, 800));
