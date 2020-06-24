import XCTest
@testable import SwiftyRedux

class SwiftyReduxTests: XCTestCase {

    struct AppState {
        var counter: Int = 0
    }
    
    lazy var appReducerExpectation: XCTestExpectation = {
        let expect = self.expectation(description: "appReducerExpectation")
        expect.expectedFulfillmentCount = 1
        return expect
    }()
    
    lazy var loggerExpectation: XCTestExpectation = {
        let expect = self.expectation(description: "loggerExpectation")
        expect.expectedFulfillmentCount = 1
        return expect
    }()
    
    lazy var loggerAfterExpectation: XCTestExpectation = {
        let expect = self.expectation(description: "loggerAfterExpectation")
        expect.expectedFulfillmentCount = 1
        return expect
    }()
    
    lazy var logger2Expectation: XCTestExpectation = {
        let expect = self.expectation(description: "logger2Expectation")
        expect.expectedFulfillmentCount = 1
        return expect
    }()

    lazy var logger2AfterExpectation: XCTestExpectation = {
        let expect = self.expectation(description: "logger2AfterExpectation")
        expect.expectedFulfillmentCount = 1
        return expect
    }()
    
    lazy var logger3Expectation: XCTestExpectation = {
        let expect = self.expectation(description: "logger3Expectation")
        expect.expectedFulfillmentCount = 1
        return expect
    }()

    lazy var logger3AfterExpectation: XCTestExpectation = {
        let expect = self.expectation(description: "logger3AfterExpectation")
        expect.expectedFulfillmentCount = 1
        return expect
    }()
    
    struct AppReducer: ReduxReducer {
        let expectation: XCTestExpectation
        func reduce(action: ReduxAction, state: AppState) -> AppState {
            expectation.fulfill()
            return AppState(counter: state.counter + 1)
        }
    }
    
    struct Logging<S>: ReduxMiddleware {
        
        let before: XCTestExpectation
        
        let after: XCTestExpectation
        
        func apply(state: @escaping () -> S, dispatch: @escaping (ReduxAction) -> Void) -> (@escaping (ReduxAction) -> ()) -> (ReduxAction) -> Void {
            return { next in
                return { action in
                    
                    self.before.fulfill()
                    
                    next(action)
                    
                    self.after.fulfill()
                    
                }
            }
        }
    }
    
    struct Logging2<S>: ReduxMiddleware {
        
        let before: XCTestExpectation
        
        let after: XCTestExpectation
        
        func apply(state: @escaping () -> S, dispatch: @escaping (ReduxAction) -> Void) -> (@escaping (ReduxAction) -> ()) -> (ReduxAction) -> Void {
            return { next in
                return { action in
                    
                    self.before.fulfill()
                    
                    next(action)
                    
                    self.after.fulfill()
                    
                }
            }
        }
    }
    
    struct Logging3<S>: ReduxMiddleware {
        
        let before: XCTestExpectation
        
        let after: XCTestExpectation
        
        func apply(state: @escaping () -> S, dispatch: @escaping (ReduxAction) -> Void) -> (@escaping (ReduxAction) -> ()) -> (ReduxAction) -> Void {
            return { next in
                return { action in
                    
                    self.before.fulfill()
                    
                    next(action)
                    
                    self.after.fulfill()
                    
                }
            }
        }
    }
    
    struct TestAction: ReduxAction {}
    
    var subscription: ReduxCancellable!
    
    func testOrder() {
        let store = ReduxStore(
            initialState: AppState(),
            reducer: AppReducer(expectation: self.appReducerExpectation),
            middlewares: [
                AnyReduxMiddleware(Logging<AppState>(before: self.loggerExpectation, after: self.loggerAfterExpectation)),
                AnyReduxMiddleware(Logging2<AppState>(before: self.logger2Expectation, after: self.logger2AfterExpectation)),
                AnyReduxMiddleware(Logging3<AppState>(before: self.logger3Expectation, after: self.logger3AfterExpectation))
            ]
        )
        let subscriberIsCalled = expectation(description: "subscriberIsCalled")
        subscription = store.subscribe { nextState in
            subscriberIsCalled.fulfill()
        }
        
        store.dispatch(action: TestAction())
        wait(
            for: [
                loggerExpectation,
                logger2Expectation,
                logger3Expectation,
                appReducerExpectation,
                subscriberIsCalled,
                logger3AfterExpectation,
                logger2AfterExpectation,
                loggerAfterExpectation,
            ],
            timeout: 5,
            enforceOrder: true
        )
    }
    
    struct EquatableAppState: Equatable {
        var count: Int = 0
    }
    
    struct EquatableAppReducer: ReduxReducer {
        let expectation: XCTestExpectation
        func reduce(action: ReduxAction, state: EquatableAppState) -> EquatableAppState {
            switch action {
            case let action as IncrementBy:
                expectation.fulfill()
                return EquatableAppState(count: state.count + action.amount)
            default:
                return state
            }
        }
    }
    
    struct IncrementBy: ReduxAction {
        let amount: Int
    }
    
    struct EquatableMiddleware<S>: ReduxMiddleware {
        func apply(state: @escaping () -> S, dispatch: @escaping (ReduxAction) -> Void) -> (@escaping (ReduxAction) -> ()) -> (ReduxAction) -> Void {
            return { next in
                return { action in
                    next(action)
                }
            }
        }
    }
    
    var equatableSubscriber: ReduxSubscription<SwiftyReduxTests.EquatableAppState, SwiftyReduxTests.EquatableAppReducer>!
    
    func testMiddlewareOrderEquatable() {
        let appReducerExpect = self.expectation(description: "appReducer")
        appReducerExpect.expectedFulfillmentCount = 2
        let store = ReduxStore(
            initialState: EquatableAppState(),
            reducer: EquatableAppReducer(expectation: appReducerExpect),
            middlewares: [
                AnyReduxMiddleware(EquatableMiddleware<EquatableAppState>()),
                AnyReduxMiddleware(EquatableMiddleware<EquatableAppState>()),
            ]
        )
        let subscriberExpect = self.expectation(description: "subscriber")
        equatableSubscriber = store.subscribe { newState in
            subscriberExpect.fulfill()
            XCTAssertEqual(5, newState.count)
        }
        store.dispatch(action: IncrementBy(amount: 0))
        store.dispatch(action: IncrementBy(amount: 5))
        wait(for: [appReducerExpect, subscriberExpect], timeout: 2)
    }

}
