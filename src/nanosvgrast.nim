## NanoSVG Rasterizer - SVG rasterization for Nim
##
## This module provides Nim bindings for the nanosvg rasterizer library,
## which renders parsed SVG images to RGBA pixels.
##
## Example:
## ```nim
## import nanosvg
## import nanosvgrast
##
## let image = parseFile("test.svg", "px", 96.0)
## if not image.isNil:
##   let rast = createRasterizer()
##   if not rast.isNil:
##     let width = 512
##     let height = 512
##     let scale = width.float / image.width
##     let pixels = rast.rasterize(image, 0, 0, scale, width, height)
##     # pixels now contains RGBA data (width * height * 4 bytes)
##     # Rasterizer and image are automatically freed when out of scope
## ```

import std/os
import nanosvg

const srcDir = currentSourcePath.parentDir()
{.passC: "-I" & srcDir.}

{.emit: """
#define NANOSVGRAST_IMPLEMENTATION
#include "nanosvgrast.h"
""".}

type RasterizerPtr = ptr object
  ## Raw C pointer to rasterizer context (opaque)

proc nsvgCreateRasterizer(): RasterizerPtr
  {.importc: "nsvgCreateRasterizer", nodecl.}

proc nsvgRasterize(r: RasterizerPtr, image: pointer, tx, ty, scale: cfloat,
                   dst: pointer, w, h, stride: cint)
  {.importc: "nsvgRasterize", nodecl.}

proc nsvgDeleteRasterizer(r: RasterizerPtr)
  {.importc: "nsvgDeleteRasterizer", nodecl.}

type
  Rasterizer* = object
    ## Rasterizer context with automatic memory management
    handle: RasterizerPtr

proc `=destroy`*(rast: var Rasterizer) =
  if rast.handle != nil:
    nsvgDeleteRasterizer(rast.handle)

proc `=copy`*(dest: var Rasterizer, src: Rasterizer) {.error.}
  ## Rasterizers cannot be copied to prevent double-free

proc `=wasMoved`*(rast: var Rasterizer) =
  rast.handle = nil

proc createRasterizer*(): Rasterizer =
  ## Create a rasterizer context
  ##
  ## The rasterizer will be automatically freed when it goes out of scope.
  ## A single rasterizer can be reused to render multiple images.
  ##
  ## Returns: Rasterizer context (handle will be nil on allocation failure)
  result.handle = nsvgCreateRasterizer()

proc isNil*(rast: Rasterizer): bool =
  ## Check if rasterizer failed to create
  rast.handle == nil

proc rasterize*(rast: Rasterizer, image: Image,
                tx: float = 0.0, ty: float = 0.0, scale: float = 1.0,
                dst: var openArray[uint8], width, height, stride: int) =
  ## Rasterize an SVG image to RGBA pixels (non-premultiplied alpha)
  ##
  ## Parameters:
  ##   rast: Rasterizer context
  ##   image: Parsed SVG image
  ##   tx, ty: Image offset in pixels (applied after scaling)
  ##   scale: Image scale factor
  ##   dst: Destination buffer for RGBA data (4 bytes per pixel)
  ##   width: Width of the output image in pixels
  ##   height: Height of the output image in pixels
  ##   stride: Number of bytes per scanline in destination buffer
  ##
  ## The destination buffer must be at least height * stride bytes.
  ## For tightly packed rows, stride should be width * 4.

  if rast.handle == nil:
    raise newException(ValueError, "Rasterizer is nil")
  if image.isNil:
    raise newException(ValueError, "Image is nil")
  if dst.len < height * stride:
    raise newException(ValueError, "Destination buffer too small")

  # Access the internal handle from Image
  # We need to get the raw pointer from the Image object
  let imagePtr = image.toPtr()
  nsvgRasterize(rast.handle, imagePtr, tx.cfloat, ty.cfloat, scale.cfloat,
                addr dst[0], width.cint, height.cint, stride.cint)

proc rasterize*(rast: Rasterizer, image: Image,
                tx: float = 0.0, ty: float = 0.0, scale: float = 1.0,
                width, height: int): seq[uint8] =
  ## Rasterize an SVG image to RGBA pixels and return as a new sequence
  ##
  ## This is a convenience function that allocates the output buffer.
  ## For the tightly packed result, stride = width * 4.
  ##
  ## Parameters:
  ##   rast: Rasterizer context
  ##   image: Parsed SVG image
  ##   tx, ty: Image offset in pixels (applied after scaling)
  ##   scale: Image scale factor
  ##   width: Width of the output image in pixels
  ##   height: Height of the output image in pixels
  ##
  ## Returns: RGBA pixel data (4 bytes per pixel, size = width * height * 4)
  let stride = width * 4
  result = newSeq[uint8](height * stride)
  rast.rasterize(image, tx, ty, scale, result, width, height, stride)
