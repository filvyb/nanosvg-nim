## NanoSVG - Simple SVG parser for Nim
##
## This module provides Nim bindings for the nanosvg library,
## a simple single-header SVG parser that outputs cubic bezier shapes.
##
## Example:
## ```nim
## let image = parseFile("test.svg", "px", 96.0)
## if not image.isNil:
##   echo "Size: ", image.width, " x ", image.height
##   for shape in image.shapes:
##     for path in shape.paths:
##       for i in 0..<path.npts-1 by 3:
##         # Access cubic bezier points
##         let p = path.pts
##         # Draw curve using p[i*2], p[i*2+1], etc.
##   # Image is automatically freed when it goes out of scope
## ```

import std/os

const srcDir = currentSourcePath.parentDir()
{.passC: "-I" & srcDir.}

# Compile-time options
when defined(nanosvgAllColors):
  ## Enable all ~140 CSS/SVG color keywords (aliceblue, antiquewhite, etc.)
  ## To enable: compile with -d:nanosvgAllColors
  {.passC: "-DNANOSVG_ALL_COLOR_KEYWORDS".}

{.emit: """
#define NANOSVG_IMPLEMENTATION
#include "nanosvg.h"
""".}

type
  PaintType* {.size: sizeof(cint).} = enum
    ## Type of paint for fills and strokes
    Undef = -1
    None = 0
    Color = 1
    LinearGradient = 2
    RadialGradient = 3

  SpreadType* {.size: sizeof(cint).} = enum
    ## Gradient spread method
    Pad = 0
    Reflect = 1
    Repeat = 2

  LineJoin* {.size: sizeof(cint).} = enum
    ## Line join style
    Miter = 0
    Round = 1
    Bevel = 2

  LineCap* {.size: sizeof(cint).} = enum
    ## Line cap style
    Butt = 0
    Round = 1
    Square = 2

  FillRule* {.size: sizeof(cint).} = enum
    ## Fill rule for shapes
    NonZero = 0
    EvenOdd = 1

  PaintOrderField* {.size: sizeof(cint).} = enum
    ## Paint order fields (3×2-bit fields)
    Fill = 0x00
    Markers = 0x01
    Stroke = 0x02

  Flags* = distinct uint8
    ## Shape visibility flags

  GradientStop* {.bycopy.} = object
    ## Gradient color stop
    color*: cuint
    offset*: cfloat

  GradientObj {.bycopy.} = object
    xform*: array[6, cfloat]
    spread*: cchar
    fx*, fy*: cfloat
    nstops*: cint
    stops*: UncheckedArray[GradientStop]

  Gradient* = ptr GradientObj
    ## Gradient definition

  PaintObj* {.bycopy, union.} = object
    color*: cuint
    gradient*: Gradient

  Paint* {.bycopy.} = object
    ## Paint definition for fills and strokes
    typ* {.importc: "type".}: cchar
    paint*: PaintObj

  PathObj {.bycopy.} = object
    pts*: ptr cfloat
    npts*: cint
    closed*: cchar
    bounds*: array[4, cfloat]
    next*: Path

  Path* = ptr PathObj
    ## SVG path containing cubic bezier points

  ShapeObj {.bycopy.} = object
    id*: array[64, cchar]
    fill*: Paint
    stroke*: Paint
    opacity*: cfloat
    strokeWidth*: cfloat
    strokeDashOffset*: cfloat
    strokeDashArray*: array[8, cfloat]
    strokeDashCount*: cchar
    strokeLineJoin*: cchar
    strokeLineCap*: cchar
    miterLimit*: cfloat
    fillRule*: cchar
    paintOrder*: uint8
    flags*: uint8
    bounds*: array[4, cfloat]
    fillGradient*: array[64, cchar]
    strokeGradient*: array[64, cchar]
    xform*: array[6, cfloat]
    paths*: Path
    next*: Shape

  Shape* = ptr ShapeObj
    ## SVG shape containing paths and styling

  ImageObj {.bycopy.} = object
    width*: cfloat
    height*: cfloat
    shapes*: Shape

  ImagePtr = ptr ImageObj
    ## Raw C pointer to SVG image

  Image* = object
    ## Parsed SVG image with automatic memory management
    handle: ImagePtr

# Raw C API bindings
proc nsvgParseFromFile(filename: cstring, units: cstring, dpi: cfloat): ImagePtr
  {.importc: "nsvgParseFromFile", nodecl.}

proc nsvgParse(input: cstring, units: cstring, dpi: cfloat): ImagePtr
  {.importc: "nsvgParse", nodecl.}

proc nsvgDuplicatePath(p: Path): Path
  {.importc: "nsvgDuplicatePath", nodecl.}

proc nsvgDelete(image: ImagePtr)
  {.importc: "nsvgDelete", nodecl.}

# Flag operations
const Visible* = Flags(0x01)

proc `==`*(a, b: Flags): bool {.borrow.}
proc `and`*(a, b: Flags): Flags {.borrow.}
proc `or`*(a, b: Flags): Flags {.borrow.}
proc contains*(flags: Flags, flag: Flags): bool =
  ## Check if flags contain the specified flag
  (flags and flag) == flag

# Memory management
proc `=destroy`*(img: var Image) =
  if img.handle != nil:
    nsvgDelete(img.handle)

