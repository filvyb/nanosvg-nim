# nanosvg-nim

Nim wrapper for nanosvg - a simple SVG parser and rasterizer library.

Based on nanosvg commit 66579081d84b613daa49a64f76357ce65925e13b.

## Features

- **Automatic memory management** with destructors
- **Type-safe iterators** for shapes and paths
- **Nim-idiomatic API** with clean, readable code

## Installation

```bash
nimble install https://github.com/filvyb/nanosvg-nim.git
```

## Compile Options

- `-d:nanosvgAllColors` - Enable all ~140 CSS/SVG color keywords

## API Modules

- **nanosvg** - SVG parsing (`parseFile`, `parse`, iterators for shapes/paths)
- **nanosvgrast** - SVG rasterization (`createRasterizer`, `rasterize`)

## License

Zlib license
