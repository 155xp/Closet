import { ClosetRails } from "@/components/ClosetRails";
import { SiteHeader } from "@/components/SiteHeader";
import { defaultLook, parseLook } from "@/lib/look";

export const metadata = {
  title: "Closet",
  description: "Tops, bottoms, and shoes on the rail.",
};

export default async function ClosetPage({ searchParams }: PageProps<"/closet">) {
  const look = parseLook(await searchParams, defaultLook());

  return (
    <div className="mx-auto min-h-dvh w-full max-w-[720px]">
      <SiteHeader current="closet" />
      <ClosetRails look={look} />
    </div>
  );
}
