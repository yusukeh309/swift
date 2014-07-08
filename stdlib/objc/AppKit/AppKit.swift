//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
@exported import AppKit

class REPLApplication : NSApplication {
}

/// Initializes and runs a REPLApplication on the main thread asynchronously.
internal func replApplicationMain() {
  _precondition(NSApp === nil)
  // Create a REPLApplication as the NSApp.
  let app = REPLApplication.sharedApplication() as REPLApplication

  // Set the activation policy so we get a dock icon and can go foreground.
  app.setActivationPolicy(.Regular)

  // Run asynchronously.
  NSOperationQueue.mainQueue().addOperationWithBlock { app.run() }

  // Quit the NSApplication when the REPL quits.
  _atREPLExit({ app.terminate(nil) })

}

struct _NSViewMirror : Mirror {
  var _v : NSView
  
  init(_ v : NSView) {_v = v}
  
  var value: Any { get { return _v } }
  
  var valueType: Any.Type { get { return (_v as Any).dynamicType } }
  
  var objectIdentifier: ObjectIdentifier? { get { return .None } }
  
  var count: Int { get { return 0 } }
  
  subscript(_: Int) -> (String,Mirror) { get { _fatalError("Mirror access out of bounds") } }
  
  var summary: String { get { return ""} }
  
  var quickLookObject: QuickLookObject? { get {
      // this code comes straight from the quicklooks
      
      /*NSBitmapImageRep *b = (NSBitmapImageRep *)[%dataValueName% bitmapImageRepForCachingDisplayInRect:(NSRect)[%dataValueName% bounds]];
      (void)[%dataValueName% cacheDisplayInRect:(NSRect)[%dataValueName% bounds] toBitmapImageRep:b];
      (NSData *)[b representationUsingType:4 properties:nil];*/
      
      let bounds = _v.bounds
      
      // we need to do this check to avoid the @unchecked -> Any -> NSObject cast failure
      if var b = _v.bitmapImageRepForCachingDisplayInRect(bounds) {
          _v.cacheDisplayInRect(bounds, toBitmapImageRep: b)
          // don't do the last step - return the image and the encoder will translate the NSImage to a TIFF alright
          return .Some(.View(b))
      }
      return nil
      
  } }
  
  var disposition : MirrorDisposition { get { return .Aggregate } }
}

extension NSView : Reflectable {
  public func getMirror() -> Mirror {
    return _NSViewMirror(self)
  }
}

// Overlays for variadics.

public extension NSGradient {
  convenience init(colorsAndLocations objects: (NSColor, CGFloat)...) {
    self.init(
      colors: objects.map { $0.0 },
      atLocations: objects.map { $0.1 },
      colorSpace: NSColorSpace.genericRGBColorSpace())
  }
}

// Fix the ARGV type of NSApplicationMain, which nonsensically takes
// argv as a const char**.
@asmname("NSApplicationMain")
func NSApplicationMain(argc: Int32, argv: UnsafePointer<UnsafePointer<CChar>>)
  -> Int32
