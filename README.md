google-places
=============

A simple example app that connects to the Google Places API, used to demonstrate different unit testing techniques.

Test Framework comparison
=========================

Here's a few things I observed while implementing the tests in each framework.  These are my opinions and I'd love to hear yours.

## OCUnit

[sente.ch](http://www.sente.ch/software/ocunit/)

### ++

- Familiar xUnit style testing
- No setup required -- Built-in to Xcode
- Less third-party code to rely on

### \-\-

- Same old xUnit style testing
- Mocking and stubbing not included
- Some swizzling may be required to mock class methods
- No built-in support for asynchronous testing
- Not actively developed?  Apple?  Anyone home?

## OCMock

[ocmock.org](http://ocmock.org/)

### ++

- Runs on top of OCUnit
- Mocks and stubs!
- Block support
- New and much improved
  - Class method stubs
	- Nice/Null mocks
	- Partial mocks
	- Built in support for swizzling
	- NSNotification center
- Mulle kybernetik is an awesome name

### \-\-

- Could be simpler to setup
- Easier with CocoaPods, but current release isn't available - though it can be overridden by URL in your podfile
- Failed mock expectations do not highlight in Xcode
- Unnatural syntax 
- Weird macros
- Don't forget to verify!  Not as much of a problem with TDD

## Kiwi

[github.com/allending/kiwi](https://github.com/allending/Kiwi)

### ++

- Cool spec-style testing
- Mocks, stubs, and tons of matchers built in
- Nested contexts DRYs up specs
- Mock, no verify
- beforeAll/afterAll
- Choice of message patterns or selectors
- Asynchronous testing
- Latest version 2.0.6 is on Cocoapods

### \-\-

- Crazy spec-style testing
- Can be a headache to setup
- Failed mock expectations do not highlight in Xcode
