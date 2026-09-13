import type { ReactNode } from "react";
import Link from "next/link";
import { ClothesRail, Hanger } from "@/components/Hanger";
import { GarmentPhoto } from "@/components/GarmentPhoto";
import { hasHood, type Garment } from "@/lib/wardrobe";
import type { Look } from "@/lib/look";
import { lookHref } from "@/lib/look";

export function HangingPiece({
  garment,
  look,
  width = 168,
}: {
  garment: Garment;
  look: Look;
  width?: number;
}) {
  const hooded = hasHood(garment.name);
  const href = lookHref({
    ...look,
    [garment.category === "tops" ? "top" : garment.category === "bottoms" ? "bottom" : "shoes"]:
      garment.key,
  });
  const photoHeight = width * (garment.category === "tops" ? 1.25 : 1.65);
  const photoTop = garment.category === "tops" ? (hooded ? 8 : 30) : 24;

  return (
    <Link
      href={href}
      aria-label={`${garment.name}, use in a look`}
      className="relative block shrink-0"
      style={{ width, height: photoHeight + 34 }}
    >
      <div className="absolute left-1/2 top-0 w-[60%] -translate-x-1/2">
        <Hanger category={garment.category} />
      </div>
      <div
        className="absolute left-0"
        style={{ top: photoTop, width, height: photoHeight }}
      >
        <GarmentPhoto
          garment={garment}
          className="h-full w-full object-contain object-top drop-shadow-[1px_4px_6px_rgba(0,0,0,0.08)]"
        />
      </div>
    </Link>
  );
}

export function Rack({
  title,
  href,
  children,
  empty,
}: {
  title: string;
  href: string;
  children: ReactNode;
  empty?: boolean;
}) {
  return (
    <section className="pt-10">
      <Link href={href} className="flex items-center gap-2.5 px-5 py-1">
        <h2 className="text-[22px] font-semibold tracking-tight">{title}</h2>
        <span className="text-muted" aria-hidden>
          ›
        </span>
      </Link>
      <div className={`relative ${empty ? "h-[265px]" : "min-h-[245px]"} pt-12`}>
        <div className="absolute inset-x-0 top-[55px]">
          <ClothesRail />
        </div>
        {children}
      </div>
    </section>
  );
}
