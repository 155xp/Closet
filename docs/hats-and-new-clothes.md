# Hats and September garment batch

Version 1.4.0 includes 35 pieces: 24 tops, eight bottoms, two pairs of shoes, and one hat. The ten new pieces import once using the existing import receipts. Existing items, deleted starter pieces, laundry state, and outfit history are preserved.

The lowercase `hat` category appears on the home screen, in the add form, and in its own photo grid. Hats use photo thumbnails without clothing hangers. The outfit carousel has a hat row above the shirt; its first option is "No hat." Saving a hat includes its photo in the calendar and adds it to Laundry. Updating today with "No hat" removes it from today's outfit without marking it clean. Reopening the carousel restores the saved hat selection.

The new assets were edited with the built-in imagegen tool, with parallel calls for separate garments. Original camera photos remain unchanged. Retail tags, tag strings, and size stickers are removed; genuine graphics and embroidery are retained. Cropped sleeve tips and hems are completed conservatively. macOS Vision foreground masking removed baked checkerboard backgrounds from nine imagegen results; all ten final images have genuine alpha transparency, verified on a dark background.

Asset prompts, original filenames, and output paths are recorded in:

- [Cap, sweater, and sweatshirt](imagegen-cap-knit.md)
- [Four tees](imagegen-new-tees.md)
- [Jeans, trousers, and Manhattan tee](imagegen-pants-manhattan.md)

Tests cover the ten-item import into an existing wardrobe, optional hat snapshots and laundry state, lowercase category selection, hat carousel selection/restoration, and adding/removing the hat in today's calendar.

Validation: all 11 unit tests and three focused UI tests passed, covering the new batch, hat add form, optional hat calendar flow, and independent carousel rows.
