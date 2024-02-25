#!/usr/bin/env python3

import sys
import struct
import PIL
from PIL import Image, ImageOps
from pathlib import Path

def main(argv=None):
    print("Image Converter v1.0")
    if len(sys.argv) == 2: # Print Error If Not Enough Arguments Given
        print("Error: Output file not specified")
        print("Usage: image_converter [image_in] [file_out]")
        print("Supported images: BLP, BMP, DDS, DIB, EPS, GIF, ICNS, ICO, IM, JPEG, JPEG 2000,")
        print("                  MSP, PCX, PNG, PPM, SGI, SPIDER, TGA, TIFF, WebP and XBM")
        sys.exit()
    if len(sys.argv) >= 4: # Print Error If Too Many Arguments Given
        print("Error: Too many arguments specified")
        print("Usage: image_converter [image_in] [file_out]")
        print("Supported images: BLP, BMP, DDS, DIB, EPS, GIF, ICNS, ICO, IM, JPEG, JPEG 2000,")
        print("                  MSP, PCX, PNG, PPM, SGI, SPIDER, TGA, TIFF, WebP and XBM")
        sys.exit()
    if len(sys.argv) == 1: # Print Usage If No Arguments Given
        print("Usage: image_converter [image_in] [file_out]")
        print("Supported images: BLP, BMP, DDS, DIB, EPS, GIF, ICNS, ICO, IM, JPEG, JPEG 2000,")
        print("                  MSP, PCX, PNG, PPM, SGI, SPIDER, TGA, TIFF, WebP and XBM")
    else: # Convert Image
        if argv is None: argv = sys.argv[1:]
        infilename, outfilename = argv
        in_file = Path(infilename)

        if in_file.is_file(): # Input File Exists
            in_img = PIL.Image.open(infilename)
            out_img = open(outfilename, 'wb')
            width, height = in_img.size
            print("Image: Name   =", infilename)
            print("Image: Width  =", width)
            print("Image: Height =", height)
            print("Saving Image...")

            # PASS 1: Convert Image To monochrome
            rgb_img = in_img.convert("L")
            #rgb_img.show()

            # PASS 2: Rotate Image 90 Degrees Anti-Clockwise
            out = rgb_img.rotate(90, expand=True)
            #out.show()

            # PASS 3: Convert Image Data To 32-bit $BGRA Binary Data
            pixels = out.getdata()
            image = []
            for i in range(width*height):
                image.append(255-pixels[i]) # Blue Byte
                image.append(0)
            for i in range((width*height)*2): out_img.write(struct.pack('B', image[i])) # Write Header + Pixels
            out_img.close()
            print("Done")
        else: # Input File Does Not Exist
            print("Error: Couldn't open the file", infilename, "for input")
            print("Usage: image_converter [image_in] [file_out]")
            print("Supported images: BLP, BMP, DDS, DIB, EPS, GIF, ICNS, ICO, IM, JPEG, JPEG 2000,")
            print("                  MSP, PCX, PNG, PPM, SGI, SPIDER, TGA, TIFF, WebP and XBM")

if __name__ == '__main__':
    main()
