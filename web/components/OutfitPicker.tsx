"use client";

import { useCallback, useMemo, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { SuggestLook } from "@/components/SuggestLook";
import { WardrobeCarousel } from "@/components/WardrobeCarousel";
import { lookHref, lookSummary, type Look, type Suggestion } from "@/lib/look";
import { byCategory } from "@/lib/wardrobe";

type Props = {
  initialLook: Look;
  suggestion: Suggestion;
};

export function OutfitPicker({ initialLook, suggestion }: Props) {
  const router = useRouter();
  const pathname = usePathname();
  const [look, setLook] = useState(initialLook);
  const tops = useMemo(() => byCategory("tops"), []);
  const bottoms = useMemo(() => byCategory("bottoms"), []);
  const shoes = useMemo(() => byCategory("shoes"), []);

  const update = useCallback(
    (next: Look) => {
      setLook(next);
      const href = lookHref(next, suggestion);
      if (`${pathname}${window.location.search}` !== href) {
        router.replace(href, { scroll: false });
      }
    },
    [pathname, router, suggestion],
  );

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      {suggestion.from || suggestion.note ? (
        <div className="mx-5 mb-2 rounded-2xl border border-line px-4 py-3 text-sm">
          <p className="font-medium">
            {suggestion.from ? `${suggestion.from} suggested this look` : "Suggested look"}
          </p>
          {suggestion.note ? <p className="mt-1 text-muted">“{suggestion.note}”</p> : null}
        </div>
      ) : (
        <p className="px-5 pb-2 text-center text-sm text-muted">
          Swipe each row, or tap a neighboring piece.
        </p>
      )}

      <div
        className="mx-auto flex w-full max-w-[430px] flex-col justify-end px-1"
        style={{ height: "min(64dvh, 36rem)" }}
      >
        <div className="h-[34%] min-h-0">
          <WardrobeCarousel
            category="tops"
            items={tops}
            selectedKey={look.top}
            onSelect={(topKey) => update({ ...look, top: topKey })}
          />
        </div>
        <div className="h-[46%] min-h-0 -mt-[6%]">
          <WardrobeCarousel
            category="bottoms"
            items={bottoms}
            selectedKey={look.bottom}
            onSelect={(bottomKey) => update({ ...look, bottom: bottomKey })}
          />
        </div>
        <div className="h-[22%] min-h-0 -mt-[1%]">
          <WardrobeCarousel
            category="shoes"
            items={shoes}
            selectedKey={look.shoes}
            onSelect={(shoesKey) => update({ ...look, shoes: shoesKey })}
          />
        </div>
      </div>

      <div className="mx-auto w-full max-w-[430px] px-6 pb-[max(1.25rem,env(safe-area-inset-bottom))] pt-4">
        <p className="mb-3 text-center text-sm text-muted">{lookSummary(look)}</p>
        <SuggestLook look={look} suggestion={suggestion} />
      </div>
    </div>
  );
}
