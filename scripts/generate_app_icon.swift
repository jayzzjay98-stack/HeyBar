import AppKit
import Foundation

let outputURL = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppBundle/AppIcon.png")
let size = CGSize(width: 1024, height: 1024)

let image = NSImage(size: size)
image.lockFocus()

guard let context = NSGraphicsContext.current?.cgContext else {
    fputs("Unable to create graphics context.\n", stderr)
    exit(1)
}

func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    let red = CGFloat((hex >> 16) & 0xFF) / 255
    let green = CGFloat((hex >> 8) & 0xFF) / 255
    let blue = CGFloat(hex & 0xFF) / 255
    return NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
}

func fillRoundedRect(_ rect: CGRect, radius: CGFloat, colors: [NSColor], angle: CGFloat = -45) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    path.addClip()
    let gradient = NSGradient(colors: colors) ?? NSGradient(starting: colors[0], ending: colors.last!)!
    gradient.draw(in: path, angle: angle)
}

func stroke(_ path: NSBezierPath, color: NSColor, width: CGFloat) {
    color.setStroke()
    path.lineWidth = width
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.stroke()
}

func fill(_ path: NSBezierPath, color: NSColor) {
    color.setFill()
    path.fill()
}

let canvas = CGRect(origin: .zero, size: size)
fillRoundedRect(canvas, radius: 240, colors: [color(0xFFD25C), color(0xFF835C), color(0xF54B8A)])

let vignette = NSGradient(colors: [color(0xFFFFFF, alpha: 0.22), color(0xFFFFFF, alpha: 0.02)])!
vignette.draw(in: NSBezierPath(roundedRect: canvas.insetBy(dx: 20, dy: 20), xRadius: 220, yRadius: 220), relativeCenterPosition: NSPoint(x: -0.6, y: 0.8))

let shadowPath = NSBezierPath(ovalIn: CGRect(x: 180, y: 140, width: 650, height: 180))
fill(shadowPath, color: color(0x6A203A, alpha: 0.16))

let faceRect = CGRect(x: 214, y: 210, width: 596, height: 596)
let facePath = NSBezierPath(ovalIn: faceRect)
fill(facePath, color: color(0xFFF3DE))
stroke(facePath, color: color(0x40221B), width: 18)

let leftEar = NSBezierPath(ovalIn: CGRect(x: 240, y: 640, width: 112, height: 136))
fill(leftEar, color: color(0xFFF3DE))
stroke(leftEar, color: color(0x40221B), width: 18)

let rightEar = NSBezierPath(ovalIn: CGRect(x: 672, y: 646, width: 100, height: 126))
fill(rightEar, color: color(0xFFF3DE))
stroke(rightEar, color: color(0x40221B), width: 18)

let hair = NSBezierPath()
hair.move(to: CGPoint(x: 238, y: 640))
hair.curve(to: CGPoint(x: 284, y: 838), controlPoint1: CGPoint(x: 212, y: 760), controlPoint2: CGPoint(x: 220, y: 826))
hair.curve(to: CGPoint(x: 470, y: 850), controlPoint1: CGPoint(x: 338, y: 862), controlPoint2: CGPoint(x: 418, y: 864))
hair.curve(to: CGPoint(x: 530, y: 924), controlPoint1: CGPoint(x: 478, y: 846), controlPoint2: CGPoint(x: 500, y: 910))
hair.curve(to: CGPoint(x: 586, y: 850), controlPoint1: CGPoint(x: 558, y: 908), controlPoint2: CGPoint(x: 560, y: 852))
hair.curve(to: CGPoint(x: 780, y: 706), controlPoint1: CGPoint(x: 654, y: 848), controlPoint2: CGPoint(x: 770, y: 818))
hair.curve(to: CGPoint(x: 776, y: 586), controlPoint1: CGPoint(x: 792, y: 674), controlPoint2: CGPoint(x: 794, y: 620))
hair.curve(to: CGPoint(x: 238, y: 640), controlPoint1: CGPoint(x: 646, y: 484), controlPoint2: CGPoint(x: 348, y: 530))
hair.close()
fill(hair, color: color(0x2A1620))

let cheekLeft = NSBezierPath(ovalIn: CGRect(x: 286, y: 410, width: 100, height: 70))
fill(cheekLeft, color: color(0xFF8C8C, alpha: 0.28))
let cheekRight = NSBezierPath(ovalIn: CGRect(x: 646, y: 430, width: 88, height: 64))
fill(cheekRight, color: color(0xFF8C8C, alpha: 0.22))

let eyebrowLeft = NSBezierPath()
eyebrowLeft.move(to: CGPoint(x: 320, y: 632))
eyebrowLeft.curve(to: CGPoint(x: 468, y: 682), controlPoint1: CGPoint(x: 344, y: 680), controlPoint2: CGPoint(x: 430, y: 702))
stroke(eyebrowLeft, color: color(0x2F1716), width: 26)

