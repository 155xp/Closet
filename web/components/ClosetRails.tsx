"use client";

import { useRef, useState } from "react";
import { HangingPiece, Rack } from "@/components/HangingPiece";
import { GarmentPhoto } from "@/components/GarmentPhoto";
import type { Look } from "@/lib/look";
import { lookHref } from "@/lib/look";
import { byCategory, type Garment } from "@/lib/wardrobe";
import Link from "next/link";

export function ClosetRails({ look }: { look: Look }) {
  const tops = byCategory("tops");
  const bottoms = byCategory("bottoms");
  const shoes = byCategory("shoes");

  return (
    <div className="pb-16">
      <p className="px-5 text-sm text-muted">
        Tap a piece to drop it into the outfit picker.
      </p>
      <Rack title="tops" href="/closet/tops">
        <SwayRail items={tops} look={look} />
      </Rack>
      <Rack title="bottoms" href="/closet/bottoms">
        <SwayRail items={bottoms} look={look} />
      </Rack>
      <section className="pt-8 pb-4">
        <Link href="/closet/shoes" className="flex items-center gap-2.5 px-5 py-1">
          <h2 className="text-[22px] font-semibold tracking-tight">shoes</h2>
          <span className="text-muted" aria-hidden>
            ›
          </span>
        </Link>
        <div className="no-scrollbar mt-5 flex gap-3 overflow-x-auto px-5">
          {shoes.map((item) => (
            <Link
              key={item.key}
              href={lookHref({ ...look, shoes: item.key })}
              aria-label={`${item.name}, use in a look`}
              className="w-[160px] shrink-0"
            >
              <div className="h-[190px]">
                <GarmentPhoto garment={item} className="h-full w-full object-contain" />
              </div>
            </Link>
          ))}
        </div>
      </section>
    </div>
  );
}

function SwayRail({ items, look }: { items: Garment[]; look: Look }) {
  const [angle, setAngle] = useState(0);
  const last = useRef({ x: 0, t: 0 });
  const idle = useRef<number>(0);

  return (
    <div
      className="no-scrollbar flex overflow-x-auto overflow-y-visible px-3"
      onScroll={(event) => {
        const now = performance.now();
        const x = event.currentTarget.scrollLeft;
        const dt = Math.max(8, Math.min(now - last.current.t, 66));
        const velocity = (x - last.current.x) / dt;
        last.current = { x, t: now };
        setAngle(Math.max(-8, Math.min(8, -velocity * 80)));
        window.clearTimeout(idle.current);
        idle.current = window.setTimeout(() => setAngle(0), 180);
      }}
    >
      {items.map((item, index) => (
        <div
          key={item.key}
          className="origin-[50%_2.5%] transition-transform duration-500 ease-out"
          style={{
            transform: `rotate(${angle * (0.9 + (index % 3) * 0.05)}deg)`,
            marginRight: -8,
          }}
        >
          <HangingPiece garment={item} look={look} />
        </div>
      ))}
    </div>
  );
}
