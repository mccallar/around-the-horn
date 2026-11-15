#if os(WASI)
// The module's exports, as the browser sees them (web/engine.js). JavaScript writes a
// UTF-8 request into memory it got from `horn_alloc`, calls `horn_call`, reads
// `horn_reply_len()` bytes at the pointer it returns, then frees its own buffer. The reply
// stays in Swift's keeping until the next call.

let bridge = Bridge()
var reply: UnsafeMutableRawPointer?
var replyLen = 0

@_expose(wasm, "horn_alloc")
@_cdecl("horn_alloc")
func hornAlloc(_ size: Int32) -> UnsafeMutableRawPointer? {
    UnsafeMutableRawPointer.allocate(byteCount: Int(max(size, 1)), alignment: 16)
}

@_expose(wasm, "horn_free")
@_cdecl("horn_free")
func hornFree(_ p: UnsafeMutableRawPointer?) {
    p?.deallocate()
}

@_expose(wasm, "horn_call")
@_cdecl("horn_call")
func hornCall(_ p: UnsafeMutableRawPointer?, _ len: Int32) -> UnsafeMutableRawPointer? {
    let request = p.map { String(decoding: UnsafeRawBufferPointer(start: $0, count: Int(len)), as: UTF8.self) } ?? ""
    let bytes = Array(bridge.handle(request).utf8)
    reply?.deallocate()
    let out = UnsafeMutableRawPointer.allocate(byteCount: max(bytes.count, 1), alignment: 16)
    bytes.withUnsafeBytes { out.copyMemory(from: $0.baseAddress!, byteCount: bytes.count) }
    reply = out
    replyLen = bytes.count
    return out
}

@_expose(wasm, "horn_reply_len")
@_cdecl("horn_reply_len")
func hornReplyLen() -> Int32 {
    Int32(replyLen)
}
#endif
