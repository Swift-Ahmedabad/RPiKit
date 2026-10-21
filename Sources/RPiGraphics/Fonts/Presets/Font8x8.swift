//
//  Font8x8.swift
//  RpiServer
//
//  Standard 8x8 monochrome bitmap font (aliased from BitmapFont.font8x8)
//

import Foundation

public enum Font8x8 {
    public static var glyphs: [[UInt8]] { BitmapFont.font8x8.glyphs }
}
