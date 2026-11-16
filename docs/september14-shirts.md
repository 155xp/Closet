# Stüssy shirt, red tee proportions, and wash indicator

Version 1.4.1 adds the Stüssy cream waffle long sleeve from `IMG_3557.JPG`. The wardrobe now includes 36 pieces. The red Uniqlo U tee previously used a landscape image with a shortened torso. Its replacement matches the white Uniqlo U tee's 1222 × 1287 framing, so both appear at a similar size.

Import receipts now retain an item ID and photo revision. Existing receipts receive default values during SwiftData migration. On the first update, the app recognizes the old red tee by its name, category, and original 1536 × 1024 photo dimensions. It updates that item's photo and its outfit snapshots, keeping its ID, dates, and wash state. Deleted items remain deleted; unrelated user photos with the same name are retained. New imports record their IDs directly.

The rail's wash-status pill is now a small circular `washer` SF Symbol. Detail status also uses an icon, with the status still spoken by VoiceOver. Laundry controls and the basket's count badge keep their existing behavior.

## Images

Both edits used the built-in imagegen tool in parallel. Originals remain unchanged. Camera MPO files were converted to PNG copies under `/tmp/closet-september14-inputs`. macOS Vision foreground masking removed the generated checkerboard backgrounds. Local alpha cleanup removed remaining checkerboard pixels in the two narrow sleeve openings; the new shirt uses photo revision 2 so this correction also reaches the installed copy. Final PNGs have alpha values from 0 to 255 and were inspected together on a dark background.

- New shirt: `Closet/Resources/Garments/stussy-cream-waffle-long-sleeve.png`, 1216 × 1293. Source `IMG_3557.JPG`.
- Corrected tee: `Closet/Resources/Garments/burgundy-u-tee.png`, 1222 × 1287. Source `IMG_3517.JPG`; the existing white tee provided a proportions reference.

### New shirt prompt

Use case: background-extraction. Edit target: supplied cream Stüssy waffle long sleeve shirt photo. Create a faithful photorealistic full garment cutout for a wardrobe app. Preserve the pale cream waffle-knit texture, crewneck, cuffs, long sleeves, relaxed long torso, and exact small black Stüssy script chest embroidery at viewer right. Remove the hanger, background blanket, black inside collar tags and all surrounding objects. Front view upright, straighten into a natural flat lay, sleeves angled gently downward and slightly inward beside torso, complete visible garment with conservative cuffs/hem. Full shirt occupies about 94% of image height and width, portrait or near-square canvas, no excessive whitespace. Genuine transparent PNG alpha outside garment, absolutely no checkerboard pixels, no cast shadow. Do not change logo or add graphics. Only one shirt.

### Red tee prompt

Use case: background-extraction. Image 1 is the actual burgundy Uniqlo U tee to edit; Image 2 is a geometry/framing reference of the SAME style of tee in white, not a color reference. Produce a full upright front cutout of Image 1 matching the realistic long torso and compact downward sleeves and canvas occupancy of Image 2. Crucially don't squash the torso or make an extra-wide short tee: the full silhouette height should be about 1.05 times full sleeve-to-sleeve width, like Image 2. Keep exact muted burgundy color, crewneck, plain cotton texture and genuine neck label of Image 1. Remove the vertical M size sticker, all dangling retail tags/string, bed and background. Natural flat lay, clean full hems and sleeves, small margin about 3%, near-square or portrait canvas, never a landscape canvas. Genuine transparent PNG alpha, no painted checkerboard, no shadow, no hanger. No added artwork. One burgundy shirt only.

## Validation

All 13 unit tests and the focused UI test passed. Screenshots verify the washer indicator, Stüssy shirt, and red tee proportions. The update was installed and launched on the connected iPhone. Its store contains 36 pieces and the same three outfits as before; the red tee has photo revision 2, with its original ID, added date, last-washed date, and laundry state unchanged.
