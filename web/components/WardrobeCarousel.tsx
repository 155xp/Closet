"use client";

import { useCallback, useEffect, useRef } from "react";
import { GarmentPhoto } from "@/components/GarmentPhoto";
import type { Category, Garment } from "@/lib/wardrobe";

type Props = {
  category: Category;
  items: Garment[];
  selectedKey: string;
  onSelect: (key: string) => void;
};

export function WardrobeCarousel({ category, items, selectedKey, onSelect }: Props) {
  const scrollerRef = useRef<HTMLDivElement>(null);
  const itemRefs = useRef(new Map<string, HTMLButtonElement>());
  const programmatic = useRef(false);
  const settleTimer = useRef<number>(0);
  const selectedRef = useRef(selectedKey);

  useEffect(() => {
    selectedRef.current = selectedKey;
  }, [selectedKey]);

  const widthClass = category === "tops" ? "w-[60%]" : "w-[51%]";
  const origin = category === "tops" ? "bottom center" : "top center";
  const align = category === "tops" ? "items-end" : "items-start";
  const selectedIndex = Math.max(0, items.findIndex((item) => item.key === selectedKey));

  const updateScales = useCallback(() => {
    const root = scrollerRef.current;
    if (!root) return;
    const center = root.scrollLeft + root.clientWidth / 2;
    for (const item of items) {
      const el = itemRefs.current.get(item.key);
      if (!el) continue;
      const mid = el.offsetLeft + el.offsetWidth / 2;
      const width = el.offsetWidth;
      const spacing = -width * 0.14;
      const progress = Math.min(Math.abs(mid - center) / Math.max(width + spacing, 1), 1);
      el.style.transform = `scale(${1 - progress * 0.5})`;
    }
  }, [items]);

  const scrollToKey = useCallback(
    (key: string, behavior: ScrollBehavior) => {
      const root = scrollerRef.current;
      const el = itemRefs.current.get(key);
      if (!root || !el) return;
      programmatic.current = true;
      root.scrollTo({
        left: el.offsetLeft + el.offsetWidth / 2 - root.clientWidth / 2,
        behavior,
      });
      window.setTimeout(
        () => {
          programmatic.current = false;
          updateScales();
        },
        behavior === "smooth" ? 320 : 40,
      );
    },
    [updateScales],
  );

  useEffect(() => {
    const root = scrollerRef.current;
    if (!root) return;

    const onScroll = () => {
      updateScales();
      if (programmatic.current) return;
      window.clearTimeout(settleTimer.current);
      settleTimer.current = window.setTimeout(() => {
        const next = nearestKey(root, itemRefs.current, items, selectedRef.current);
        if (next !== selectedRef.current) onSelect(next);
      }, 70);
    };

    const onResize = () => {
      scrollToKey(selectedRef.current, "instant");
      updateScales();
    };

    root.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", onResize);
    onResize();
    return () => {
      root.removeEventListener("scroll", onScroll);
      window.removeEventListener("resize", onResize);
      window.clearTimeout(settleTimer.current);
    };
  }, [items, onSelect, scrollToKey, updateScales]);

  const didMount = useRef(false);
  useEffect(() => {
    scrollToKey(selectedKey, didMount.current ? "smooth" : "instant");
    didMount.current = true;
  }, [scrollToKey, selectedKey]);

  return (
    <div className="relative h-full min-h-0">
      <div
        ref={scrollerRef}
        className="no-scrollbar flex h-full snap-x snap-mandatory overflow-x-auto overflow-y-hidden"
        style={{ paddingLeft: "20%", paddingRight: "20%" }}
        role="listbox"
        aria-label={`${category}, ${selectedIndex + 1} of ${items.length}`}
        aria-activedescendant={`piece-${selectedKey}`}
      >
        {items.map((item, index) => (
          <button
            key={item.key}
            id={`piece-${item.key}`}
            ref={(node) => {
              if (node) itemRefs.current.set(item.key, node);
              else itemRefs.current.delete(item.key);
            }}
            type="button"
            role="option"
            aria-selected={item.key === selectedKey}
            aria-label={item.name}
            onClick={() => onSelect(item.key)}
            className={`relative ${widthClass} ${align} flex h-full shrink-0 snap-center snap-always justify-center`}
            style={{
              marginRight: index === items.length - 1 ? 0 : "-7.14%",
              transformOrigin: origin,
            }}
          >
            <GarmentPhoto
              garment={item}
              priority={index < 3}
              className="max-h-full w-full object-contain drop-shadow-[1px_4px_6px_rgba(0,0,0,0.08)]"
              sizes={category === "tops" ? "(max-width: 540px) 60vw, 280px" : "(max-width: 540px) 51vw, 240px"}
            />
          </button>
        ))}
      </div>
    </div>
  );
}

function nearestKey(
  root: HTMLDivElement,
  refs: Map<string, HTMLButtonElement>,
  items: Garment[],
  fallback: string,
) {
  const center = root.scrollLeft + root.clientWidth / 2;
  let best = fallback;
  let bestDist = Number.POSITIVE_INFINITY;
  for (const item of items) {
    const el = refs.get(item.key);
    if (!el) continue;
    const dist = Math.abs(el.offsetLeft + el.offsetWidth / 2 - center);
    if (dist < bestDist) {
      bestDist = dist;
      best = item.key;
    }
  }
  return best;
}
