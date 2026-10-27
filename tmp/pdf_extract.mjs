import fs from 'node:fs';
import zlib from 'node:zlib';

const p = process.argv[2];
const buf = fs.readFileSync(p);
const latin = buf.toString('latin1');

// 找所有 stream ... endstream
const out = [];
const re = /stream\r?\n/g;
let m;
while ((m = re.exec(latin)) !== null) {
  const start = m.index + m[0].length;
  const end = latin.indexOf('endstream', start);
  if (end < 0) continue;
  let raw = buf.subarray(start, end);
  // 去掉尾部换行
  let s = raw.toString('latin1');
  if (s.endsWith('\r\n')) raw = raw.subarray(0, raw.length - 2);
  else if (s.endsWith('\n')) raw = raw.subarray(0, raw.length - 1);
  try {
    const inf = zlib.inflateSync(raw);
    out.push(inf.toString('latin1'));
  } catch {
    // 未压缩流
    out.push(raw.toString('latin1'));
  }
}
fs.writeFileSync(process.argv[3], out.join('\n\n=====STREAM=====\n\n'), 'latin1');
console.log('streams:', out.length);
