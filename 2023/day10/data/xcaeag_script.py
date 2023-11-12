"""
Code by Geum Pyrenaicum
@geum@mapstodon.space
https://github.com/xcaeag/30DayMapChallenge-2023/blob/main/day9.md

Minor modifications by Cyrille Médard de Chardon
@serial@urbanists.social
https://github.com/serialc/30DayMapChallenge
"""

import math

import processing
from qgis.core import (QgsFeature, QgsField, QgsGeometry, QgsPoint, QgsProject,
                       QgsVectorLayer)
from qgis.PyQt.QtCore import QVariant
from qgis.PyQt.QtWidgets import QApplication
from qgis.utils import iface

# Functions
def buildGridHex(extent, resolution, crs):
    """resolution
    Constructs a layer of points positioned on a hexagonal grid.

    resolution: width of the tile
    """
    layer = QgsVectorLayer(
        "MultiPoint?crs={}".format(
            crs.authid()), "grid", "memory")
            
    layer.startEditing()
    layer.dataProvider().addAttributes(
        [
            QgsField("col", QVariant.Int),
            QgsField("row", QVariant.Int),
            QgsField("neighbourhood", QVariant.Int),
        ]
    )
    layer.updateFields()

    feats = []

    xres, yres = resolution, (resolution * math.sqrt(0.75))
    nrows = int(extent.height() / yres)
    ncols = int(extent.width() / xres)
    
    print(ncols, nrows)

    for row in range(nrows):
        for col in range(ncols):
            # the xres/2 and yres/2 make the points centered
            x = extent.xMinimum() + col * xres + xres/2
            y = extent.yMinimum() + row * yres + yres/2

            # for every second row offset by half a cell width
            dx = (row % 2) * (resolution / 2)

            # new point coordinates
            vtx = QgsPoint(x + dx, y)
            newG = QgsGeometry(vtx)

            # create feature with geometry and attributes
            newF = QgsFeature()
            newF.setGeometry(newG)
            newF.setFields(layer.fields())
            newF.setAttribute("col", col)
            newF.setAttribute("row", row)
            newF.setAttribute("neighbourhood", 0)

            # add to the list of features
            feats.append(newF)

    layer.dataProvider().addFeatures(feats)
    layer.commitChanges()

    return layer

def intersection(grid, polys):
    r = processing.run(
        "native:intersection",
        {
            "INPUT": grid,
            "OVERLAY": polys,
            "INPUT_FIELDS": "",
            "OVERLAY_FIELDS": "",
            "OVERLAY_FIELDS_PREFIX": "",
            "GRID_SIZE": None,
            "OUTPUT": "TEMPORARY_OUTPUT",
        },
    )
    return r["OUTPUT"]


def updateNeighbourhood(grid):
    """
    Code the 'neighbourhood' field.

    +1 if a neighbour at the top left, +2 if a neighbour at the top right, etc...

          +1  / \\  +2
        +4   |   |   +8
         +16  \\ /  +32

    """
    grid.startEditing()

    p = {}

    # populate the points dict with point features using 'X-Y' keys
    # this serves as a lookup table
    for feat in grid.getFeatures():
        # create col dict if needed
        if feat['col'] not in p:
            p[feat['col']] = {}

        # populate multidimensional dict
        p[feat['col']][feat['row']] = feat

    # determine neighbours using lookup dict p
    for feat in grid.getFeatures():
        c, r = feat["col"], feat["row"]
        
        # calculate all six neighbour col/row in tuples
        pvoisins = [
            [c - (r % 2 == 0), r + 1],
            [c + (r % 2 == 1), r + 1],
            [c - 1, r],
            [c + 1, r],
            [c - (r % 2 == 0), r - 1],
            [c + (r % 2 == 1), r - 1],
        ]

        neighbourhood = 0
        # zip: take an element from each list, like a zipper
        for n, cr in zip([1, 2, 4, 8, 16, 32], pvoisins):
            
            # check cell exists in our dict, if so add code
            if cr[0] in p and cr[1] in p[cr[0]]:
                neighbourhood += n

        feat["neighbourhood"] = neighbourhood

        grid.updateFeature(feat)

    grid.commitChanges()


# Main code

# the selected layer in the Layers panel is used as hex generation bounds
target = iface.activeLayer()
EXTENT = target.extent()

# Select the number of tiles (A) or the width of tiles (B)
# Tile width is better for display in QGIS after

# A - how many tiles wide (columns) do you want
NBTILES = 32
# calculate the size of the hex tiles given the extent
HEX_SIZE = EXTENT.width() / NBTILES

# B -override. Scale the tiles in QGIS to use double/8000m
# as my tiles are exactly twice the hexagon width
HEX_SIZE = 4000

# determine the location of centroids of a hexagonal grid covering the polygon
hexgrid = buildGridHex(EXTENT, HEX_SIZE, target.crs())

# get intersection of hexgrid points with target polygon
vhexgrid = intersection(hexgrid, target)

# calculate the hexgrid cell type based on neighbour configuration
updateNeighbourhood(vhexgrid)

QgsProject.instance().addMapLayer(vhexgrid)
