# UI visuals

The look of the game for this development cycle. How the frame is divided is `docs/UI_Layout.md`.

Pictures of the places, the banners, the book, the tags, and the seals are drawn outside this checkout. This document is the brief for those pictures, and the rule for controls drawn here until the pictures are applied.

The words on the controls are a string table. They will change. Banners, the book, tags, and seals are wordless. The engine sets every word.

`Samples/` is mood. It shows leather, deckled paper, and wax. It is not a component.

## Finished pictures

On a 1920×1080 frame, from back to front:

1. The stop's picture, edge to edge. On the road, the road's picture.
2. A worn paper banner across the top, short, and a taller one across the bottom. Each is plain faded paper, held in from the screen so a sliver of the ground shows around it. The center of the paper is clear.
3. A ledger under the top banner, the full width of the screen. A solid binding is on the left, then a few page layers. Tags hang under the pages. The page block covers the top of each tag.
4. The well, which is only the gap. It adds no border, no plate, and no paper.
5. Seals. A line of work is a rounded rectangle. An icon-only control is a circle. The pause control is a circle. The three desks are rounded rectangles on the bottom banner.

### Materials

The ground is a finished plate of a specific place, with real perspective and small objects a person could walk up to. Late-afternoon light. The book is a straight page block: a leather spine, then even sheets. The tags are that same leather. Ink on the paper is dark. Ink on the leather is bone, so the mark can be seen. The engine sets the type in Bona Nova, the face already in the project. The place name is the only large type.

The current tag is the same leather, cut longer. The current seal is red wax. A quiet seal is pewter.

Palette: bone paper, umber leather, dull oxblood wax, pewter, warm dust.

A ground has no people, no writing, and no interface. A banner, a tag, a mark, and a seal leave the center clear, or leave the ground showing through. The book and the grounds are opaque.

### Heat

- **Tag.** Quiet and pressed share the short body. The open tag is longer. Pressed is the short body, a step darker.
- **Round seal and rounded seal.** Quiet is pewter. Current is red wax. Pressed is that wax, a step darker. A seal that carries a word leaves the center clear for the engine. A mark, when it has one, sits in that center with the word.

Quiet, current, and pressed share one silhouette. A halo, a glowing edge, or a gilt rule fails the piece.

### What the pictures are

- **Grounds.** One picture per stop, and one for the road. Full bleed. The chart is the project's map plate, letterboxed inside the well. Routes on that plate stay as drawn. The road's picture is the ground while moving.
- **Banners.** Plain faded rag paper, a warm yellow, brighter than the dust. The worn edge runs around all four sides. The center stays empty so facts and seals can be set on top. The top banner is the short one.
- **Book.** The page block at the book's screen size. Tags are separate files.
- **Tag bodies.** The short leather, and the longer leather. Empty center for a mark and a word. On a transparent ground.
- **Marks.** Dark ink, one stroke, readable when small, on a transparent ground. One for each tag: what you carry, the person, the eyes you have posted, what you have heard, the chart. One for the patron. One each for the clock, the purse, the burden, and the sky. One for the pause circle.
- **Seals.** A circle and a rounded rectangle, each in pewter, red wax, and a darker red. On a transparent ground. The center stays clear.

### Other screens

Title, house select, and pause use the same seals and the same ink when those screens receive pictures. The location frame is the one this brief describes.

## Prototype stand-in

Until those pictures are applied, controls in this checkout use `InstrumentStyle` (`scripts/ui/instrument_style.gd`) and the plates in `Assets/UI/instrument/`.

- Type is Bona Nova. A title is amber. Body type is bone. The place name stays the largest type.
- Colors stay the ones named on `InstrumentStyle`: bone, amber, muted, the dark ground, brass.
- A button takes `action`, `toggle`, or `place`. A list row takes `row`. A cargo cell takes `cell`. A panel takes `frame`. The top and bottom bars take `bar`.
- A missing picture is the dark ground color.
- A new control is a plate, a row, or a cell from that style.

Generate no stand-in images. Add no second plate set. Open no side scene to try a look. Play is the shell. `field_shell` keeps these plates until the outside pictures are applied.
