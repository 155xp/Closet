import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { defaultLook, lookSummary, parseLook, serializeLook } from "./look";
import { byCategory, garments, getGarment } from "./wardrobe";

describe("wardrobe", () => {
  it("includes the starter 17 tops, 6 bottoms, and 2 shoes", () => {
    assert.equal(byCategory("tops").length, 17);
    assert.equal(byCategory("bottoms").length, 6);
    assert.equal(byCategory("shoes").length, 2);
    assert.equal(garments.length, 25);
  });

  it("looks up garments by the bundled photo key", () => {
    assert.equal(getGarment("stussy-hong-kong-sweatshirt")?.name, "Stüssy Hong Kong sweatshirt");
    assert.equal(getGarment("missing"), undefined);
  });
});

describe("look urls", () => {
  it("restores a look from query params and ignores unknown pieces", () => {
    const look = parseLook({
      top: "codex-cream-tee",
      bottom: "not-a-real-bottom",
      shoes: "black-on-sneakers",
    });
    assert.equal(look.top, "codex-cream-tee");
    assert.equal(look.bottom, defaultLook().bottom);
    assert.equal(look.shoes, "black-on-sneakers");
  });

  it("round-trips a suggested look through the query string", () => {
    const look = {
      top: "bucees-yellow-tee",
      bottom: "washed-black-jeans",
      shoes: "taupe-shearling-clogs",
    };
    const query = serializeLook(look, { from: "Maya", note: "wear this Friday" });
    const params = Object.fromEntries(new URLSearchParams(query));
    assert.deepEqual(parseLook(params), look);
    assert.equal(lookSummary(look), "Buc-ee's tee · Washed black jeans · Taupe shearling clogs");
  });
});