let eyebrowRight = NSBezierPath()
eyebrowRight.move(to: CGPoint(x: 580, y: 690))
eyebrowRight.curve(to: CGPoint(x: 720, y: 654), controlPoint1: CGPoint(x: 626, y: 708), controlPoint2: CGPoint(x: 684, y: 690))
stroke(eyebrowRight, color: color(0x2F1716), width: 24)

let wink = NSBezierPath()
wink.move(to: CGPoint(x: 320, y: 560))
wink.curve(to: CGPoint(x: 470, y: 560), controlPoint1: CGPoint(x: 362, y: 592), controlPoint2: CGPoint(x: 420, y: 590))
stroke(wink, color: color(0x2F1716), width: 20)

let rightEye = NSBezierPath(ovalIn: CGRect(x: 590, y: 524, width: 116, height: 136))
fill(rightEye, color: color(0xFFFFFF))
stroke(rightEye, color: color(0x2F1716), width: 18)

let pupil = NSBezierPath(ovalIn: CGRect(x: 632, y: 552, width: 52, height: 76))
fill(pupil, color: color(0x23181A))

let eyeSpark = NSBezierPath(ovalIn: CGRect(x: 648, y: 600, width: 18, height: 18))
fill(eyeSpark, color: color(0xFFFFFF, alpha: 0.95))

let nose = NSBezierPath()
nose.move(to: CGPoint(x: 520, y: 498))
nose.curve(to: CGPoint(x: 480, y: 438), controlPoint1: CGPoint(x: 510, y: 470), controlPoint2: CGPoint(x: 472, y: 458))
nose.curve(to: CGPoint(x: 560, y: 438), controlPoint1: CGPoint(x: 500, y: 424), controlPoint2: CGPoint(x: 540, y: 424))
stroke(nose, color: color(0x8F5540), width: 16)

let mouth = NSBezierPath()
mouth.move(to: CGPoint(x: 366, y: 344))
mouth.curve(to: CGPoint(x: 718, y: 398), controlPoint1: CGPoint(x: 438, y: 248), controlPoint2: CGPoint(x: 662, y: 284))
mouth.curve(to: CGPoint(x: 658, y: 318), controlPoint1: CGPoint(x: 732, y: 376), controlPoint2: CGPoint(x: 704, y: 320))
mouth.curve(to: CGPoint(x: 366, y: 344), controlPoint1: CGPoint(x: 580, y: 334), controlPoint2: CGPoint(x: 450, y: 334))
fill(mouth, color: color(0x3B1E2A))

let tongue = NSBezierPath()
tongue.move(to: CGPoint(x: 522, y: 334))
tongue.curve(to: CGPoint(x: 648, y: 332), controlPoint1: CGPoint(x: 552, y: 292), controlPoint2: CGPoint(x: 620, y: 296))
tongue.curve(to: CGPoint(x: 624, y: 252), controlPoint1: CGPoint(x: 652, y: 304), controlPoint2: CGPoint(x: 654, y: 264))
tongue.curve(to: CGPoint(x: 522, y: 334), controlPoint1: CGPoint(x: 596, y: 228), controlPoint2: CGPoint(x: 534, y: 274))
tongue.close()
fill(tongue, color: color(0xFF6E8C))

let tooth = NSBezierPath(roundedRect: CGRect(x: 448, y: 336, width: 94, height: 36), xRadius: 12, yRadius: 12)
fill(tooth, color: color(0xFFFDF8))

let blushMark = NSBezierPath()
blushMark.move(to: CGPoint(x: 712, y: 470))
blushMark.curve(to: CGPoint(x: 770, y: 444), controlPoint1: CGPoint(x: 730, y: 460), controlPoint2: CGPoint(x: 748, y: 446))
stroke(blushMark, color: color(0xA24E5E, alpha: 0.55), width: 10)

let bubble = NSBezierPath(roundedRect: CGRect(x: 104, y: 746, width: 174, height: 114), xRadius: 42, yRadius: 42)
fillRoundedRect(CGRect(x: 104, y: 746, width: 174, height: 114), radius: 42, colors: [color(0xFFF8EC, alpha: 0.96), color(0xFFE8CC, alpha: 0.96)], angle: 90)
stroke(bubble, color: color(0x40221B, alpha: 0.9), width: 12)

let bubbleTail = NSBezierPath()
bubbleTail.move(to: CGPoint(x: 238, y: 748))
bubbleTail.line(to: CGPoint(x: 272, y: 700))
bubbleTail.line(to: CGPoint(x: 202, y: 730))
bubbleTail.close()
fill(bubbleTail, color: color(0xFFF2DE))
stroke(bubbleTail, color: color(0x40221B, alpha: 0.9), width: 10)

let exclamation = NSString(string: "!")
let exclamationAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 72, weight: .black),
    .foregroundColor: color(0x40221B)
]
exclamation.draw(at: CGPoint(x: 164, y: 774), withAttributes: exclamationAttributes)

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let pngData = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Unable to encode PNG.\n", stderr)
    exit(1)
}

try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try pngData.write(to: outputURL)
print("Wrote \(outputURL.path)")
