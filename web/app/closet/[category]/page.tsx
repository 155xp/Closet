import Link from "next/link";
import { notFound } from "next/navigation";
import { GarmentPhoto } from "@/components/GarmentPhoto";
import { SiteHeader } from "@/components/SiteHeader";
import { defaultLook, lookHref, parseLook } from "@/lib/look";
import { byCategory, categories, categoryTitle, type Category } from "@/lib/wardrobe";

function isCategory(value: string): value is Category {
  return categories.includes(value as Category);
}

export function generateStaticParams() {
  return categories.map((category) => ({ category }));
}

export async function generateMetadata({ params }: PageProps<"/closet/[category]">) {
  const { category } = await params;
  if (!isCategory(category)) return {};
  return {
    title: categoryTitle(category),
    description: `Every ${category} in the closet.`,
  };
}

export default async function CategoryPage({
  params,
  searchParams,
}: PageProps<"/closet/[category]">) {
  const { category } = await params;
  if (!isCategory(category)) notFound();
  const look = parseLook(await searchParams, defaultLook());
  const items = byCategory(category);

  return (
    <div className="mx-auto min-h-dvh w-full max-w-[720px] pb-16">
      <SiteHeader current="closet" />
      <div className="flex items-end justify-between px-5 pb-4">
        <div>
          <Link href="/closet" className="text-sm text-muted">
            Closet
          </Link>
          <h2 className="text-[28px] font-semibold tracking-tight">{categoryTitle(category)}</h2>
        </div>
        <p className="text-sm text-muted">{items.length}</p>
      </div>
      <div className="grid grid-cols-2 gap-x-4 gap-y-8 px-5">
        {items.map((item) => (
          <div key={item.key} className="min-w-0">
            <Link
              href={lookHref({
                ...look,
                [category === "tops" ? "top" : category === "bottoms" ? "bottom" : "shoes"]: item.key,
              })}
              className={`relative block ${category === "bottoms" ? "aspect-[0.7]" : "aspect-square"}`}
              aria-label={`${item.name}, use in a look`}
            >
              <GarmentPhoto garment={item} className="h-full w-full object-contain" />
            </Link>
            <Link
              href={`/clothes/${item.key}`}
              className="mt-2 block text-center text-sm text-muted"
            >
              {item.name}
            </Link>
          </div>
        ))}
      </div>
    </div>
  );
}
