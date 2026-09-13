import { SiteHeader } from "@/components/SiteHeader";
import { OutfitPicker } from "@/components/OutfitPicker";
import { defaultLook, lookSummary, parseLook, parseSuggestion } from "@/lib/look";

export async function generateMetadata({ searchParams }: PageProps<"/">) {
  const params = await searchParams;
  const look = parseLook(params);
  const suggestion = parseSuggestion(params);
  const title = suggestion.from ? `${suggestion.from} sent a look` : "Look";
  const query = new URLSearchParams({
    top: look.top,
    bottom: look.bottom,
    shoes: look.shoes,
  });
  return {
    title,
    description: lookSummary(look),
    openGraph: {
      title,
      description: lookSummary(look),
      images: [`/api/og?${query.toString()}`],
    },
  };
}

export default async function Home({ searchParams }: PageProps<"/">) {
  const params = await searchParams;
  const look = parseLook(params, defaultLook());
  const suggestion = parseSuggestion(params);

  return (
    <div className="mx-auto flex min-h-dvh w-full max-w-[560px] flex-col">
      <SiteHeader current="look" />
      <OutfitPicker initialLook={look} suggestion={suggestion} />
    </div>
  );
}
