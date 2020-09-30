//
//  Socket+File.swift
//  Swifter
//
//  Created by Damian Kolakowski on 13/07/16.
//

import Foundation

#if os(iOS) || os(tvOS) || os (Linux)
    struct sf_hdtr { }
    
    private func sendfileImpl(_ source: UnsafeMutablePointer<FILE>, _ target: Int32, _: off_t, _: UnsafeMutablePointer<off_t>, _: UnsafeMutablePointer<sf_hdtr>, _: Int32) -> Int32 {
        let BUFFER_SIZE = 1024
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: BUFFER_SIZE, alignment: 1)
        while true {
            let readResult = fread(buffer, 1, BUFFER_SIZE, source)
            guard readResult > 0 else {
                buffer.deallocate()
                return Int32(readResult)
            }
            var writeCounter = 0
            while writeCounter < readResult {
                let writeResult = write(target, buffer + writeCounter, readResult - writeCounter)
                guard writeResult > 0 else {
                    buffer.deallocate()
                    return Int32(writeResult)
                }
                writeCounter = writeCounter + writeResult
            }
        }
    }
#endif

extension Socket {
    
    public func writeFile(_ file: String.File) throws -> Void {
        var offset: off_t = 0
        var sf: sf_hdtr = sf_hdtr()
        
        #if os(iOS) || os(tvOS) || os (Linux)
        let result = sendfileImpl(file.pointer, self.socketFileDescriptor, 0, &offset, &sf, 0)
        #else
        let result = sendfile(fileno(file.pointer), self.socketFileDescriptor, 0, &offset, &sf, 0)
        #endif
        
        if result == -1 {
            throw SocketError.writeFailed("sendfile: " + Errno.description())
        }
    }
    
}
