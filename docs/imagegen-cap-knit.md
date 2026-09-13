# Hat and knitwear image cleanup

Built-in `image_gen` edit mode was used for three separate images in parallel on 2026-09-13. Originals were not changed. The `.JPG` inputs were MPO files, rejected by imagegen; `sips` converted copies to PNG and resized their longest edge to 2048 pixels under `/tmp/closet-cap-knit/`.

## brown-hammer-cap

- Original: `/Users/eric/Downloads/IMG_3520.JPG`
- Imagegen input: `/tmp/closet-cap-knit/IMG_3520.png`
- Selected imagegen result: `/Users/eric/.codex/generated_images/01a09c64-ff56-7cf3-974b-9e9238f4a8b0/exec-cbab51fb-312a-4329-b9a2-7bb67f8ab0ca.png`
- Intended app asset: `Closet/Resources/Garments/brown-hammer-cap.png`

Prompt:

> Use case: background-extraction. Edit the supplied photo into a photorealistic wardrobe catalog cutout, upright and centered with the ENTIRE garment visible and a small clear margin. Output PNG with a genuinely transparent alpha-channel background, no opaque backdrop, no checkerboard painted into pixels, no floor or cast shadow. Preserve the photographed garment's true color, weave, seams, proportions, and genuine design. Remove the bedroom, bed, people, other objects, removable retail tags, strings, stickers and price/size labels. Keep genuine embroidery and printed graphics. Do not add hangers or new decorations. Subject: brown baseball cap. Preserve exact cream front embroidery HAMMER on first line, the in cursive on second, OVER on third, all matching photo. Preserve bill shape and panel stitches. Remove hand/arm entirely; hat floats alone. Same front/slightly elevated viewpoint. No retail labels.

## cream-knit-sweater

- Original: `/Users/eric/Downloads/IMG_3523.JPG`
- Imagegen input: `/tmp/closet-cap-knit/IMG_3523.png`
- Selected imagegen result: `/Users/eric/.codex/generated_images/01a09c64-ff56-7cf3-974b-9e9238f4a8b0/exec-4ea7003e-df07-4a4b-93e7-fc2366ad52eb.png`
- Intended app asset: `Closet/Resources/Garments/cream-knit-sweater.png`

Prompt:

> Use case: background-extraction. Edit the supplied photo into a photorealistic wardrobe catalog cutout, upright and centered with the ENTIRE garment visible and a small clear margin. Output PNG with a genuinely transparent alpha-channel background, no opaque backdrop, no checkerboard painted into pixels, no floor or cast shadow. Preserve the photographed garment's true color, weave, seams, proportions, and genuine design. Remove the bedroom, bed, people, other objects, removable retail tags, strings, stickers and price/size labels. Keep genuine embroidery and printed graphics. Do not add hangers or new decorations. Subject: cream loose-knit long-sleeve sweater. Preserve honeycomb/rib knit texture, rolled neck, rolled hem, loose fit and cream shade. Remove barcode paper tag at neck and black inside collar label. Front flat-lay, sleeves extend diagonally downward, complete only the clipped cuffs conservatively so both sleeves are visible. No logos or text.

## cream-guinness-sweatshirt

- Original: `/Users/eric/Downloads/IMG_3525.JPG`
- Imagegen input: `/tmp/closet-cap-knit/IMG_3525.png`
- Selected imagegen result: `/Users/eric/.codex/generated_images/01a09c64-ff56-7cf3-974b-9e9238f4a8b0/exec-7c5d87f9-a77e-4891-91b4-d0a0c7ff2ac7.png`
- Intended app asset: `Closet/Resources/Garments/cream-guinness-sweatshirt.png`

Prompt:

> Use case: background-extraction. Edit the supplied photo into a photorealistic wardrobe catalog cutout, upright and centered with the ENTIRE garment visible and a small clear margin. Output PNG with a genuinely transparent alpha-channel background, no opaque backdrop, no checkerboard painted into pixels, no floor or cast shadow. Preserve the photographed garment's true color, weave, seams, proportions, and genuine design. Remove the bedroom, bed, people, other objects, removable retail tags, strings, stickers and price/size labels. Keep genuine embroidery and printed graphics. Do not add hangers or new decorations. Subject: cream/beige crewneck long-sleeve sweatshirt, genuine small gold harp and red GUINNESS embroidery on wearer's left chest (viewer right). Preserve exact GUINNESS text, placement, color and size. Remove paper hangtag above neck and inner label. Front flat-lay, complete cropped sleeves with matching simple rib cuffs. Preserve roomy fit, ribbed hem and collar.

## Inspection and transparency limitation

The generated images preserve the cap's HAMMER / the / OVER embroidery, cream knit texture and rolled edges, and the Guinness harp and red chest text. The bed, hand, surrounding objects, retail tags, strings and inside collar labels are absent. Cropped sleeve ends were completed by imagegen with matching cuffs; these missing areas are inferred rather than directly photographed.

The first results have opaque RGB checkerboard pixels despite the transparency request. Dimensions: cap 1205 × 1306, sweater 1224 × 1285, sweatshirt 1318 × 1193. A targeted imagegen correction also returned opaque checkerboard backgrounds and was rejected. No opaque checkerboard result should be shipped as a transparent asset.

Correction prompt:

> Precisely edit this existing garment cutout image: remove ONLY the fake gray/white checkerboard background, replacing it with actual PNG transparency (alpha 0 outside the garment). Preserve every garment pixel, embroidered text, color, seams, lighting, size, placement and silhouette. The input incorrectly baked a checkerboard into an RGB image. Output must be RGBA PNG with a real alpha channel and no painted checkerboard, no backdrop color, no shadows. Do not redraw or change the garment.

Final packaging: macOS Vision foreground masking removed the baked checkerboard from the selected imagegen results. The three app PNGs now contain genuine alpha from 0 through 255, verified numerically and composited on a dark background. Original dimensions and garment graphics are preserved.
