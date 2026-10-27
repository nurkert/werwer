# Prompts: stage sets (task 012)

Codex CLI 0.164.0 (built-in image generation), 2026-10-27, run as `codex exec --skip-git-repo-check -i concept.png -i board_a.png -i board_b.png < prompt` with the approved concept and boards as style references.

## Shared text

> Create ONE image with the built-in image generation tool. Do not write any code and do not create any other files.
> The attached images are the approved design direction of the app "Whowolf" (a moonlit puppet theatre). Paint ONE background plate for it in exactly that painted style (2000s cartoon look but refined, bold dark outlines on the near elements, warm lantern light, cool night blues, everything looks like painted cardboard theatre scenery).
> Format: SQUARE image. It is a pure background: NO user interface, NO text, NO characters or puppets, NO moon and NO sun in the sky (they are added separately), NO elements at the far left and right edges that would be cut on narrow screens (keep the left and right 15 percent calm: sky, distant hills, soft foliage). Keep the middle and upper middle open and calm, because titles and buttons will sit on top. The lower 20 percent is the ground the puppets will stand on.
> Original designs only: no resemblance to existing games, apps or characters.
> Scene:

## Scenes

- `source/scenes/village.png`: A medieval half-timbered village at dusk seen across a meadow: rows of houses with warm lit windows, a church tower, a mill, pine trees, a pond reflecting the light; deep blue evening sky with a few stars and soft clouds; a wooden plank stage floor in the foreground.
- `source/scenes/theatre.png`: The inside of a small wooden puppet theatre at night: a round wooden stage platform in the middle foreground, a painted night backdrop behind it with a silhouetted village and pine forest, warm footlights glowing at the stage edge, dark wooden stage frame; the backdrop sky is empty and dark blue.
- `source/scenes/nightlake.png`: A calm lake at night: the dark village and church on the far shore with only a few warm windows, a pine forest, the water mirroring the sky, reeds, a wooden fence and grass in the foreground; the sky very dark blue with many fine stars; mysterious and quiet.
- `source/scenes/morning.png`: The same village in bright early morning: warm golden light, soft mist over the meadow, light blue sky with pink clouds, dew on the grass, a cobblestone path in the foreground.
- `source/scenes/dusk.png`: A village square at dusk: half-timbered houses around a cobbled square with a well and a market stall, garlands of small lanterns, the sky from deep blue at the top to dusty pink at the horizon; cobblestone ground in the foreground.
- `source/scenes/hunt.png`: The edge of a dark forest at twilight: tall pines and an old oak, a misty clearing, the sky grey-blue with heavy clouds; mossy ground with ferns in the foreground.
- `source/scenes/finale.png`: The village square at sunrise after a long night: garlands, lanterns, flower boxes, a festive wooden stage in the foreground; warm sky from blue to golden peach.
- `source/scenes/backstage.png`: Backstage of a puppet theatre: a wooden wall with hanging costumes on a rack, a dressing mirror with warm bulbs, ropes and sandbags, a folded red curtain, wooden floor; cosy warm light, calm surfaces.
- `source/scenes/curtain.png`: A closed heavy red velvet theatre curtain filling the stage, with golden tassels and a golden fringe, a thin vertical gap of warm light in the middle, wooden stage floor in the foreground, two small hanging lanterns at the sides.

The first wings sheet (2026-10-27) was replaced by single scenery pieces, see `scenery.md`.
