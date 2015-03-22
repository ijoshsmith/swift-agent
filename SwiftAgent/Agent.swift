//
//  Agent.swift
//  SwiftAgent
//
//  Created by Joshua Smith on 3/19/15.
//  Copyright (c) 2015 iJoshSmith. All rights reserved.
//

import Foundation

/**
 * Provides thread-safe serialized access to mutable state.
 * All closures passed to an Agent execute on a background thread.
 * It is the caller's responsibility to ensure those closures are thread-safe.
 */
class Agent<TValue>
{
    /** Initializes a new Agent whose initial value is provided by a closure. */
    init(provideInitialValue: () -> TValue)
    {
        let label = NSUUID().UUIDString
        let queue = dispatch_queue_create(label, DISPATCH_QUEUE_SERIAL)
        var value: TValue?
        dispatch_sync(queue) { value = provideInitialValue() }
        self.value = value!
        self.queue = queue
    }
    
    /** Returns the agent's value. */
    func get() -> TValue
    {
        return get { $0 }
    }
    
    /** Passes the agent's value to a closure and returns the transformed value. */
    func get<TResult>(transformValue: (TValue) -> TResult) -> TResult
    {
        var result: TResult?
        dispatch_sync(queue) { result = transformValue(self.value) }
        return result!
    }
    
    /** Passes the agent's value, which should be a mutable object, to a closure. */
    func mutate(mutateValue: (TValue) -> Void)
    {
        dispatch_async(queue) { mutateValue(self.value) }
    }
    
    /** Passes the agent's value to a closure and stores the updated value. */
    func update(updateValue: (TValue) -> TValue)
    {
        dispatch_async(queue) { self.value = updateValue(self.value) }
    }
    
    /** Passes the agent's value to a closure. Stores and returns the updated value. */
    func updateAndGet(updateValue: (TValue) -> TValue) -> TValue
    {
        var result: TValue?
        dispatch_sync(queue) {
            result = updateValue(self.value)
            self.value = result!
        }
        return result!
    }
    
    private let queue: dispatch_queue_t
    private var value: TValue
}
