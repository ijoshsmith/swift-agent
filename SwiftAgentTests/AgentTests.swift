//
//  AgentTests.swift
//  SwiftAgentTests
//
//  Created by Joshua Smith on 3/19/15.
//  Copyright (c) 2015 iJoshSmith. All rights reserved.
//

import XCTest

class SwiftAgentTests: XCTestCase
{
    // MARK: - get
    
    func test_get_valueIsHello_returnsHello()
    {
        let agent = Agent { "Hello" }
        XCTAssertEqual(agent.get(), "Hello", "")
    }
    
    func test_get_valueIs1Plus1_returns2()
    {
        let agent = Agent { 1 + 1 }
        XCTAssertEqual(agent.get(), 2, "")
    }
    
    func test_get_passValueTransformer_returnsTransformedValue()
    {
        let agent = Agent { 42 }
        let value = agent.get { "agent value is \($0)" }
        XCTAssertEqual(value, "agent value is 42", "")
    }
    
    // MARK: - mutate
    
    func test_mutate_addDictionaryEntry_entryIsAdded()
    {
        let agent = Agent { NSMutableDictionary(dictionary: ["A": 1]) }
        agent.mutate { $0["B"] = 2 }
        XCTAssertEqual(agent.get()["A"] as Int, 1, "")
        XCTAssertEqual(agent.get()["B"] as Int, 2, "")
    }
    
    func test_mutate_addBToSetThenRemoveA_onlyContainsB()
    {
        let agent = Agent { NSMutableSet(object: "A") }
        agent.mutate { $0.addObject("B") }
        agent.mutate { $0.removeObject("A") }
        XCTAssertEqual(agent.get().count, 1, "")
        XCTAssertTrue(agent.get().containsObject("B"), "")
    }
    
    // MARK: - update
    
    func test_update_increment100_valueIs101()
    {
        let agent = Agent { 100 }
        agent.update { $0 + 1 }
        XCTAssertEqual(agent.get(), 101, "")
    }
    
    // MARK: - updateAndGet
    
    func test_updateAndGet_increment100_valueIs101()
    {
        let agent = Agent { 100 }
        let value = agent.updateAndGet { $0 + 1 }
        XCTAssertEqual(value, 101, "")
        XCTAssertEqual(agent.get(), 101, "")
    }
    
    func test_updateAndGet_ignoreCurrentValue_valueIsReplaced()
    {
        let agent = Agent { "Happy Happy" }
        let value = agent.updateAndGet { _ in "Joy"}
        XCTAssertEqual(value, "Joy", "")
        XCTAssertEqual(agent.get(), value, "")
    }
    
    // MARK: - concurrency test
    
    func test_update_4ThreadsIncrement250Times_valueIs1000()
    {
        let agent = Agent { 0 }
        
        // Each quality-of-service class represents a separate 
        // dispatch queue running on a different thread.
        [QOS_CLASS_DEFAULT,
         QOS_CLASS_BACKGROUND,
         QOS_CLASS_USER_INITIATED,
         QOS_CLASS_USER_INTERACTIVE]
         .map { qosClass in
            AgentUpdater(
                agent: agent,
                block: { $0 + 1 },
                count: 250,
                delay: 0.001,
                queue: dispatch_get_global_queue(qosClass, 0))
         }
         .each { $0.startUpdating() }
        
        // Pause the current thread while the Agent is updated.
        NSThread.sleepForTimeInterval(2)
        
        XCTAssertEqual(agent.get(), 1000, "")
    }
}

class AgentUpdater<T>
{
    let agent: Agent<T>
    let block: (T) -> T
    let count: Int
    let delay: NSTimeInterval
    let queue: dispatch_queue_t
    
    init(
        agent: Agent<T>,
        block: (T) -> T,
        count: Int,
        delay: NSTimeInterval,
        queue: dispatch_queue_t)
    {
        self.agent = agent
        self.block = block
        self.count = count
        self.delay = delay
        self.queue = queue
    }
    
    func startUpdating()
    {
        dispatch_async(queue) { self.doUpdates() }
    }
    
    private func doUpdates()
    {
        [Int](1...self.count).each { self.doUpdate($0) }
    }
    
    private func doUpdate(updateNumber: Int)
    {
        let duration = delay * NSTimeInterval(updateNumber)
        wait(duration, then: { self.agent.update(self.block) } )
    }
    
    private func wait(duration: NSTimeInterval, then: () -> Void)
    {
        let diff = Int64(duration * NSTimeInterval(NSEC_PER_SEC))
        let time = dispatch_time(DISPATCH_TIME_NOW, diff)
        dispatch_after(time, queue, then)
    }
}

extension Array
{
    func each(closure: (T) -> Void)
    {
        for elem in self { closure(elem) }
    }
    
    func each(closure: () -> Void)
    {
        for elem in self { closure() }
    }
}
