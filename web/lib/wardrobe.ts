export type Category = "tops" | "bottoms" | "shoes";

export type Garment = {
  key: string;
  name: string;
  category: Category;
};

export const garments: Garment[] = [
  { key: "codex-cream-tee", name: "Codex tee", category: "tops" },
  { key: "green-striped-polo", name: "Green striped polo", category: "tops" },
  { key: "formula-one-brown-tee", name: "Formula 1 tee", category: "tops" },
  { key: "levi-wells-olive-tee", name: "Levi Wells Prentice tee", category: "tops" },
  { key: "washed-charcoal-tee", name: "Washed charcoal tee", category: "tops" },
  { key: "red-bull-cream-tee", name: "Red Bull Racing tee", category: "tops" },
  { key: "blue-moon-cream-tee", name: "Blue Moon tee", category: "tops" },
  { key: "vineyard-vines-boat-tee", name: "Vineyard Vines boat tee", category: "tops" },
  { key: "bucees-yellow-tee", name: "Buc-ee's tee", category: "tops" },
  { key: "cream-waffle-long-sleeve", name: "Cream waffle long sleeve", category: "tops" },
  { key: "dark-waffle-long-sleeve", name: "Dark waffle long sleeve", category: "tops" },
  { key: "blue-straight-jeans", name: "Blue jeans", category: "bottoms" },
  { key: "stussy-hong-kong-sweatshirt", name: "Stüssy Hong Kong sweatshirt", category: "tops" },
  { key: "heather-gray-hoodie", name: "Heather gray hoodie", category: "tops" },
  { key: "virginia-tech-gray-sweatshirt", name: "Virginia Tech sweatshirt", category: "tops" },
  { key: "brown-hollister-sweatpants", name: "Brown Hollister sweatpants", category: "bottoms" },
  { key: "slate-blue-sweatshirt", name: "Slate blue sweatshirt", category: "tops" },
  { key: "washed-charcoal-hoodie", name: "Washed charcoal hoodie", category: "tops" },
  { key: "washed-black-jeans", name: "Washed black jeans", category: "bottoms" },
  { key: "charcoal-sweatpants", name: "Charcoal sweatpants", category: "bottoms" },
  { key: "navy-hollister-sweatpants", name: "Navy Hollister sweatpants", category: "bottoms" },
  { key: "deep-navy-sweatshirt", name: "Deep navy sweatshirt", category: "tops" },
  { key: "washed-blue-wide-jeans", name: "Washed blue jeans", category: "bottoms" },
  { key: "taupe-shearling-clogs", name: "Taupe shearling clogs", category: "shoes" },
  { key: "black-on-sneakers", name: "Black On sneakers", category: "shoes" },
];

export const categories: Category[] = ["tops", "bottoms", "shoes"];

export function garmentSrc(key: string) {
  return `/garments/${key}.webp`;
}

export function getGarment(key: string | undefined | null) {
  if (!key) return undefined;
  return garments.find((item) => item.key === key);
}

export function byCategory(category: Category) {
  return garments.filter((item) => item.category === category);
}

export function categoryTitle(category: Category) {
  return category;
}

export function hasHood(name: string) {
  return /hoodie|hooded/i.test(name);
}
