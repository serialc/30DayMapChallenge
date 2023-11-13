# A bit more work
So this map requires a bit more documentation to replicate.

Working in QGIS for developing QGIS python is easier for development.

## QGIS python console (open with Ctrl+Alt+P)
You want the file editor, not just the interactive console, open the file editor with the [page and pencil] icon.

## Tiling hexagonal SVG
Everything here is an attempt to replicate and adapt what [xcaeag](https://github.com/xcaeag/30DayMapChallenge-2023/blob/main/day9.md) did for his great day9 map with forests.

Basically, in QGIS, you take a polygon and calculate the centroids of overlayed hexagons, as well as determine what neighbour configurations each cell has. This is done with the script.

Then, still in QGIS, you will symbolize each point using an SVG tile. 

Open the Symbology tab for the hexpoints layer's attributes.

The menu for this is a bit finicky.
- Change marker type to `SVG Marker`.
- Scroll down to the input below `> Dynamic SVG parameters` and select on the far right drop-down the 'edit' option'
- Note, the '\|\|' operator concatenates.
- Enter something like `'/home/cyrille/public_html/30DayMapChallenge/2023/day10/svg/forest-' || "neighbourhood" || '.svg'`
- Where the first part is the path to the SVG, the "attribute" and then the SVG ending.
- You will need to select one of the provided SVG by default to unlock setting the line thickness. This will only be effective on the expression linked files if the SVG contain values defined using `param()`, such as `param(fill)`, `param(outline)`, and `param(outline-width)`. See [reference](https://docs.qgis.org/3.10/en/docs/user_manual/style_library/symbol_selector.html#marker-symbols).

It's possible to take this a bit further, having multiple tile pictures per attribute.

So, for example, the tiles that are completely surrounded could be randomized to use a variety, using something like this:
```
CASE
WHEN "neighbourhood" == 0 THEN '/home/cyrille/public_html/30DayMapChallenge/2023/day10/svg/forest-0-' || rand(0,5) || '.svg'`
ELSE '/home/cyrille/public_html/30DayMapChallenge/2023/day10/svg/forest-' || "neighbourhood" || '.svg'`
END
```

Or maybe we make two types of tiles for each, to add some variability:
```
'/home/cyrille/public_html/30DayMapChallenge/2023/day10/svg/forest-0-' || rand(0,1) || '.svg'`
```

See other alternatives using [this helpful SO response](https://gis.stackexchange.com/questions/415335/using-data-defined-override-for-svg-marker-lines).

## Making the reference tiles
Make the 0 tile that' you're happy with. Then duplicate 63 more times:
```bash
for i in {1..63}; do cp 0.svg "$i.svg"; done
```
