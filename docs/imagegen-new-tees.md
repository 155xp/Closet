# September 2026 tee cutouts

Mode: built-in imagegen, four independent parallel edit calls. Original JPGs were rejected as MPO, so unchanged originals were normalized to PNG with sips and reduced to a 2000 px maximum dimension for input. Originals remain in /Users/eric/Downloads.

Status: all four final app PNGs have genuine alpha. Snoopy retains the generated alpha; macOS Vision foreground masking removed the baked checkerboards from the other three. Alpha range and dark-background composites were checked.

| Source | Workspace asset | Dimensions | Alpha |
| --- | --- | --- | --- |
| IMG_3516.JPG | Closet/Resources/Garments/white-snoopy-tee.png | 1230 × 1278 | RGBA, range 0–255 |
| IMG_3517.JPG | Closet/Resources/Garments/burgundy-u-tee.png | 1536 × 1024 | RGBA, range 0–255 |
| IMG_3518.JPG | Closet/Resources/Garments/charcoal-u-tee.png | 1230 × 1278 | RGBA, range 0–255 |
| IMG_3521.JPG | Closet/Resources/Garments/white-u-tee.png | 1222 × 1287 | RGBA, range 0–255 |

All final workspace paths are relative to /Users/eric/Code/Closet. The source JPG paths are relative to /Users/eric/Downloads. Visually checked the four outputs: retail size stickers, hangtags, and plastic loops removed; Snoopy print and real neck branding retained. The dark tee is now upright. Cropped sleeve ends are conservatively reconstructed.

## Shared prompt

Use case: background-extraction. Asset type: transparent product cutout for a personal wardrobe iPhone app. Edit target: the supplied photograph. Extract ONLY the main garment described below, faithfully preserving its identity, color, proportions, materials, seams and genuine graphics. Remove the bed, blankets, other clothing, person, tags, stickers and all unrelated objects. Garment fully visible and centered upright front view on a genuinely transparent PNG background with alpha=0 outside garment; no checkerboard pixels, no white/gray backdrop, no floor, no drop shadow, no hanger or mannequin. Complete any cropped sleeve ends conservatively. Keep natural fabric folds; subtly straighten into an attractive flat-lay without changing design. Small even transparent margin. Subject:

## Subject additions

### white-snoopy-tee

Edit target: /tmp/closet-tees-refs/IMG_3516-preview.png

white Snoopy short-sleeve cotton T-shirt. Preserve the entire original black Snoopy graphic, the exact printed wording MY SUPPER DISH! above Snoopy, SNOOPY underneath, and genuine small signature/print marks. The vertical repeated M marks are a removable size sticker, NOT artwork: remove that sticker completely while reconstructing the shirt and actual graphic underneath.

### burgundy-u-tee

Edit target: /tmp/closet-tees-refs/IMG_3517-preview.png

plain muted burgundy Uniqlo U short-sleeve T-shirt. Preserve the color, cotton texture, crewneck ribbing and loose fit. Remove the vertical transparent repeated M size sticker, white paper hangtag, and hanging plastic loop from the neck. Keep the chest plain.

### charcoal-u-tee

Edit target: /tmp/closet-tees-refs/IMG_3518-preview.png

plain dark charcoal-navy Uniqlo U short-sleeve T-shirt. The source garment is photographed upside down: turn it upright with neck at the top and hem at the bottom. Preserve its dark charcoal-navy color, cotton texture, crewneck ribbing, loose fit. Remove vertical M size sticker and all dangling paper hangtags and strings. Keep the chest plain.

### white-u-tee

Edit target: /tmp/closet-tees-refs/IMG_3521-preview.png

plain white Uniqlo U short-sleeve T-shirt. Preserve white cotton texture, crewneck ribbing, loose fit. Remove vertical M size sticker and all dangling paper hangtags and strings. Keep chest plain.

## Generated originals

- white-snoopy-tee: /Users/eric/.codex/generated_images/01a09c65-49cf-7403-82e2-b988fedc7318/exec-111cfe1c-c20a-4930-af05-f213a1de9b02.png
- burgundy-u-tee: /Users/eric/.codex/generated_images/01a09c65-49cf-7403-82e2-b988fedc7318/exec-db1e5c1b-fdbe-43f6-903b-73d826de802c.png
- charcoal-u-tee: /Users/eric/.codex/generated_images/01a09c65-49cf-7403-82e2-b988fedc7318/exec-8445fabd-15e0-456d-a913-03ef4ec4b8d8.png
- white-u-tee: /Users/eric/.codex/generated_images/01a09c65-49cf-7403-82e2-b988fedc7318/exec-ff05b19e-07ef-4388-a7fa-23b5fb81a75e.png
