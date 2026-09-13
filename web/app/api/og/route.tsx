import { readFile } from "node:fs/promises";
import path from "node:path";
import { ImageResponse } from "next/og";
import { defaultLook, parseLook } from "@/lib/look";
import { getGarment } from "@/lib/wardrobe";

export const runtime = "nodejs";

async function garmentData(key: string) {
  const file = path.join(process.cwd(), "public", "garments", `${key}.webp`);
  const buffer = await readFile(file);
  return `data:image/webp;base64,${buffer.toString("base64")}`;
}

export async function GET(request: Request) {
  const look = parseLook(Object.fromEntries(new URL(request.url).searchParams), defaultLook());
  const pieces = [look.top, look.bottom, look.shoes]
    .map((key) => getGarment(key))
    .filter((item) => item != null);

  const images = await Promise.all(
    pieces.map(async (item) => ({
      name: item.name,
      src: await garmentData(item.key),
    })),
  );

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          background: "#fbfbf9",
          color: "#1a1a1c",
        }}
      >
        <div style={{ fontSize: 22, letterSpacing: 4, textTransform: "uppercase", opacity: 0.5 }}>
          closet
        </div>
        <div style={{ display: "flex", alignItems: "flex-end", gap: 28, marginTop: 28 }}>
          {images.map((image) => (
            <img
              key={image.name}
              src={image.src}
              alt={image.name}
              width={220}
              height={280}
              style={{ objectFit: "contain" }}
            />
          ))}
        </div>
      </div>
    ),
    { width: 1200, height: 630 },
  );
}
