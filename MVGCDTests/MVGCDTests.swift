//
//  MVGCDTests.swift
//  MVGCDTests
//
//  Created by Michael on 24/6/14.
//  Copyright (c) 2014 Michael Vu. All rights reserved.
//

import XCTest
import MVGCD

class MVGCDTests: XCTestCase {
    
    func testExecOnce() {
        var val = 0
        for (var i = 1; i <= 10; ++i) {
            MVGCD.execOnce({val = i})
        }
        XCTAssertEqual(val, 1)
    }
    
    func testMainQueue() {
        XCTAssertEqual(MVGCDQueue.mainQueue.queue, dispatch_get_main_queue())
    }
    
    func testQueues() {
        XCTAssertEqual(MVGCDQueue.defaultQueue.queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
        XCTAssertEqual(MVGCDQueue.highPriorityQueue.queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0))
        XCTAssertEqual(MVGCDQueue.lowPriorityQueue.queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0))
        XCTAssertEqual(MVGCDQueue.backgroundQueue.queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))
    }
    
    func testQueueAsync() {
        let semaphore = MVGCDSemaphore()
        let queue = MVGCDQueue()
        var val = 0
        
        queue.async({
            val += 1
            semaphore.signal()
            })
        
        semaphore.wait()
        XCTAssertEqual(val, 1)
    }
    
    func testQueueAfterDelay() {
        let semaphore = MVGCDSemaphore()
        let queue = MVGCDQueue()
        let then = NSDate()
        var val = 0
        
        queue.after({
            val += 1
            semaphore.signal()
            }, afterDelay: 0.5)
        
        XCTAssertEqual(val, 0)
        semaphore.wait()
        XCTAssertEqual(val, 1)
        
        let now = NSDate()
        XCTAssertTrue(now.timeIntervalSinceDate(then) > 0.4)
        XCTAssertTrue(now.timeIntervalSinceDate(then) < 0.6)
    }
    
    func testQueueSync() {
        let queue = MVGCDQueue()
        var val = 0
        
        queue.sync({
            val += 1
            })
        
        XCTAssertEqual(val, 1)
    }
    
    func testQueueApplyIterationCount() {
        let queue = MVGCDQueue.initConcurrent()
        var val: Int32 = 0
        let pVal: CMutablePointer = &val
        
        queue.apply({ i in OSAtomicIncrement32(UnsafePointer<Int32>(pVal)); return }, iterationCount: 100)
        
        XCTAssertEqual(val, 100)
    }
    
    func testGroupAsyncWithQueue() {
        let queue = MVGCDQueue.initConcurrent()
        let group = MVGCDGroup()
        var val: Int32 = 0
        let pVal: CMutablePointer = &val
        
        for (var i = 0; i < 100; ++i) {
            group.async({ OSAtomicIncrement32(UnsafePointer<Int32>(pVal)); return }, withQueue: queue)
        }
        
        group.wait()
        XCTAssertEqual(val, 100)
    }
    
    func testGroupNotifyBlockWithQueue() {
        let queue = MVGCDQueue.initConcurrent()
        let semaphore = MVGCDSemaphore()
        let group = MVGCDGroup()
        var val: Int32 = 0
        let pVal: CMutablePointer = &val
        var notifyVal: Int32 = 0
        
        for (var i = 0; i < 100; ++i) {
            group.async({ OSAtomicIncrement32(UnsafePointer<Int32>(pVal)); return }, withQueue: queue)
        }
        
        group.notify({
            notifyVal = val
            semaphore.signal()
            }, withQueue: queue);
        
        semaphore.wait()
        XCTAssertEqual(notifyVal, 100)
    }
    
    func testQueueBarrierAsync() {
        let queue = MVGCDQueue.initConcurrent()
        let semaphore = MVGCDSemaphore()
        var val: Int32 = 0
        let pVal: CMutablePointer = &val
        var barrierVal: Int32 = 0
        
        for (var i = 0; i < 100; ++i) {
            queue.async({ OSAtomicIncrement32(UnsafePointer<Int32>(pVal)); return })
        }
        queue.barrierAsync({
            barrierVal = val
            semaphore.signal()
            })
        for (var i = 0; i < 100; ++i) {
            queue.async({ OSAtomicIncrement32(UnsafePointer<Int32>(pVal)); return })
        }
        
        semaphore.wait()
        XCTAssertEqual(barrierVal, 100)
    }
    
    func testQueueBarrierSync() {
        let queue = MVGCDQueue.initConcurrent()
        var val: Int32 = 0
        let pVal: CMutablePointer = &val
        
        for (var i = 0; i < 100; ++i) {
            queue.async({ OSAtomicIncrement32(UnsafePointer<Int32>(pVal)); return })
        }
        queue.barrierSync({})
        XCTAssertEqual(val, 100)
    }
    
}
