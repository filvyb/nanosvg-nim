import ../src/nanosvg
import strutils

proc rgbaToHex(color: uint32): string =
  ## Convert RGBA color to hex string
  let r = (color and 0xFF)
  let g = (color shr 8) and 0xFF
  let b = (color shr 16) and 0xFF
  let a = (color shr 24) and 0xFF
  result = "#"
  result.add r.toHex(2)
  result.add g.toHex(2)
  result.add b.toHex(2)
  if a != 0xFF:
    result.add a.toHex(2)


echo "Parsing test.svg..."
let image = parseFile("examples/test.svg", "px", 96.0)

if image.isNil:
  echo "Failed to parse SVG!"
  quit(1)

echo "\nImage dimensions: ", image.width, " x ", image.height

var shapeCount = 0
for shape in shapes(image):
  shapeCount.inc
  echo "\n--- Shape ", shapeCount, " ---"

  let id = shape.getId()
  if id.len > 0:
    echo "ID: ", id

  let fillType = shape.fill.paintType
  echo "Fill type: ", fillType
  if fillType == PaintType.Color:
    echo "  Color: ", rgbaToHex(shape.fill.getPaintColor())

  let strokeType = shape.stroke.paintType
  echo "Stroke type: ", strokeType
  if strokeType == PaintType.Color:
    echo "  Color: ", rgbaToHex(shape.stroke.getPaintColor())
    echo "  Width: ", shape.strokeWidth

  let b = shape.bounds
  echo "Bounds: [", b[0], ", ", b[1], ", ", b[2], ", ", b[3], "]"

  echo "Visible: ", shape.isVisible

  var pathCount = 0
  for path in paths(shape):
    pathCount.inc
    echo "  Path ", pathCount, ":"
    echo "    Points: ", path.len
    echo "    Closed: ", path.isClosed

    if path.len > 0:
      echo "    First point: (", path[0], ", ", path[1], ")"

echo "\nDone!"
