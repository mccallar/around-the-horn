#if !os(WASI)
import Foundation

// On the Mac: one JSON request per line on stdin, one reply per line on stdout. The Node
// parity test (Tools/web-tests/parity.mjs) sends the same requests here and to the
// WebAssembly build and checks that the replies agree.
let bridge = Bridge()
while let line = readLine(strippingNewline: true) {
    if line.isEmpty { continue }
    print(bridge.handle(line))
    // A pipe is block-buffered: without this the test would wait for a reply forever.
    fflush(stdout)
}
#endif
