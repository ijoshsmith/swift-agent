# Swift Agent
Swift implementation of an Agent which enables thread-safe mutable state. 

## What is an agent?
An agent provides serialized (i.e. one-at-a-time) access to mutable state shared between threads. Forcing all state access to occur serially ensures one thread is not reading the data while another thread is changing it.
This is a port of the Agent concept used in Elixir programming, as well as other platforms.

## How to use Agent
Copy the [Agent](SwiftAgent/Agent.swift) class into your project to use it in an app.

To get you started, here's a quick example from the [unit tests](SwiftAgentTests/AgentTests.swift) showing how to create an Agent with an initial value and then `update` that value in a thread-safe manner:
```swift
func test_update_increment100_valueIs101()
{
    let agent = Agent { 100 }
    agent.update { $0 + 1 }
    XCTAssertEqual(agent.get(), 101, "")
}
```
If the Agent manages a mutable data structure, use `mutate` to modify it.
```swift
func test_mutate_addDictionaryEntry_entryIsAdded()
{
    let agent = Agent { NSMutableDictionary(dictionary: ["A": 1]) }
    agent.mutate { $0["B"] = 2 }
    XCTAssertEqual(agent.get()["A"] as Int, 1, "")
    XCTAssertEqual(agent.get()["B"] as Int, 2, "")
}
```
