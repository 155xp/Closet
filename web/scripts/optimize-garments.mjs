import { mkdir, readdir } from "node:fs/promises";
import path from "node:path";
import sharp from "sharp";

const srcDir = path.resolve(import.meta.dirname, "../../Closet/Resources/Garments");
const destDir = path.resolve(import.meta.dirname, "../public/garments");

await mkdir(destDir, { recursive: true });

const files = (await readdir(srcDir)).filter((file) => file.endsWith(".png"));

await Promise.all(
  files.map(async (file) => {
    const dest = path.join(destDir, file.replace(/\.png$/, ".webp"));
    await sharp(path.join(srcDir, file))
      .resize({ width: 900, height: 1100, fit: "inside", withoutEnlargement: true })
      .webp({ quality: 82, alphaQuality: 92 })
      .toFile(dest);
    console.log(file);
  }),
);
