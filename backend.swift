import CoreGraphics

func getDisplayNameByID(displayID: CGDirectDisplayID) -> String {
    if let dictionary = (CoreDisplay_DisplayCreateInfoDictionary(displayID)?.takeRetainedValue() as NSDictionary?),
       let nameList = dictionary["DisplayProductName"] as? [String: String],
       let name = nameList["en_US"] ?? nameList.first?.value {
        return name
    }
    return "Unknown Display"
}

func isAppleDisplay(displayID: CGDirectDisplayID) -> Bool {
    return CGDisplayVendorNumber(displayID) == 1552
}

func getAVServiceByID(displayID: CGDirectDisplayID) -> IOAVService? {
    let serviceMatches = Arm64ServiceFetcher.getServiceMatches(displayIDs: [displayID])
    assert(serviceMatches.count == 1)
    assert(serviceMatches[0].displayID == displayID)
    assert(serviceMatches[0].service != nil)
    return serviceMatches[0].service
}

var avServices: [CGDirectDisplayID: IOAVService] = [:]
let BRIGHTNESS: UInt8 = 0x10  // VCP code for brightness

func setBrightness(displayID: CGDirectDisplayID, newBrightness: UInt8) {
    let avService = avServices[displayID]
    
    var data: [UInt8] = [
        0x84, // "Set VCP" command
        0x03, // size = 3 bytes
        BRIGHTNESS,
        (newBrightness >> 8) & 0xFF,  // high byte
        (newBrightness & 0xFF),       // low byte
        0x6E ^ 0x51 ^ 0x84 ^ 0x03 ^ BRIGHTNESS ^ ((newBrightness >> 8) & 0xFF) ^ (newBrightness & 0xFF) // checksum
    ]
    
    usleep(50000)
    IOAVServiceWriteI2C(avService, 0x37, 0x51, &data, 6)
}

func getBrightness(displayID: CGDirectDisplayID) -> Double {
    let avService = avServices[displayID]

    var data: [UInt8] = [
        0x82, // "Get VCP" command
        0x01, // size = 1 byte
        BRIGHTNESS, // VCP code for brightness
        0x6E ^ 0x82 ^ 0x01 ^ BRIGHTNESS // checksum
    ]
    var i2cBytes: [UInt8] = [UInt8](repeating: 0, count: 12)

    usleep(50000)
    IOAVServiceWriteI2C(avService, 0x37, 0x51, &data, 4)

    usleep(50000)
    IOAVServiceReadI2C(avService, 0x37, 0x51, &i2cBytes, 12)

    guard i2cBytes.count >= 10 else {
        return 50 // Return default value if the data is insufficient
    }
    let currentValue = i2cBytes[9] // 10th byte (index 9) is the brightness value
    
    return Double(currentValue)
}

func enumerateDisplays() -> [CGDirectDisplayID] {
    var onlineDisplayIDs: [CGDirectDisplayID] = [CGDirectDisplayID](repeating: 0, count: 16)
    var displayCount: UInt32 = 0
    CGGetOnlineDisplayList(16, &onlineDisplayIDs, &displayCount)
    
    var nonAppleDisplayIDs: [CGDirectDisplayID] = []
    avServices = [:]
    for displayID in onlineDisplayIDs where displayID != 0 {
        if !isAppleDisplay(displayID: displayID) {
            print("Display Name: \(getDisplayNameByID(displayID: displayID)) - Serial Number: \(CGDisplaySerialNumber(displayID))")
            if let service = getAVServiceByID(displayID: displayID) {
                avServices[displayID] = service
            }
            nonAppleDisplayIDs.append(displayID)
        }
    }
    return nonAppleDisplayIDs
}
