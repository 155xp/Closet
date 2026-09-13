import type { Category } from "@/lib/wardrobe";

export function ClothesRail() {
  return <div className="rail w-full" aria-hidden />;
}

export function Hanger({ category }: { category: Category }) {
  if (category === "tops") {
    return (
      <svg viewBox="0 0 160 90" className="h-[56px] w-full" aria-hidden>
        <defs>
          <linearGradient id="hook" x1="73" y1="0" x2="88" y2="27" gradientUnits="userSpaceOnUse">
            <stop stopColor="#7a7a7a" />
            <stop offset="0.5" stopColor="#c2c2c2" />
            <stop offset="1" stopColor="#707070" />
          </linearGradient>
          <linearGradient id="wood" x1="0" y1="32" x2="0" y2="80" gradientUnits="userSpaceOnUse">
            <stop stopColor="#ebc48f" />
            <stop offset="0.5" stopColor="#c9965c" />
            <stop offset="1" stopColor="#dbab6e" />
          </linearGradient>
        </defs>
        <path
          d="M73 8 C75 -1 85 -2 85 3 C92 10 83 14 82 16 Q80 18 80 21 L80 31"
          fill="none"
          stroke="url(#hook)"
          strokeWidth="1.25"
          strokeLinecap="round"
        />
        <path
          fillRule="evenodd"
          d="M14 68 Q48 52 71 34 Q80 26 89 34 Q111 52 146 68 Q151 75 143 77 L17 77 Q9 76 14 68 Z M29 70 L131 70 Q105 58 85 45 Q80 43 75 45 Q55 58 29 70 Z"
          fill="url(#wood)"
        />
      </svg>
    );
  }

  return (
    <svg viewBox="0 0 160 60" className="h-[40px] w-full" aria-hidden>
      <defs>
        <linearGradient id="hook-b" x1="73" y1="0" x2="88" y2="27" gradientUnits="userSpaceOnUse">
          <stop stopColor="#7a7a7a" />
          <stop offset="0.5" stopColor="#c2c2c2" />
          <stop offset="1" stopColor="#707070" />
        </linearGradient>
        <linearGradient id="bar" x1="0" y1="30" x2="0" y2="41" gradientUnits="userSpaceOnUse">
          <stop stopColor="#ebc48f" />
          <stop offset="1" stopColor="#c9965c" />
        </linearGradient>
      </defs>
      <path
        d="M73 8 C75 -1 85 -2 85 3 C92 10 83 14 82 16 Q80 18 80 21 L80 31"
        fill="none"
        stroke="url(#hook-b)"
        strokeWidth="1.25"
        strokeLinecap="round"
      />
      <rect x="17" y="31" width="126" height="8" rx="2" fill="url(#bar)" />
      <rect x="22" y="30" width="8" height="18" rx="1.5" fill="#c8c8c8" />
      <rect x="130" y="30" width="8" height="18" rx="1.5" fill="#c8c8c8" />
    </svg>
  );
}
