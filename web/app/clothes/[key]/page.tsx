import Link from "next/link";
import { notFound } from "next/navigation";
import { ClothesRail } from "@/components/Hanger";
import { HangingPiece } from "@/components/HangingPiece";
import { GarmentPhoto } from "@/components/GarmentPhoto";
import { SiteHeader } from "@/components/SiteHeader";
import { defaultLook, lookHref, parseLook } from "@/lib/look";
import { garments, getGarment } from "@/lib/wardrobe";

export function generateStaticParams() {
  return garments.map((item) => ({ key: item.key }));
}

export async function generateMetadata({ params }: PageProps<"/clothes/[key]">) {
  const garment = getGarment((await params).key);
  if (!garment) return {};
  return {
    title: garment.name,
    description: `${garment.name} · ${garment.category}`,
  };
}

export default async function PiecePage({
  params,
  searchParams,
}: PageProps<"/clothes/[key]">) {
  const garment = getGarment((await params).key);
  if (!garment) notFound();
  const look = parseLook(await searchParams, defaultLook());
  const nextLook = {
    ...look,
    [garment.category === "tops" ? "top" : garment.category === "bottoms" ? "bottom" : "shoes"]:
      garment.key,
  };

  return (
    <div className="mx-auto min-h-dvh w-full max-w-[560px] pb-16">
      <SiteHeader current="closet" />
      <div className="px-5">
        <Link href={`/closet/${garment.category}`} className="text-sm text-muted">
          {garment.category}
        </Link>
      </div>
      <div className="relative mx-auto mt-10 flex w-[280px] justify-center pt-6">
        {garment.category === "shoes" ? (
          <div className="h-[300px] w-[260px]">
            <GarmentPhoto garment={garment} className="h-full w-full object-contain" />
          </div>
        ) : (
          <>
            <div className="absolute inset-x-[-40px] top-0">
              <ClothesRail />
            </div>
            <HangingPiece garment={garment} look={nextLook} width={280} />
          </>
        )}
      </div>
      <div className="mt-8 px-6 text-center">
        <h2 className="text-[22px] font-semibold tracking-tight">{garment.name}</h2>
        <p className="mt-1 text-muted">{garment.category}</p>
        <Link
          href={lookHref(nextLook)}
          className="glass mt-6 inline-block rounded-full px-5 py-3 text-sm font-semibold"
        >
          Use in a look
        </Link>
      </div>
    </div>
  );
}
