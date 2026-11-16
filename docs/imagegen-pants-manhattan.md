# Pants and Manhattan tee image generation

Built-in imagegen edit mode was used, with three separate calls running in parallel. Source JPGs were normalized to 2048-pixel PNG copies with `sips` because imagegen rejected the original MPO encoding; originals are unchanged.

## washed-gray-jeans

- Original: `IMG_3519.JPG`
- Edit input: `/tmp/closet-pants-inputs/IMG_3519.png`
- Intended final: `Closet/Resources/Garments/washed-gray-jeans.png`

Prompt:

> Use case: background-extraction. Edit target is the attached garment photo. Create a faithful photorealistic wardrobe app cutout of ONLY the garment, full front view upright, centered with small transparent padding. Background must be genuinely transparent PNG alpha, not a painted checkerboard, not white. Remove bed, surrounding clothes, hands, furniture and ALL removable retail tags, strings and size stickers. Preserve actual garment color, material, stitching, cut and permanent graphics. Correct perspective into a natural flat lay; conservatively complete any cropped sleeve tips or hems. No floor shadow, no hanger, no model, no new design or logos. Subject: washed charcoal gray baggy jeans shown, preserve salt-and-pepper denim wash, five-pocket shape, copper rivets, button, belt loops, straight baggy legs; show both finished hems fully. Portrait composition.

## brown-baggy-trousers

- Original: `IMG_3524.JPG`
- Edit input: `/tmp/closet-pants-inputs/IMG_3524.png`
- Intended final: `Closet/Resources/Garments/brown-baggy-trousers.png`

Prompt:

> Use case: background-extraction. Edit target is the attached garment photo. Create a faithful photorealistic wardrobe app cutout of ONLY the garment, full front view upright, centered with small transparent padding. Background must be genuinely transparent PNG alpha, not a painted checkerboard, not white. Remove bed, surrounding clothes, hands, furniture and ALL removable retail tags, strings and size stickers. Preserve actual garment color, material, stitching, cut and permanent graphics. Correct perspective into a natural flat lay; conservatively complete any cropped sleeve tips or hems. No floor shadow, no hanger, no model, no new design or logos. Subject: muted medium brown baggy trousers shown, preserve twill fabric, wide legs, slanted pockets, waistband belt loops and dark button. Completely remove the cream BAGGY TROUSER paper card and all retail labels/strings; reconstruct brown waistband and pocket naturally underneath. Show full hems. Portrait composition.

## cream-manhattan-tee

- Original: `IMG_3522.JPG`
- Edit input: `/tmp/closet-pants-inputs/IMG_3522.png`
- Intended final: `Closet/Resources/Garments/cream-manhattan-tee.png`

Prompt:

> Use case: background-extraction. Edit target is the attached garment photo. Create a faithful photorealistic wardrobe app cutout of ONLY the garment, full front view upright, centered with small transparent padding. Background must be genuinely transparent PNG alpha, not a painted checkerboard, not white. Remove bed, surrounding clothes, hands, furniture and ALL removable retail tags, strings and size stickers. Preserve actual garment color, material, stitching, cut and permanent graphics. Correct perspective into a natural flat lay; conservatively complete any cropped sleeve tips or hems. No floor shadow, no hanger, no model, no new design or logos. Subject: off-white short sleeve crewneck tee with small permanent chest graphic on the wearer left (viewer right): orange bottle beside dark teal bag with small handwritten "Manhattan Mini Mart" beneath. Preserve this graphic exactly in shape, size, position and colors. Remove loose neck paper tags and tag string; keep the tee otherwise faithful. Whole tee including both sleeves and hem. Square composition.

## Inspection

All three generated photos were visually inspected. Garment colors, silhouettes, stitching, and permanent details are represented; retail tags and strings are absent. Cropped hems and sleeve tips were conservatively reconstructed. Manhattan Mini Mart chest graphic remains present. The jeans and trousers are 1086 × 1448; the tee is 1254 × 1254.

The first generated outputs contained an opaque checkerboard instead of transparency. macOS Vision foreground masking removed that backdrop, preserving garment details. All three final app PNGs have genuine alpha from 0 through 255, verified numerically and on a dark-background composite.
