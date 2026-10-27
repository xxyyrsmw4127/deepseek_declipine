// 解压 PDF 内容流（FlateDecode），查看页面实际绘制指令
// 用法: node kaoyan/tools/pdf-content-dump.js <input.pdf>
const fs = require('fs');
const zlib = require('zlib');

const [, , inPath] = process.argv;
if (!inPath) { console.error('usage: node pdf-content-dump.js <input.pdf>'); process.exit(1); }
const buf = fs.readFileSync(inPath);
const latin = buf.toString('latin1');

// 找出所有 stream ... endstream 段，尝试以 Flate 解压
const re = /stream\r?\n/g;
let m, n = 0;
while ((m = re.exec(latin)) !== null) {
  const start = m.index + m[0].length;
  const end = latin.indexOf('endstream', start);
  if (end === -1) continue;
  let raw = buf.subarray(start, end);
  // 去掉尾部 EOL
  let out = null;
  try { out = zlib.inflateSync(raw); } catch (e) {
    try { out = zlib.inflateRawSync(raw); } catch (e2) { out = null; }
  }
  if (!out) continue;
  n += 1;
  const head = latin.slice(Math.max(0, m.index - 500), m.index);
  const dictMatch = head.match(/<<[^>]*>>\s*$/);
  const dict = dictMatch ? dictMatch[0].replace(/\s+/g, ' ') : '(dict not parsed)';
  console.log(`\n===== stream #${n}  raw=${raw.length}  inflated=${out.length} =====`);
  console.log('dict: ' + dict.slice(0, 400));
  // 若像内容流（含文本算子），打印前 1200 字符
  const s = out.toString('latin1');
  const looksLikeContent = /(Tj|TJ|Td|TD|re|cm|Do|BT)/.test(s);
  if (looksLikeContent) {
    console.log('--- content head ---');
    console.log(s.slice(0, 1200).replace(/[^\x20-\x7e\n\r\t]/g, '.'));
  } else {
    console.log('(binary payload, first 24 bytes hex: ' + out.subarray(0, 24).toString('hex') + ')');
  }
}
console.log(`\ntotal inflated streams: ${n}`);
