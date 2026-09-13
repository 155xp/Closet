import Link from "next/link";
import { SiteHeader } from "@/components/SiteHeader";

export default function NotFound() {
  return (
    <div className="mx-auto flex min-h-dvh w-full max-w-[560px] flex-col">
      <SiteHeader current="closet" />
      <div className="flex flex-1 flex-col items-center justify-center px-6 text-center">
        <h2 className="text-2xl font-semibold tracking-tight">That piece isn’t here</h2>
        <p className="mt-2 text-muted">Head back to the rail or build a look.</p>
        <div className="mt-6 flex gap-3">
          <Link href="/" className="glass rounded-full px-5 py-2.5 text-sm font-semibold">
            Look
          </Link>
          <Link href="/closet" className="rounded-full border border-line px-5 py-2.5 text-sm font-medium">
            Closet
          </Link>
        </div>
      </div>
    </div>
  );
}
