//
//  MVGCD.swift
//  MVGCD
//
//  Created by Michael on 24/6/14.
//  Copyright (c) 2014 Michael Vu. All rights reserved.
//

import Foundation

let MVGCDQueueSpecificKey:CString = "MVGCDQueueSpecificKey"

class MVGCD {
    class func execOnce(block: dispatch_block_t!) {
        struct Static {
            static var predicate:dispatch_once_t = 0
        }
        dispatch_once(&Static.predicate, block)
    }
    @required init() {
        
    }
}

class MVGCDQueue {
    let queue: dispatch_queue_t
    
    convenience init() {
        self.init(queue: dispatch_queue_create(MVGCDQueueSpecificKey, DISPATCH_QUEUE_SERIAL))
    }
    init(queue: dispatch_queue_t) {
        self.queue = queue
    }
    class var mainQueue: MVGCDQueue {
        return MVGCDQueue(queue: dispatch_get_main_queue())
    }
    class var defaultQueue: MVGCDQueue {
        return MVGCDQueue(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
    }
    class var highPriorityQueue: MVGCDQueue {
        return MVGCDQueue(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0))
    }
    class var lowPriorityQueue: MVGCDQueue {
        return MVGCDQueue(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0))
    }
    class var backgroundQueue: MVGCDQueue {
        return MVGCDQueue(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))
    }
    class func initSerial() -> MVGCDQueue {
        return MVGCDQueue(queue: dispatch_queue_create(MVGCDQueueSpecificKey, DISPATCH_QUEUE_SERIAL))
    }
    class func initConcurrent() -> MVGCDQueue {
        return MVGCDQueue(queue: dispatch_queue_create(MVGCDQueueSpecificKey, DISPATCH_QUEUE_CONCURRENT))
    }
    func sync(block: dispatch_block_t) {
        dispatch_sync(self.queue, block)
    }
    func async(block: dispatch_block_t) {
        dispatch_async(self.queue, block)
    }
    func after(block: dispatch_block_t, afterDelay seconds: Double) {
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
        dispatch_after(time, self.queue, block)
    }
    func afterDate(block: dispatch_block_t, afterDelay date: NSDate) {
        after(block, afterDelay: date.timeIntervalSinceNow)
    }
    func apply(block: ((UInt) -> Void), iterationCount count: UInt) {
        dispatch_apply(count, self.queue, block)
    }
    func barrierAsync(block: dispatch_block_t) {
        dispatch_barrier_async(self.queue, block)
    }
    func barrierSync(block: dispatch_block_t) {
        dispatch_barrier_sync(self.queue, block)
    }
    func suspend() {
        dispatch_suspend(self.queue)
    }
    func resume() {
        dispatch_resume(self.queue)
    }
    func lable() -> CString {
        return dispatch_queue_get_label(self.queue)
    }
    func setTarget(object:dispatch_object_t) {
        dispatch_set_target_queue(object, self.queue)
    }
    func runMain() {
        dispatch_main()
    }
}

class MVGCDGroup {
    let group: dispatch_group_t
    
    convenience init() {
        self.init(group: dispatch_group_create())
    }
    
    init(group: dispatch_group_t) {
        self.group = group
    }
    func async(block: dispatch_block_t, withQueue queue: MVGCDQueue) {
        dispatch_group_async(self.group, queue.queue, block)
    }
    func enter() {
        return dispatch_group_enter(self.group)
    }
    func leave() {
        return dispatch_group_leave(self.group)
    }
    func notify(block: dispatch_block_t, withQueue queue: MVGCDQueue) {
        dispatch_group_notify(self.group, queue.queue, block)
    }
    func wait() {
        dispatch_group_wait(self.group, DISPATCH_TIME_FOREVER)
    }
    func wait(seconds: Double) -> Bool {
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
        return dispatch_group_wait(self.group, time) == 0
    }
    func waitDate(date: NSDate) -> Bool {
        return wait(date.timeIntervalSinceNow)
    }
}

class MVGCDSemaphore {
    let semaphore: dispatch_semaphore_t
    
    convenience init() {
        self.init(value: 0)
    }
    convenience init(value: CLong) {
        self.init(semaphore: dispatch_semaphore_create(value))
    }
    init(semaphore: dispatch_semaphore_t) {
        self.semaphore = semaphore
    }
    func signal() -> Bool {
        return dispatch_semaphore_signal(self.semaphore) != 0
    }
    func wait() {
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER)
    }
    func wait(seconds: Double) -> Bool {
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
        return dispatch_semaphore_wait(self.semaphore, time) == 0
    }
    func waitDate(date: NSDate) -> Bool {
        return wait(date.timeIntervalSinceNow)
    }
}

class MVGCDSource {
    let source: dispatch_source_t

    convenience init(type: dispatch_source_type_t, handle: UInt, mask: CUnsignedLong, queue: dispatch_queue_t?) {
        self.init(source: dispatch_source_create(type, handle, mask, queue!))
    }
    init(source: dispatch_source_t) {
        self.source = source
    }
    func resume() {
        dispatch_resume(self.source)
    }
    func cancel() {
        dispatch_source_cancel(self.source);
    }
    func isCancelled() -> Bool {
        return (dispatch_source_testcancel(self.source) != 0)
    }
    func setRegistrationHandler(block: dispatch_block_t) {
        dispatch_source_set_registration_handler(self.source, block)
    }
    func setCancelHandler(block: dispatch_block_t) {
        dispatch_source_set_cancel_handler(self.source, block)
    }
    func setEventHandler(block: dispatch_block_t) {
        dispatch_source_set_event_handler(self.source, block)
    }
    func handle() -> UInt {
        return dispatch_source_get_handle(self.source)
    }
    func mask() -> CUnsignedLong {
        return dispatch_source_get_mask(self.source)
    }
    func data() -> CUnsignedLong {
        return dispatch_source_get_data(self.source)
    }
    func mergeData(value:CUnsignedLong) {
        dispatch_source_merge_data(self.source, value)
    }
    func setTimer(seconds: Double, interval:UInt64, leeway:UInt64) {
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
        dispatch_source_set_timer(self.source, time, interval / NSEC_PER_SEC, leeway / NSEC_PER_SEC);
    }
    func setTimer(date: NSDate, interval:UInt64, leeway:UInt64) {
        setTimer(date.timeIntervalSinceNow, interval: interval, leeway: leeway)
    }
}