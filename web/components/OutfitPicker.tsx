"use client";

import { useCallback, useMemo, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { SuggestLook } from "@/components/SuggestLook";
import { WardrobeCarousel } from "@/components/WardrobeCarousel";
import { lookHref, type Look, type Suggestion } from "@/lib/look";
import { byCategory, getGarment } from "@/lib/wardrobe";

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

  const top = getGarment(look.top);
  const bottom = getGarment(look.bottom);

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

      <div className="mx-auto flex w-full max-w-[430px] min-h-0 flex-1 flex-col justify-center px-1">
        <p className="pb-1 text-center text-sm text-muted">{top?.name ?? ""}</p>
        <div className="h-[34%] min-h-[132px]">
          <WardrobeCarousel
            category="tops"
            items={tops}
            selectedKey={look.top}
            onSelect={(topKey) => update({ ...look, top: topKey })}
          />
        </div>
        <div className="h-[46%] min-h-[176px]">
          <WardrobeCarousel
            category="bottoms"
            items={bottoms}
            selectedKey={look.bottom}
            onSelect={(bottomKey) => update({ ...look, bottom: bottomKey })}
          />
        </div>
        <p className="pt-1 text-center text-sm text-muted">{bottom?.name ?? ""}</p>
        <div className="h-[20%] min-h-[88px]">
          <WardrobeCarousel
            category="shoes"
            items={shoes}
            selectedKey={look.shoes}
            onSelect={(shoesKey) => update({ ...look, shoes: shoesKey })}
          />
        </div>
      </div>

      <div className="mx-auto w-full max-w-[430px] px-6 pb-[max(1.25rem,env(safe-area-inset-bottom))] pt-3">
        <SuggestLook look={look} suggestion={suggestion} />
      </div>
    </div>
  );
}
