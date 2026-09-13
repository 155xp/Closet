"use client";

import { useState } from "react";
import { lookHref, lookSummary, type Look, type Suggestion } from "@/lib/look";

type Props = {
  look: Look;
  suggestion: Suggestion;
};

export function SuggestLook({ look, suggestion }: Props) {
  const [open, setOpen] = useState(false);
  const [from, setFrom] = useState(suggestion.from ?? "");
  const [note, setNote] = useState(suggestion.note ?? "");
  const [copied, setCopied] = useState<"link" | "text" | null>(null);

  const href = lookHref(look, { from, note });
  const absolute = () => new URL(href, window.location.origin).toString();
  const message = [
    from.trim() ? `${from.trim()} picked a look for you` : "A look from your closet",
    "",
    lookSummary(look).replaceAll(" · ", "\n"),
    note.trim() ? `\n“${note.trim()}”` : "",
    "",
    absolute(),
  ]
    .filter((line, index, lines) => line !== "" || lines[index - 1] !== "")
    .join("\n")
    .trim();

  async function copy(kind: "link" | "text") {
    const value = kind === "link" ? absolute() : message;
    await navigator.clipboard.writeText(value);
    if (from.trim()) window.localStorage.setItem("closet-from", from.trim());
    setCopied(kind);
    window.setTimeout(() => setCopied(null), 1600);
  }

  async function share() {
    if (navigator.share) {
      await navigator.share({
        title: "closet look",
        text: message,
        url: absolute(),
      });
      return;
    }
    await copy("text");
  }

  return (
    <>
      <button
        type="button"
        onClick={() => {
          setFrom((current) => current || window.localStorage.getItem("closet-from") || "");
          setOpen(true);
        }}
        className="glass w-full rounded-full px-5 py-3 text-[17px] font-semibold tracking-tight"
      >
        Suggest this look
      </button>
      {open ? (
        <div className="fixed inset-0 z-40 flex items-end justify-center bg-black/30 p-4 sm:items-center">
          <div
            role="dialog"
            aria-labelledby="suggest-title"
            className="glass w-full max-w-md rounded-[28px] p-5"
          >
            <div className="mb-4 flex items-start justify-between gap-3">
              <div>
                <h2 id="suggest-title" className="text-lg font-semibold tracking-tight">
                  Send this look
                </h2>
                <p className="mt-1 text-sm text-muted">{lookSummary(look)}</p>
              </div>
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="rounded-full px-2 py-1 text-sm text-muted"
              >
                Close
              </button>
            </div>
            <label className="mb-3 block text-sm">
              <span className="mb-1 block text-muted">Your name</span>
              <input
                value={from}
                onChange={(event) => setFrom(event.target.value)}
                placeholder="Maya"
                className="w-full rounded-2xl border border-line bg-background px-3 py-2.5 outline-none"
              />
            </label>
            <label className="mb-5 block text-sm">
              <span className="mb-1 block text-muted">Note</span>
              <textarea
                value={note}
                onChange={(event) => setNote(event.target.value)}
                placeholder="This with the clogs Friday"
                rows={3}
                className="w-full resize-none rounded-2xl border border-line bg-background px-3 py-2.5 outline-none"
              />
            </label>
            <div className="grid gap-2">
              <button
                type="button"
                onClick={share}
                className="rounded-full bg-foreground px-5 py-3 text-sm font-semibold text-background"
              >
                Share look
              </button>
              <button
                type="button"
                onClick={() => copy("link")}
                className="rounded-full border border-line px-5 py-3 text-sm font-medium"
              >
                {copied === "link" ? "Link copied" : "Copy link"}
              </button>
              <button
                type="button"
                onClick={() => copy("text")}
                className="rounded-full border border-line px-5 py-3 text-sm font-medium"
              >
                {copied === "text" ? "Message copied" : "Copy text"}
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </>
  );
}
