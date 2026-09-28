# UI review

Judge the location screen whole. The play shell is not the place to try a picture.

## Where

| Role | Path |
|---|---|
| Block. Primitives only. Placement. | `scenes/ui/screen_stage.tscn` — open it and press F6 |
| Sample. The same frame, wearing generated pictures. | `scenes/ui/screen_sample.tscn` — open it and press F6 |
| One picture, alone. | `scenes/ui/component_gallery.tscn` — open it and press F6 |
| Placement, shared by the block and the sample | `scripts/ui/screen_stage.gd` |
| Generated pictures. The shell does not load these. | `Assets/UI/stage/` |
| Mood. Not a slot. | `Samples/` |
| What the shell still loads | `Assets/UI/instrument/` |
| Look | `docs/UI_Visuals.md` |
| Composition | `docs/UI_Layout.md` |

The block never loads `Assets/UI/stage/`. The sample and the gallery do. A missing picture on the sample stays the primitive, with the filename. The gallery shows that file alone, or says it is missing.

## On the block and the sample

Both are the stopped frame, at the play size. Neither is the game. The keys match. The corner names which one you opened.

- `[` and `]` step through the stops. The place name follows. On the sample, the ground loads `grounds/<id>.png` for that stop.
- `R` swaps to the road. The place reads as bound for the current stop. The desk seals go dead. On the sample, the road picture is `ground_road.png`.
- `1` through `5` open a tag. The same key again closes it. Clicking does the same. The well then shows that tag's space. The map tag letterboxes the project's chart. The carry tag shows the two regions, with no frames.
- House is drawn for a city and for Ghorath. Other stops draw the stall and the leaving yard.
- The desk seals select. Arrival is the stall, with no tag open.

Sample figures on the banner are there so the type can be judged. They are not the live wagon.

## Slots

Canvas is the size to draw. The sample shows banners, the book, and grounds at that size on a 1920×1080 frame. Tags, marks, and seals are shown at half the canvas. The gallery shows wide pictures reduced, and tags, marks, and seals at that half size.

| Slot | File | Canvas |
|---|---|---|
| Test ground. Used for every stop that has no picture of its own. | `ground_location.png` | 1920×1080 |
| A stop | `grounds/<id>.png` | 1920×1080 |
| Road | `ground_road.png` | 1920×1080 |
| Top banner | `banner_top.png` | 1876×56 |
| Bottom banner | `banner_bottom.png` | 1876×136 |
| Ledger | `rod.png` | 1920×148 |
| Short tag | `tab_body.png` | 184×236 |
| Open tag | `tab_body_hot.png` | 184×308 |
| Pressed tag | `tab_body_pressed.png` | 184×236 |
| Carry mark | `mark_carry.png` | 128×128 |
| Person mark | `mark_person.png` | 128×128 |
| Posted-eyes mark | `mark_posted.png` | 128×128 |
| Heard mark | `mark_heard.png` | 128×128 |
| Chart mark | `mark_chart.png` | 128×128 |
| Patron mark | `mark_patron.png` | 128×128 |
| Clock, purse, burden, sky | `mark_clock.png`, `mark_purse.png`, `mark_burden.png`, `mark_sky.png` | 128×128 |
| Pause mark | `mark_pause.png` | 128×128 |
| Quiet circle | `seal_round.png` | 192×192 |
| Current circle | `seal_round_hot.png` | 192×192 |
| Pressed circle | `seal_round_pressed.png` | 192×192 |
| Quiet rounded seal | `seal_rect.png` | 336×116 |
| Current rounded seal | `seal_rect_hot.png` | 336×116 |
| Pressed rounded seal | `seal_rect_pressed.png` | 336×116 |

Stop ids, in world order: `kharun`, `zamath`, `thalor`, `veythar`, `ghorath`, `sarns_rest`, `ghul`, `rukh`, `neth`, `kethra`, `sorel`, `draven`, `moraq`, `torven`, `ashar`, `westmark`, `kaleth`, `highmark`, `southmark`, `brineford`, `ridgewatch`.

Tags, marks, and seals are transparent around the object. The book and the grounds are opaque. A banner is faded paper with a deckled edge, held in from the screen.

The stage labels the tags Carry's row as Cargo, Character, Agents, Rumours, and Map, so the row can be seen at full length. Character and Agents are placement labels. They are not in play. The string table can still rename any of them.

## Placement

Heights, the tag size, how far a tag tucks into the book, and the gap between tags are the constants at the top of `screen_stage.gd`. Directing placement means changing those, then looking at the stage again.

## Apply

Accepting the screen is one pass, done when Derek says the stage looks right. That pass copies the stage pictures onto the shell and moves the shell's frame to these anchors. Until then, `field_shell` stays as it is.

## How to ask

Name one filename. Ask for that canvas. Look at it in the gallery, then on the sample screen, before asking for the next. A full painted screen is a mood. The slot is the file.