proc `=copy`*(dest: var Image, src: Image) {.error.}
  ## Images cannot be copied to prevent double-free

proc `=wasMoved`*(img: var Image) =
  img.handle = nil

proc parseFile*(filename: string, units: string = "px", dpi: float = 96.0): Image =
  ## Parse SVG from a file
  ##
  ## The image will be automatically freed when it goes out of scope.
  ##
  ## Parameters:
  ##   filename: Path to the SVG file
  ##   units: Units for coordinates ("px", "pt", "pc", "mm", "cm", "in")
  ##   dpi: Dots per inch for unit conversion
  ##
  ## Returns: Parsed SVG image (handle will be nil on error)
  result.handle = nsvgParseFromFile(filename.cstring, units.cstring, dpi.cfloat)

proc parse*(input: string, units: string = "px", dpi: float = 96.0): Image =
  ## Parse SVG from a string
  ##
  ## The image will be automatically freed when it goes out of scope.
  ## Warning: This modifies the input string. Make a copy if needed.
  ##
  ## Parameters:
  ##   input: SVG content as a string
  ##   units: Units for coordinates ("px", "pt", "pc", "mm", "cm", "in")
  ##   dpi: Dots per inch for unit conversion
  ##
  ## Returns: Parsed SVG image (handle will be nil on error)
  var mutableInput = input
  result.handle = nsvgParse(mutableInput.cstring, units.cstring, dpi.cfloat)

proc duplicate*(path: Path): Path =
  ## Create a deep copy of a path
  nsvgDuplicatePath(path)

proc isNil*(image: Image): bool =
  ## Check if image failed to parse
  image.handle == nil

iterator shapes*(image: Image): Shape =
  ## Iterate over all shapes in an image
  if image.handle != nil:
    var shape = image.handle.shapes
    while shape != nil:
      yield shape
      shape = shape.next

iterator paths*(shape: Shape): Path =
  ## Iterate over all paths in a shape
  if shape != nil:
    var path = shape.paths
    while path != nil:
      yield path
      path = path.next

iterator stops*(gradient: Gradient): GradientStop =
  ## Iterate over gradient stops
  if gradient != nil:
    for i in 0..<gradient.nstops:
      yield gradient.stops[i]

# Convenience accessors
proc paintType*(paint: Paint): PaintType =
  ## Get the paint type
  PaintType(paint.typ)

proc getPaintColor*(paint: Paint): uint32 =
  ## Get the color from a paint (only valid if paintType is Color)
  paint.paint.color

proc getPaintGradient*(paint: Gradient): Gradient =
  ## Get the gradient from a paint (only valid if paintType is gradient)
  paint

proc isVisible*(shape: Shape): bool =
  ## Check if a shape is visible
  if shape == nil: return false
  Visible in Flags(shape.flags)

proc getId*(shape: Shape): string =
  ## Get the shape ID as a Nim string
  if shape == nil: return ""
  $cast[cstring](addr shape.id[0])

proc getFillGradient*(shape: Shape): string =
  ## Get the fill gradient ID as a Nim string
  if shape == nil: return ""
  $cast[cstring](addr shape.fillGradient[0])

proc getStrokeGradient*(shape: Shape): string =
  ## Get the stroke gradient ID as a Nim string
  if shape == nil: return ""
  $cast[cstring](addr shape.strokeGradient[0])

proc getLineJoin*(shape: Shape): LineJoin =
  ## Get the line join style
  if shape == nil: return Miter
  LineJoin(shape.strokeLineJoin)

proc getLineCap*(shape: Shape): LineCap =
  ## Get the line cap style
  if shape == nil: return Butt
  LineCap(shape.strokeLineCap)

proc getFillRule*(shape: Shape): FillRule =
  ## Get the fill rule
  if shape == nil: return NonZero
  FillRule(shape.fillRule)

proc `[]`*(path: Path, index: int): float =
  ## Access a point coordinate by index
  ## Points are stored as [x0,y0, cpx1,cpy1, cpx2,cpy2, x1,y1, ...]
  if path == nil or index < 0 or index >= path.npts * 2:
    raise newException(IndexDefect, "Path point index out of bounds")
  cast[ptr UncheckedArray[cfloat]](path.pts)[index].float

proc len*(path: Path): int =
  ## Get the number of points in a path (actual coordinates = npts * 2)
  if path == nil: return 0
  path.npts.int

proc isClosed*(path: Path): bool =
  ## Check if a path is closed
  if path == nil: return false
  path.closed != cchar(0)

type Bounds* = tuple[minX, minY, maxX, maxY: float]

proc bounds*(path: Path): Bounds =
  ## Get the bounding box of a path
  if path == nil:
    return (0.0, 0.0, 0.0, 0.0)
  (path.bounds[0].float, path.bounds[1].float,
   path.bounds[2].float, path.bounds[3].float)

proc bounds*(shape: Shape): Bounds =
  ## Get the bounding box of a shape
  if shape == nil:
    return (0.0, 0.0, 0.0, 0.0)
  (shape.bounds[0].float, shape.bounds[1].float,
   shape.bounds[2].float, shape.bounds[3].float)

proc width*(image: Image): float =
  ## Get the image width
  if image.handle == nil: return 0.0
  image.handle.width.float

proc height*(image: Image): float =
  ## Get the image height
  if image.handle == nil: return 0.0
  image.handle.height.float

