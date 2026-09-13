# Shoe photo preparation

Both supplied photos were edited in parallel using the built-in imagegen tool. Original photos were unchanged. The generated checkerboard backgrounds were replaced with flat magenta and removed locally to produce genuine alpha transparency. Edges were inspected on light and dark backgrounds.

Final app assets:

- [Taupe shearling clogs](../Closet/Resources/Garments/taupe-shearling-clogs.png)
- [Black On sneakers](../Closet/Resources/Garments/black-on-sneakers.png)

## Clog prompts

Use case: background-extraction.
Asset type: transparent shoe pair cutout for a wardrobe outfit preview app.
Input image: IMG_3490.JPG is the edit target.
Primary request: Extract the exact taupe suede shearling-lined clogs in the supplied photograph, removing the rug, wood furniture, floor and every other background object. Keep the shoes faithful to their photographed real materials, color, shape, buckles and visible branding. Lightly tidy dust and uneven lighting while preserving natural texture and wear.
Composition: clean top-down photograph of the complete left and right clog together, centered, vertically aligned parallel with heels at the top and toes pointing down. Preserve a small natural gap between shoes. Both shoes the same scale. Entire pair visible with about 3 percent padding.
Scene/backdrop: genuinely transparent RGBA background, no checkerboard painted into image, no ground plane, no backdrop, no cast shadow outside the shoes.
Constraints: preserve shoe identity and all construction details; do not stylize; no extra objects, text or watermark.

Second pass:
Use case: precise-object-edit. Change ONLY the gray-white checkerboard surrounding the pair of clogs into a completely uniform solid bright pink chroma-key background #FF00FF. Same exact pair of taupe shearling clogs, same size, same positions, same materials, buckles, labels, lighting, contours and details. No shadow or pink reflection on the shoes. All checkerboard everywhere outside shoes including gap between them must become solid bright magenta pink. Background absolutely flat with no pattern, gradient, texture or shadows. Preserve the entire shoes and do not redesign them.

Built-in imagegen. Input normalized from iPhone MPO JPEG to PNG. First output baked checkerboard; second generated flat magenta; local Python chroma-key derived alpha using nearest solid foreground colors and removed detached residual islands. Final PNG alpha verified (0,255), inspected on cream and charcoal backgrounds. Original photo unchanged.


## Sneaker prompts

Asset: Closet/Resources/Garments/black-on-sneakers.png
Original: /Users/eric/Downloads/IMG_3491.JPG (unchanged)
Mode: built-in image_gen editing, two passes. Source was MPO inside JPG filename, normalized to PNG for tool input.
Prompt 1: Use case: background-extraction. Asset type: transparent photo cutout for a wardrobe outfit preview app. Edit target: supplied photograph of a pair of black On sneakers. Remove carpet, furniture, socks, room and background, retaining exact pair. Request genuine alpha. Center top-down pair, toes down, heels up, parallel and evenly aligned with narrow gap. Preserve black colors, fabric texture, lace pattern, soles, proportions and existing branding. Lightly tidy dust and improve even natural lighting. Complete shoes with 3 percent padding. No floor, shadow, hanger, labels, added text, border or props. If alpha impossible use flat magenta #FF00FF, never checkerboard.
Prompt 2: Use case: background-extraction. Edit ONLY background. Preserve both black On sneakers exactly: shape, alignment, texture, laces, logos, soles, toe direction down, proportions and lighting. Replace gray/white checkerboard around and between shoes with uniform solid vivid MAGENTA #FF00FF. No checkerboard, pink lighting, shadows, floor, texture or gradient. Literal chroma key backdrop for programmatic removal; full pair uncropped.
Generated source: /Users/eric/.codex/generated_images/01a097b7-6147-7d21-a7d9-ad8dbbb2cc46/exec-6420e2ad-d427-48f0-8084-1fb723861ebe.png
Postprocessing: removed magenta with alpha chroma key and color decontamination, tight crop plus 3 percent transparent padding, 1600px maximum edge. Genuine RGBA confirmed, visually inspected on neutral background.
