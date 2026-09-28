# UI visuals

The look of the location screen. This is the brief for new art. How the frame is divided is `docs/UI_Layout.md`. How a picture is judged, and where the file goes, is `docs/UI_Review.md`.

The screen is accepted whole, on the stage. A single picture can be replaced. It is not locked by itself. The live shell keeps its current plates until that whole screen is accepted.

The words on the controls are a string table. They will change. Banners, the book, tags, and seals are wordless. The engine sets every word. A generated screen that contains a label, a number, or a sentence is a mood sketch.

`Samples/` is mood. It shows leather, deckled paper, and wax. It is not a component, and it is not traced into a slot.

## The stack

On a 1920×1080 frame, from back to front:

1. The stop's picture, edge to edge. On the road, the road's picture.
2. A worn paper banner across the top, half as tall as the first block, and another across the bottom. Each is plain faded paper, held in from the screen so a sliver of the ground shows around it. The center of the paper is clear.
3. A ledger edge under the top banner, the full width of the screen. It is a simplified reading of the sample page block: a solid binding on the left, then a few page layers. The binding is opaque. Scrolls hang under the pages as the tabs. A house seal can sit on the binding later.
4. Scrolls hanging from that rod, one for each category. The roll tucks under the rod. A separate mark sits on the hanging sheet. Opening a scroll fills the well with that panel.
5. The well, which is only the gap. It adds no border, no plate, and no paper.
6. Seals. A line of work is a rounded rectangle. An icon-only control is a circle. The pause control is a circle. The three desks are rounded rectangles on the bottom banner.

## Materials

The ground is a finished plate of a specific place, with real perspective and small objects. The book is a straight page block: a leather spine, then even sheets. The tags are that same leather, and the page block covers their tops so they read as slipped into the book. Ink on the paper is dark. Ink on the leather is bone, so the mark can be seen. The engine sets the type in the face already in the project. The place name is the only large type. Do not generate a font.

The teal thread from the mood sketches is retired. The current tag is the same leather, cut longer. The current seal is red wax.

## Heat

- **Tag.** Quiet and pressed share the short body. The open tag is longer. Pressed is the short body, a step darker.
- **Round seal and rounded seal.** Quiet is pewter. Current is red wax. Pressed is that wax, a step darker. A seal that carries a word leaves the center clear for the engine. A mark, when it has one, sits in that center with the word.

A halo, a glowing edge, a gilt rule, or a different silhouette inside one family is a failed piece.

## What to draw

Draw one file at a time, at the canvas in `docs/UI_Review.md`.

- **Grounds.** One picture per stop, and one for the road. Full bleed, no border, no letters, no interface. The chart is not one of these pictures. The finish is locked to the plates already in `Assets/UI/stage/ground_location.png` and `ground_road.png`: a finished digital matte painting, the backdrop of a shipped PC game. Fine detail, controlled edges, real perspective, late-afternoon light, a specific place with objects you could walk up to. No people, no writing. A photograph is the wrong picture, and so is a loose painted study.
- **Banners.** Plain faded rag paper, a warm yellow, brighter than the dust. No ink border. The worn edge runs around all four sides, and the sheet is held in from the screen so the ground shows around it. The center stays empty so facts and seals can be set on top. The top banner is half the height of the first block.
- **Book.** The page block at the book's screen size. Tags are not drawn into this file.
- **Tag bodies.** The short leather, and the longer leather. Empty center for a mark and a word. On a transparent ground.
- **Marks.** Dark ink, one stroke, readable when small, on a transparent ground. One for each tag: what you carry, the person, the eyes you have posted, what you have heard, the chart. One for the patron. One each for the clock, the purse, the burden, and the sky, if the banner needs them. One for the pause circle.
- **Seals.** A circle and a rounded rectangle, each in pewter, red wax, and a darker red. On a transparent ground. The center stays clear.

## Chart

The chart is not a component. Routes are already drawn on the project's plate. The map tag shows that plate, letterboxed, inside the well. Do not draw a map, a route, a settlement, or a replacement picture of the road to stand in for the chart. The road's own picture is the ground while moving. It is not the chart, and it is not painted over the chart.

## Other screens

Title, house select, and pause use the same seals and the same ink when those screens are staged. The location screen is the one on the stage now.

## How to ask

Name one filename from `docs/UI_Review.md`. Ask for that canvas. The book and the grounds are opaque. Banners, tags, marks, and seals leave the ground showing through their worn or open edges. Leave centers empty, except a ground, which is a picture of a place. Point at `Samples/` for leather, paper, and wax only. The picture is judged alone in the gallery, then in place on the sample screen.
