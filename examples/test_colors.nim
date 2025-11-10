import ../src/nanosvg
import strformat

let image = parseFile("examples/test_colors.svg", "px", 96.0)
if image.isNil:
  echo "Failed to parse SVG!"
  quit(1)

for shape in image.shapes:
  let fillType = shape.fill.paintType
  if fillType == PaintType.Color:
    let color = shape.fill.getPaintColor()
    let r = color and 0xFF
    let g = (color shr 8) and 0xFF
    let b = (color shr 16) and 0xFF
    echo fmt"Shape fill: RGB({r}, {g}, {b})"
