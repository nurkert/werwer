# Prompts: scenery pieces (task 012)

Codex CLI 0.164.0 (built-in image generation), 2026-10-27, one cardboard cut-out per call, as `codex exec --skip-git-repo-check -i baeckerin.png -i schmied.png -i village.png < prompt` (two figures for the style, a stage set for the colours). Processed by `tool/assets/scenery.py`.

## Shared text

> Create ONE image with the built-in image generation tool. Do not write any code and do not create any other files.
> Draw ONE single piece of theatre scenery as a flat CARDBOARD CUT-OUT for a paper puppet theatre, in EXACTLY the drawing style of the attached puppet figures: 2000s cartoon look but refined, bold dark-brown outlines, painted textures, warm light from the upper left, and an even PALE CARDBOARD RIM (light beige border, the same thickness as on the figures) running around the whole outer silhouette. The third attached image only shows the colours of the world (moonlit night blues, warm lantern light).
> Format: TALL PORTRAIT image. The piece fills the height of the image from near the top to the bottom edge, centred, with a little empty margin at the top and sides. Fully TRANSPARENT background: nothing behind the piece, no ground, no shadow, no glow, no frame, no text, no characters.
> The piece:

## Pieces

- `sheets/scenery/oak.png`: a gnarled old oak tree with a thick trunk and leafy crown, a wrought-iron lantern glowing warmly on a branch that reaches to the RIGHT; roots and a few stones at its foot.
- `sheets/scenery/house.png`: the corner of a half-timbered village house seen from the side, a lit window, a hanging wooden shop sign on an iron bracket reaching to the LEFT (no lettering), a flower box, a barrel at its foot.
- `sheets/scenery/lamppost.png`: a slim old street lantern post glowing warmly, with a small flowering bush and tall grass at its foot.
- `sheets/scenery/fence.png`: a low piece: a short rustic wooden fence with a bush, wild flowers and two stacked barrels. Much wider than tall is fine, but keep it in a portrait image.
- `sheets/scenery/pines.png`: a group of three tall dark pine trees, one behind the other, ferns and a mossy stone at the foot.
- `sheets/scenery/owl.png`: a tall dark pine tree with a branch reaching to the LEFT and an owl sitting on it, ferns at the foot.
- `sheets/scenery/birch.png`: a slim white birch tree with yellow-green leaves and tall ferns at the foot.
- `sheets/scenery/reeds.png`: a low piece: reeds, cattails and a few stones at a lake shore with a small glowing lantern on a post.
- `sheets/scenery/curtain.png`: a heavy red velvet theatre curtain hanging down from the top, gathered to the RIGHT with a thick golden tassel rope, golden fringe at the bottom, deep folds.
- `sheets/scenery/apple.png`: a small apple tree in blossom with pink and white flowers, a ladder leaning against it, grass at the foot.
- `sheets/scenery/hay.png`: a low piece: two hay bales, a wooden cart wheel and a pitchfork leaning on them.
- `sheets/scenery/stall.png`: the corner of a village market stall with a striped awning reaching to the LEFT, baskets of apples and bread, a wooden crate.
- `sheets/scenery/branch.png`: a piece that HANGS DOWN FROM THE TOP-LEFT CORNER: a leafy oak branch growing in from the upper left edge and reaching to the RIGHT and down, with a small glowing lantern hanging from it on a chain. It touches the top edge and the left edge of the image; everything else is open.
- `sheets/scenery/pinebranch.png`: a piece that HANGS DOWN FROM THE TOP-LEFT CORNER: dark pine branches with cones reaching in from the upper left edge to the RIGHT and down, an owl feather and a few stars of moss. It touches the top and left edges of the image.
- `sheets/scenery/garland.png`: a WIDE LANDSCAPE piece for the TOP EDGE: a string garland sagging between both upper corners, with small glowing paper lanterns and little cloth pennants hanging from it. It touches the left and right edges near the top; the lower part of the image is empty. Use a wide landscape image instead of portrait.
- `sheets/scenery/valance.png`: a WIDE LANDSCAPE piece for the TOP EDGE: a scalloped red velvet theatre valance with golden fringe and golden tassels, hanging along the whole top edge. The lower two thirds of the image are empty. Use a wide landscape image instead of portrait.

## Added 2026-10-28

Same shared text (with "The other attached images only show the colours and materials of the world"), each piece with its own format line. References: two figures and the village (signpost), the curtain and old valance (swag, tassel), the garland (knot).

- `sheets/scenery/signpost.png`: Format: TALL NARROW PORTRAIT image. The piece fills the height of the image from near the top to the bottom edge, centred, with a little empty margin at the top and sides. The piece is SLIM: about a quarter as wide as it is tall. The piece: an old crooked wooden village signpost, slim, with three blank wooden arrow boards all pointing to the LEFT (no lettering), a small iron lantern glowing warmly hanging from a hook on its left side, ivy climbing up the post, a black cat sitting at its foot between tall grass and a few wild flowers.
- `sheets/scenery/swag.png`: Format: WIDE LANDSCAPE image. The piece spans the FULL WIDTH of the image, touching the left and right edges at the top; the lower half of the image is empty and transparent. The piece: ONE single swag of a red velvet theatre valance, painted EXACTLY like the attached scalloped valance (same cartoon painting, same bold dark-brown outlines, same red and gold, same pale cardboard rim along its lower outline), but only ONE scallop: the velvet hangs from both upper corners and sags down in one soft, even curve between them, a few cartoon folds, a golden braid along its lower edge and a short golden fringe below it. The left and right ends are cut straight and vertical at the image edges with the same height at both ends. No glow, no photographic realism: a flat painted cardboard cut-out like the attached figures.
- `sheets/scenery/tassel.png`: Format: TALL PORTRAIT image. The piece hangs from the top edge and is centred, with empty margins at the sides and bottom. The piece: a small gathered knot of red velvet with a golden rosette, from which a long golden tassel on a thick twisted golden cord hangs down. It covers the joint between two swags of a theatre valance. Slim: about a third as wide as it is tall. Fine, detailed painting.
- `sheets/scenery/knot.png`: Format: SQUARE image. The piece is centred with empty margins around it. The piece: a small wooden peg with a knotted cloth bow in faded red and ochre, where two garland strings meet, and one round glowing paper lantern hanging below it on a short string, with two little cloth pennants. It covers the joint between two string garlands of paper lanterns and pennants. Compact, about as wide as tall.
- `sheets/scenery/garland_hook.png` (replaces the knot, references: maid, smith, the seamless garland): Format: portrait canvas. The piece: a small HANGING CONNECTOR for two festival garlands, seen straight from the front, symmetric. From the very top edge a short dark iron chain (4-5 links) hangs straight down to a sturdy round wrought-iron RING. Two short ends of twisted hemp rope (the same rope as in the attached garland) are tied onto the ring with neat small knots, one leading off to the LEFT and one to the RIGHT, each rope end only as long as the ring is wide, sloping gently downwards and cut off cleanly. Below the ring hangs one small warm-glowing brass BELL-LANTERN (a tiny round lantern with a cap, the same brass and warm yellow glass as the lanterns in the attached garland). No ribbons, no bows, no pennants, no red colours. Compact: the whole piece is about twice as tall as wide.
