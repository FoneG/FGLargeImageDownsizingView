//
//  FGLargeImageDownsizingView.swift
//  FGLargeImageDownsizing_Example
//
//  Created by FoneG on 2021/12/15.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

/* Image Constants: for images, we define the resulting image
 size and tile size in megabytes. This translates to an amount
 of pixels. Keep in mind this is almost always significantly different
 from the size of a file on disk for compressed formats such as png, or jpeg.
 
 For an image to be displayed in iOS, it must first be uncompressed (decoded) from
 disk. The approximate region of pixel data that is decoded from disk is defined by both,
 the clipping rect set onto the current graphics context, and the content/image
 offset relative to the current context.
 
 To get the uncompressed file size of an image, use: Width x Height / pixelsPerMB, where
 pixelsPerMB = 262144 pixels in a 32bit colospace (which iOS is optimized for).
 
 Supported formats are: PNG, TIFF, JPEG. Unsupported formats: GIF, BMP, interlaced images.
 */
open class FGLargeImageDownsizingView: UIImageView {
        
    public func setContentsOfFile(_ contentsOfFile: String) {
        guard let sourceImage = UIImage(contentsOfFile: contentsOfFile) else {
            print("input image not found!"); return
        }
        Thread.detachNewThreadSelector(#selector(downsize), toTarget: self, with: sourceImage)
    }
    
    @objc func downsize(_ sourceImage: UIImage) {
        
        autoreleasepool {
            let sourceResolutionWidth = CGFloat(sourceImage.cgImage?.width ?? 0)
            let sourceResolutionHeight = CGFloat(sourceImage.cgImage?.height ?? 0)
            
            let sourceTotalPixels = sourceResolutionWidth * sourceResolutionHeight
            // determine the scale ratio to apply to the input image
            // that results in an output image of the defined size.
            // see kDestImageSizeMB, and how it relates to destTotalPixels.
            let imageScale = destTotalPixels / sourceTotalPixels
            
            // use the image scale to calcualte the output image width, height
            let destResolutionWidth = Int(sourceResolutionWidth * imageScale)
            let destResolutionHeight = Int(sourceResolutionHeight * imageScale)
            
            // create an offscreen bitmap context that will hold the output image
            // pixel data, as it becomes available by the downscaling routine.
            // use the RGB colorspace as this is the colorspace iOS GPU is optimized for.
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bytesPerRow = Int(bytesPerPixel) * Int(sourceResolutionWidth * imageScale)
            let bytesPointer = UnsafeMutableRawPointer.allocate(byteCount: bytesPerRow * destResolutionHeight, alignment: 1)
            
            // create the output bitmap context
            let context = CGContext.init(data: bytesPointer, width: destResolutionWidth, height: destResolutionHeight, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            
            guard let destContext = context else {
                print("failed to create the output bitmap context!")
                free(bytesPointer)
                return
            }
            progressContext = destContext
            // flip the output graphics context so that it aligns with the
            // cocoa style orientation of the input document. this is needed
            // because we used cocoa's UIImage -imageNamed to open the input file.
            destContext.translateBy(x: 0.0, y: CGFloat(destResolutionHeight))
            destContext.scaleBy(x: 1.0, y: -1.0)
            
            // now define the size of the rectangle to be used for the
            // incremental blits from the input image to the output image.
            // we use a source tile width equal to the width of the source
            // image due to the way that iOS retrieves image data from disk.
            // iOS must decode an image from disk in full width 'bands', even
            // if current graphics context is clipped to a subrect within that
            // band. Therefore we fully utilize all of the pixel data that results
            // from a decoding opertion by achnoring our tile size to the full
            // width of the input image.
            var sourceTile = CGRect()
            sourceTile.origin.x = 0.0
            sourceTile.size.width = sourceResolutionWidth
            // the source tile height is dynamic. Since we specified the size
            // of the source tile in MB, see how many rows of pixels high it
            // can be given the input image width.
            sourceTile.size.height = CGFloat(Int(tileTotalPixels / sourceResolutionWidth))
            print("source tile size: \(sourceTile.size.width) x \(sourceTile.size.height)")
            
            var destTile = CGRect()
            destTile.origin.x = 0.0
            // the output tile is the same proportions as the input tile, but
            // scaled to image scale.
            destTile.size.width = CGFloat(destResolutionWidth)
            destTile.size.height = sourceTile.size.height * imageScale
            print("dest tile size width:\(destTile.size.width) height: \(destTile.size.height)")
            //the number of pixels to overlap tiles as they are assembled.
            let sourceSeemOverlap = Int(destSeemOverlap / CGFloat(destResolutionHeight) * sourceResolutionHeight)
            print("dest seem overlap: \(destSeemOverlap), source seem overlap: \(sourceSeemOverlap)")
            // calculate the number of read/write opertions required to assemble the
            // output image.
            var iterations = Int(sourceResolutionHeight / sourceTile.size.height)
            // if tile height doesn't divide the image height evenly, add another iteration
            // to account for the remaining pixels.
            let remainder = Int(sourceResolutionHeight) % Int(sourceTile.size.height)
            if remainder > 0 { iterations += 1 }
            // add seem overlaps to the tiles, but save the original tile height for y coordinate calculations.
            let sourceTileHeightMinusOverlap = sourceTile.size.height
            sourceTile.size.height += CGFloat(sourceSeemOverlap)
            destTile.size.height += destSeemOverlap
            print("beginning downsize. iterations: \(iterations), tile height: \(sourceTile.size.height), remainder height: \(remainder)")
            
            for y in 0...iterations-1 {
                // create an autorelease pool to catch calls to -autorelease made within the downsize loop.
                autoreleasepool {
                    var sourceTileImageRef: CGImage
                    print("iteration \(y + 1) of \(iterations)")
                    sourceTile.origin.y = CGFloat(y) * sourceTileHeightMinusOverlap + CGFloat(sourceSeemOverlap)
                    destTile.origin.y = CGFloat( destResolutionHeight ) - ( CGFloat( y + 1 ) * sourceTileHeightMinusOverlap * imageScale + destSeemOverlap )
                    
                    // create a reference to the source image with its context clipped to the argument rect.
                    if let tileImageRef = sourceImage.cgImage?.cropping(to: sourceTile) {
                        sourceTileImageRef = tileImageRef
                    }
                    guard let tileImageRef = sourceImage.cgImage?.cropping(to: sourceTile) else { print("cropping sourceImage is NULL \(sourceTile)"); return }
                    sourceTileImageRef = tileImageRef
                    
                    // if this is the last tile, it's size may be smaller than the source tile height.
                    // adjust the dest tile size to account for that difference.
                    if y == iterations - 1 && remainder > 0  {
                        var dify = destTile.size.height;
                        destTile.size.height = CGFloat(sourceTileImageRef.height) * imageScale
                        dify -= destTile.size.height
                        destTile.origin.y += dify
                    }
                    
                    // read and write a tile sized portion of pixels from the input image to the output image.
                    destContext.draw(sourceTileImageRef, in: destTile)
                    
                    performSelector(onMainThread:  #selector(updateScrollView), with: self, waitUntilDone: true)
                }
            }
            print("downsize complete.")
        }
    }
    
    @objc func updateScrollView() {
        guard let destImageRef = progressContext?.makeImage() else {
            print("destImageRef is null.") ; return
        }
        let destImage = UIImage.init(cgImage: destImageRef, scale: 1.0, orientation: .downMirrored)
        image = destImage
    }
    
    //MARK: Get
        
    public var kDestImageSizeMB: CGFloat = 60.0 // The resulting image will be (x)MB of uncompressed image data.
    public var kSourceImageTileSizeMB: CGFloat = 20.0 // The tile size will be (x)MB of uncompressed image data.
    
    let bytesPerMB: CGFloat = 1048576.0
    let bytesPerPixel: CGFloat = 4.0
    let destSeemOverlap: CGFloat = 2.0 // the numbers of pixels to overlap the seems where tiles meet.
    
    var pixelsPerMB : CGFloat { // 262144 pixels, for 4 bytes per pixel.
        get {
            return bytesPerMB / bytesPerPixel
        }
    }
    var destTotalPixels : CGFloat {
        get {
            return kDestImageSizeMB * pixelsPerMB
        }
    }
    var tileTotalPixels : CGFloat {
        get {
            return kSourceImageTileSizeMB * pixelsPerMB
        }
    }
    
    var progressContext: CGContext?    // the temporary container used to hold the resulting output image pixel data, as it is being assembled.
}
