import CoreAudio
import Foundation

struct InputDevice: Encodable {
    let id: String
    let name: String
    let modelUID: String?
}

func propertyAddress(
    _ selector: AudioObjectPropertySelector,
    scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal
) -> AudioObjectPropertyAddress {
    AudioObjectPropertyAddress(
        mSelector: selector,
        mScope: scope,
        mElement: kAudioObjectPropertyElementMain
    )
}

func stringProperty(_ device: AudioDeviceID, _ selector: AudioObjectPropertySelector) -> String? {
    var address = propertyAddress(selector)
    var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    var value: Unmanaged<CFString>?
    let status = withUnsafeMutablePointer(to: &value) { pointer in
        AudioObjectGetPropertyData(device, &address, 0, nil, &size, pointer)
    }
    guard status == noErr, let value else {
        return nil
    }
    // CoreAudio transfers ownership of CFString properties to the caller.
    return value.takeRetainedValue() as String
}

func hasInputChannels(_ device: AudioDeviceID) -> Bool {
    var address = propertyAddress(
        kAudioDevicePropertyStreamConfiguration,
        scope: kAudioDevicePropertyScopeInput
    )
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(device, &address, 0, nil, &size) == noErr,
          size >= MemoryLayout<UInt32>.size else {
        return false
    }
    let storage = UnsafeMutableRawPointer.allocate(
        byteCount: Int(size),
        alignment: MemoryLayout<AudioBufferList>.alignment
    )
    defer { storage.deallocate() }
    let buffers = storage.assumingMemoryBound(to: AudioBufferList.self)
    guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, buffers) == noErr else {
        return false
    }
    return UnsafeMutableAudioBufferListPointer(buffers).contains { $0.mNumberChannels > 0 }
}

func inputDevices() throws -> [InputDevice] {
    let system = AudioObjectID(kAudioObjectSystemObject)
    var address = propertyAddress(kAudioHardwarePropertyDevices)
    var size: UInt32 = 0
    var status = AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size)
    guard status == noErr else {
        throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }
    guard size > 0 else { return [] }
    var devices = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
    status = devices.withUnsafeMutableBytes { buffer in
        AudioObjectGetPropertyData(system, &address, 0, nil, &size, buffer.baseAddress!)
    }
    guard status == noErr else {
        throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }
    return devices.filter(hasInputChannels).compactMap { device in
        guard let id = stringProperty(device, kAudioDevicePropertyDeviceUID),
              let name = stringProperty(device, kAudioObjectPropertyName) else {
            return nil
        }
        return InputDevice(
            id: id,
            name: name,
            modelUID: stringProperty(device, kAudioDevicePropertyModelUID)
        )
    }.sorted { ($0.name, $0.id) < ($1.name, $1.id) }
}

do {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    FileHandle.standardOutput.write(try encoder.encode(inputDevices()))
    FileHandle.standardOutput.write(Data("\n".utf8))
} catch {
    FileHandle.standardError.write(Data("Cannot enumerate audio inputs: \(error)\n".utf8))
    exit(1)
}
