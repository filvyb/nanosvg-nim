# nanosvg-nim

Nim wrapper for nanosvg - a simple SVG parser library that outputs cubic bezier shapes.

Based on nanosvg commit 66579081d84b613daa49a64f76357ce65925e13b.

## Features

- Parse SVG files and strings into structured data
- Automatic memory management with destructors
- Type-safe iterators for shapes and paths

## Quick Example

```nim
import nanosvg

let image = parseFile("test.svg", "px", 96.0)
if not image.isNil:
  echo "Size: ", image.width, " x ", image.height

  for shape in image.shapes:
    echo "Shape ID: ", shape.getId()
    for path in shape.paths:
      echo "  Points: ", path.len
      echo "  Closed: ", path.isClosed
```

## Installation

```bash
nimble install nanosvg
```

## Compile Options

- `-d:nanosvgAllColors` - Enable all ~140 CSS/SVG color keywords

## Status

- **nanosvg.h**: Complete
- **nanosvgrast.h**: Not yet implemented

## License

Zlib license

