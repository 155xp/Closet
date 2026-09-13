import Link from "next/link";

export function SiteHeader({ current }: { current: "look" | "closet" }) {
  return (
    <header className="sticky top-0 z-20 flex items-center justify-between gap-3 px-5 pb-3 pt-[max(0.85rem,env(safe-area-inset-top))]">
      <div className="min-w-0">
        <p className="text-[11px] font-medium uppercase tracking-[0.18em] text-muted">enci closet</p>
        <h1 className="text-[21px] font-semibold tracking-tight">closet</h1>
      </div>
      <nav className="glass flex rounded-full p-1 text-sm font-medium">
        <Link
          href="/"
          className={`rounded-full px-3.5 py-1.5 transition ${
            current === "look" ? "bg-foreground text-background" : "text-foreground/80"
          }`}
        >
          Look
        </Link>
        <Link
          href="/closet"
          className={`rounded-full px-3.5 py-1.5 transition ${
            current === "closet" ? "bg-foreground text-background" : "text-foreground/80"
          }`}
        >
          Closet
        </Link>
      </nav>
    </header>
  );
}
