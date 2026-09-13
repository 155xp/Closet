import { mkdir, readdir } from "node:fs/promises";
import path from "node:path";
import sharp from "sharp";

const srcDir = path.resolve(import.meta.dirname, "../../Closet/Resources/Garments");
const destDir = path.resolve(import.meta.dirname, "../public/garments");
const ogDir = path.resolve(import.meta.dirname, "../public/og");

await mkdir(destDir, { recursive: true });
await mkdir(ogDir, { recursive: true });

const files = (await readdir(srcDir)).filter((file) => file.endsWith(".png"));

await Promise.all(
  files.map(async (file) => {
    const source = sharp(path.join(srcDir, file));
    await source
      .clone()
      .resize({ width: 900, height: 1100, fit: "inside", withoutEnlargement: true })
      .webp({ quality: 82, alphaQuality: 92 })
      .toFile(path.join(destDir, file.replace(/\.png$/, ".webp")));
    await source
      .clone()
      .resize({ width: 420, height: 520, fit: "inside", withoutEnlargement: true })
      .png({ compressionLevel: 9 })
      .toFile(path.join(ogDir, file));
    console.log(file);
  }),
);
