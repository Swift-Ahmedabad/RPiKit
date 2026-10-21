import Testing
import Foundation
@testable import RPiHAL
@testable import RPiPeripherals

@Suite("Peripheral Tests")
struct ButtonTests {

    @Test("DebouncedButton yields pressed and released events")
    func testDebouncedButtonEvents() async throws {
        let pin = MockGPIOPin(pinNumber: 27, initialState: .high) // Active low pull-up
        let button = DebouncedButton(
            pin: pin,
            activeLow: true,
            debounceInterval: 0.01,
            pollInterval: 0.005
        )

        let events = button.events()
        var iterator = events.makeAsyncIterator()

        // Simulate press (low)
        pin.simulateInput(.low)

        // Await event with timeout
        let pressedEvent = await iterator.next()
        #expect(pressedEvent == .pressed)

        // Simulate release (high)
        pin.simulateInput(.high)
        let releasedEvent = await iterator.next()
        #expect(releasedEvent == .released)
    }
}
