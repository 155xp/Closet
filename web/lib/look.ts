import { byCategory, getGarment, type Category, type Garment } from "./wardrobe";

export type Look = {
  top: string;
  bottom: string;
  shoes: string;
};

export type Suggestion = {
  from?: string;
  note?: string;
};

export type SearchValues = Record<string, string | string[] | undefined>;

function firstValue(params: SearchValues, key: string) {
  const value = params[key];
  if (typeof value === "string" && value.length > 0) return value;
  if (Array.isArray(value) && value[0]) return value[0];
  return undefined;
}

export function defaultLook(): Look {
  return {
    top: defaultKey("tops"),
    bottom: defaultKey("bottoms"),
    shoes: defaultKey("shoes"),
  };
}

export function defaultKey(category: Category) {
  const items = byCategory(category);
  return items[Math.min(1, items.length - 1)]?.key ?? items[0]!.key;
}

export function parseLook(params: SearchValues, fallback: Look = defaultLook()): Look {
  return {
    top: validKey(firstValue(params, "top"), "tops") ?? fallback.top,
    bottom: validKey(firstValue(params, "bottom"), "bottoms") ?? fallback.bottom,
    shoes: validKey(firstValue(params, "shoes"), "shoes") ?? fallback.shoes,
  };
}

export function parseSuggestion(params: SearchValues): Suggestion {
  return {
    from: firstValue(params, "from"),
    note: firstValue(params, "note"),
  };
}

export function serializeLook(look: Look, suggestion: Suggestion = {}) {
  const params = new URLSearchParams({
    top: look.top,
    bottom: look.bottom,
    shoes: look.shoes,
  });
  if (suggestion.from?.trim()) params.set("from", suggestion.from.trim());
  if (suggestion.note?.trim()) params.set("note", suggestion.note.trim());
  return params.toString();
}

export function lookPieces(look: Look): Garment[] {
  return [look.top, look.bottom, look.shoes]
    .map((key) => getGarment(key))
    .filter((item): item is Garment => item != null);
}

export function lookSummary(look: Look) {
  return lookPieces(look)
    .map((item) => item.name)
    .join(" · ");
}

export function lookHref(look: Look, suggestion: Suggestion = {}) {
  return `/?${serializeLook(look, suggestion)}`;
}

function validKey(key: string | undefined, category: Category) {
  const item = getGarment(key);
  return item?.category === category ? item.key : undefined;
}
