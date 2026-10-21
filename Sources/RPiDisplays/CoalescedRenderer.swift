import Foundation

/// An actor that executes slow display renders off the calling thread,
/// automatically coalescing rapid updates so the newest state is drawn
/// as soon as the display finishes its active refresh cycle.
public actor CoalescedRenderer<State: Sendable> {
    private let renderAction: @Sendable (State) async throws -> Void
    private var isRendering = false
    private var latestState: State?
    private var renderedState: State?
    private var isStateEqual: (@Sendable (State, State) -> Bool)?

    public init(
        render: @escaping @Sendable (State) async throws -> Void,
        isEqual: (@Sendable (State, State) -> Bool)? = nil
    ) {
        self.renderAction = render
        self.isStateEqual = isEqual
    }

    public func submit(_ state: State) {
        self.latestState = state
        scheduleRenderIfNeeded()
    }

    private func scheduleRenderIfNeeded() {
        guard !isRendering, let stateToRender = latestState else { return }

        if let rendered = renderedState, let isEqual = isStateEqual, isEqual(rendered, stateToRender) {
            return
        }

        isRendering = true
        renderedState = stateToRender

        Task.detached { [weak self] in
            guard let self = self else { return }
            do {
                try await self.renderAction(stateToRender)
            } catch {
                print("CoalescedRenderer error: \(error)")
            }
            await self.renderDidFinish()
        }
    }

    private func renderDidFinish() {
        isRendering = false
        if let latest = latestState, let rendered = renderedState {
            if let isEqual = isStateEqual {
                if !isEqual(latest, rendered) {
                    scheduleRenderIfNeeded()
                }
            } else {
                scheduleRenderIfNeeded()
            }
        }
    }
}
