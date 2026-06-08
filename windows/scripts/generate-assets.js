const fs = require("node:fs");
const path = require("node:path");
const zlib = require("node:zlib");

const outDir = path.join(__dirname, "..", "src", "assets");
fs.mkdirSync(outDir, { recursive: true });

function crc32(buffer) {
  let crc = 0xffffffff;
  for (const byte of buffer) {
    crc ^= byte;
    for (let i = 0; i < 8; i += 1) {
      crc = (crc >>> 1) ^ (0xedb88320 & -(crc & 1));
    }
  }
  return (crc ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const typeBuffer = Buffer.from(type);
  const length = Buffer.alloc(4);
  length.writeUInt32BE(data.length);
  const checksum = Buffer.alloc(4);
  checksum.writeUInt32BE(crc32(Buffer.concat([typeBuffer, data])));
  return Buffer.concat([length, typeBuffer, data, checksum]);
}

function makePng(size) {
  const rows = [];
  for (let y = 0; y < size; y += 1) {
    const row = Buffer.alloc(1 + size * 4);
    row[0] = 0;
    for (let x = 0; x < size; x += 1) {
      const index = 1 + x * 4;
      const inCard = x >= 4 && x <= size - 5 && y >= 4 && y <= size - 5;
      const inStem = x >= 9 && x <= 13 && y >= 10 && y <= 23;
      const inBowl = x >= 9 && x <= 22 && y >= 8 && y <= 15;
      const inCutout = x >= 14 && x <= 18 && y >= 11 && y <= 14;
      const inSpark = (x === 23 && y >= 8 && y <= 14) || (y === 11 && x >= 20 && x <= 26);

      let rgba = [0, 0, 0, 0];
      if (inCard) rgba = [23, 110, 203, 255];
      if (inStem || (inBowl && !inCutout)) rgba = [255, 255, 255, 255];
      if (inSpark) rgba = [255, 221, 95, 255];
      row[index] = rgba[0];
      row[index + 1] = rgba[1];
      row[index + 2] = rgba[2];
      row[index + 3] = rgba[3];
    }
    rows.push(row);
  }

  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(size, 0);
  ihdr.writeUInt32BE(size, 4);
  ihdr[8] = 8;
  ihdr[9] = 6;
  ihdr[10] = 0;
  ihdr[11] = 0;
  ihdr[12] = 0;

  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk("IHDR", ihdr),
    chunk("IDAT", zlib.deflateSync(Buffer.concat(rows))),
    chunk("IEND", Buffer.alloc(0))
  ]);
}

fs.writeFileSync(path.join(outDir, "tray.png"), makePng(32));
