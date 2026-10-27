// 从纯扫描 PDF 中提取内嵌 JPEG 图像（无第三方依赖）
// 用法: node kaoyan/tools/extract-pdf-jpegs.js <input.pdf> <outDir>
const fs = require('fs');
const path = require('path');

const [, , inPath, outDir] = process.argv;
if (!inPath || !outDir) {
  console.error('usage: node extract-pdf-jpegs.js <input.pdf> <outDir>');
  process.exit(1);
}
fs.mkdirSync(outDir, { recursive: true });

const buf = fs.readFileSync(inPath);
const SOI = Buffer.from([0xff, 0xd8, 0xff]);
const EOI = Buffer.from([0xff, 0xd9]);

let idx = 0;
let n = 0;
while (true) {
  const start = buf.indexOf(SOI, idx);
  if (start === -1) break;
  const end = buf.indexOf(EOI, start + 3);
  if (end === -1) break;
  const jpg = buf.subarray(start, end + 2);
  // 过滤掉过小的图标
  if (jpg.length > 20000) {
    n += 1;
    const out = path.join(outDir, `img-${String(n).padStart(2, '0')}.jpg`);
    fs.writeFileSync(out, jpg);
    console.log(`${out}  ${jpg.length} bytes  (pdf offset ${start})`);
  }
  idx = end + 2;
}
console.log(`done: ${n} image(s) extracted`);
