## Example 2: Rasterizing SVG to RGBA pixels
##
## This example demonstrates how to parse an SVG file and rasterize it
## to RGBA pixel data using the nanosvgrast module.

import ../src/nanosvg
import ../src/nanosvgrast

proc main() =
  echo "Parsing SVG..."
  let image = parseFile("examples/test.svg", "px", 96.0)

  if image.isNil:
    echo "Error: Could not parse SVG file"
    return

  echo "SVG parsed successfully"
  echo "  Original size: ", image.width, " x ", image.height

  let rast = createRasterizer()
  if rast.isNil:
    echo "Error: Could not create rasterizer"
    return

  let outputWidth = 512
  let outputHeight = 512

  let scaleX = outputWidth.float / image.width
  let scaleY = outputHeight.float / image.height
  let scale = min(scaleX, scaleY)

  echo "\nRasterizing to ", outputWidth, " x ", outputHeight, " pixels..."
  echo "  Scale factor: ", scale

  let pixels = rast.rasterize(image, 0, 0, scale, outputWidth, outputHeight)

  echo "Rasterization complete!"
  echo "  Output buffer size: ", pixels.len, " bytes (", outputWidth * outputHeight * 4, " expected)"

  echo "\nSample pixel data (first pixel, RGBA):"
  echo "  R: ", pixels[0]
  echo "  G: ", pixels[1]
  echo "  B: ", pixels[2]
  echo "  A: ", pixels[3]

  var nonTransparent = 0
  for i in countup(0, pixels.len - 4, 4):
    if pixels[i + 3] > 0:
      inc nonTransparent

  echo "\nStatistics:"
  echo "  Total pixels: ", outputWidth * outputHeight
  echo "  Non-transparent pixels: ", nonTransparent
  echo "  Transparency: ", ((outputWidth * outputHeight - nonTransparent) * 100) div (outputWidth * outputHeight), "%"

when isMainModule:
  main()
