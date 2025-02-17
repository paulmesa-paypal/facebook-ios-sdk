// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import FBAEMKit
import XCTest

#if !os(tvOS)

class FBAEMRuleTests: XCTestCase { // swiftlint:disable:this type_body_length

  enum Keys {
      static let conversionValue = "conversion_value"
      static let priority = "priority"
      static let events = "events"
      static let eventName = "event_name"
      static let values = "values"
      static let currency = "currency"
      static let amount = "amount"
  }

  enum Values {
      static let purchase = "fb_mobile_purchase"
      static let donate = "Donate"
      static let activateApp = "fb_activate_app"
      static let testEvent = "fb_test_event"
      static let USD = "USD"
      static let EU = "EU" // swiftlint:disable:this identifier_name
      static let JPY = "JPY"
  }

  var sampleData: [String: Any] = [
    Keys.conversionValue: 2,
    Keys.priority: 7,
    Keys.events: [
      [
        Keys.eventName: Values.purchase,
        Keys.values: [
          [
            Keys.currency: Values.USD,
            Keys.amount: 100,
          ],
        ],
      ],
    ],
  ]

  var validRule: FBAEMRule? = FBAEMRule(json: [
    Keys.conversionValue: 10,
    Keys.priority: 7,
    Keys.events: [
      [
        Keys.eventName: Values.purchase,
        Keys.values: [
          [
            Keys.currency: Values.USD,
            Keys.amount: 100,
          ],
        ],
      ],
    ],
  ])

  func testValidCase1() {
    let validData: [String: Any] = [
      Keys.conversionValue: 2,
      Keys.priority: 10,
      Keys.events: [
        [
          Keys.eventName: Values.purchase,
        ],
        [
          Keys.eventName: Values.donate,
        ],
      ],
    ]

    guard let rule = FBAEMRule(json: validData) else { return XCTFail("Unwraping Error") }
    XCTAssertEqual(2, rule.conversionValue)
    XCTAssertEqual(10, rule.priority)
    XCTAssertEqual(2, rule.events.count)

    let event1 = rule.events[0]
    XCTAssertEqual(event1.eventName, Values.purchase)
    XCTAssertNil(event1.values)

    let event2 = rule.events[1]
    XCTAssertEqual(event2.eventName, Values.donate)
    XCTAssertNil(event2.values)
  }

  func testValidCase2() {
    guard let rule = FBAEMRule(json: self.sampleData) else { return XCTFail("Unwraping Error") }
    XCTAssertEqual(2, rule.conversionValue)
    XCTAssertEqual(7, rule.priority)
    XCTAssertEqual(1, rule.events.count)

    let event = rule.events[0]
    XCTAssertEqual(event.eventName, Values.purchase)
    XCTAssertEqual(event.values, [Values.USD: 100])
  }

  func testInvalidCases() {
    var invalidData: [String: Any] = [:]
    XCTAssertNil(FBAEMRule(json: invalidData))

    invalidData = [Keys.conversionValue: 2]
    XCTAssertNil(FBAEMRule(json: invalidData))

    invalidData = [Keys.priority: 7]
    XCTAssertNil(FBAEMRule(json: invalidData))

    invalidData = [
      Keys.events: [
        [
          Keys.eventName: Values.purchase,
          Keys.values: [
            [
              Keys.currency: Values.USD,
              Keys.amount: 100,
            ],
          ],
        ],
      ],
    ]
    XCTAssertNil(FBAEMRule(json: invalidData))

    invalidData = [
      Keys.conversionValue: 2,
      Keys.events: [
        [
          Keys.eventName: Values.purchase,
          Keys.values: [
            [
              Keys.currency: 100,
              Keys.amount: Values.USD,
            ],
          ],
        ],
      ],
    ]
    XCTAssertNil(FBAEMRule(json: invalidData))

    invalidData = [
      Keys.priority: 2,
      Keys.events: [
        [
          Keys.eventName: Values.purchase,
          Keys.values: [
            [
              Keys.currency: Values.USD,
              Keys.amount: 100,
            ],
          ],
        ],
      ],
    ]
    XCTAssertNil(FBAEMRule(json: invalidData))
  }

  func testParsing() {
    (1 ... 100).forEach { _ in
      if let data = (Fuzzer.randomize(json: self.sampleData) as? [String: Any]) {
        _ = FBAEMRule(json: data)
      }
    }
  }

  func testSecureCoding() {
    XCTAssertTrue(
      FBAEMRule.supportsSecureCoding,
      "AEM Rule should support secure coding"
    )
  }

  func testEncoding() {
    let coder = TestCoder()
    let rule = self.validRule
    rule?.encode(with: coder)

    let encodedConversionValue = coder.encodedObject[Keys.conversionValue] as? NSNumber
    XCTAssertEqual(
      encodedConversionValue?.intValue,
      rule?.conversionValue,
      "Should encode the expected conversion_value with the correct key"
    )
    let encodedPriority = coder.encodedObject[Keys.priority] as? NSNumber
    XCTAssertEqual(
      encodedPriority?.intValue,
      rule?.priority,
      "Should encode the expected priority with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject[Keys.events] as? [FBAEMEvent],
      rule?.events,
      "Should encode the expected events with the correct key"
    )
  }

  func testDecoding() {
    let decoder = TestCoder()
    _ = FBAEMRule(coder: decoder)

    XCTAssertEqual(
      decoder.decodedObject[Keys.conversionValue] as? String,
      "decodeIntegerForKey",
      "Should decode the expected type for the conversion_value key"
    )
    XCTAssertEqual(
      decoder.decodedObject[Keys.priority] as? String,
      "decodeIntegerForKey",
      "Should decode the expected type for the priority key"
    )
    XCTAssertEqual(
      decoder.decodedObject[Keys.events] as? NSSet,
      [NSArray.self, FBAEMEvent.self],
      "Should decode the expected type for the events key"
    )
  }

  func testRuleMatch() {
    guard let rule = FBAEMRule(json: [
      Keys.conversionValue: 10,
      Keys.priority: 7,
      Keys.events: [
        [
          Keys.eventName: Values.purchase,
          Keys.values: [
            [
              Keys.currency: Values.USD,
              Keys.amount: 100,
            ],
            [
              Keys.currency: Values.EU,
              Keys.amount: 100,
            ],
          ],
        ],
      ],
    ]) else {
      return XCTFail("Fail to initalize AEM rule")
    }
    XCTAssertTrue(
      rule.isMatched(
        withRecordedEvents: [Values.activateApp, Values.purchase],
        recordedValues: [Values.purchase: [Values.USD: 1000]]
      ),
      "Should match the expected events and values for the rule"
    )
    XCTAssertTrue(
      rule.isMatched(
        withRecordedEvents: [Values.activateApp, Values.purchase],
        recordedValues: [Values.purchase: [Values.EU: 1000]]
      ),
      "Should match the expected events and values for the rule"
    )
    XCTAssertFalse(
      rule.isMatched(
        withRecordedEvents: [Values.activateApp],
        recordedValues: [Values.purchase: [Values.USD: 1000]]
      ),
      "Should not match the unexpected events for the rule"
    )
    XCTAssertFalse(
      rule.isMatched(
        withRecordedEvents: [Values.activateApp, Values.purchase],
        recordedValues: [Values.purchase: [Values.JPY: 1000]]
      ),
      "Should not match the unexpected values for the rule"
    )
  }

  func testRuleMatchWithEventBundle() {
    guard let rule = FBAEMRule(json: [
      Keys.conversionValue: 10,
      Keys.priority: 7,
      Keys.events: [
        [
          Keys.eventName: Values.activateApp,
        ],
        [
          Keys.eventName: Values.purchase,
          Keys.values: [
            [
              Keys.currency: Values.USD,
              Keys.amount: 100,
            ],
          ],
        ],
        [
          Keys.eventName: Values.testEvent,
        ],
      ],
    ]) else {
      return XCTFail("Fail to initalize AEM rule")
    }
    XCTAssertTrue(
      rule.isMatched(
        withRecordedEvents: [Values.activateApp, Values.purchase, Values.testEvent],
        recordedValues: [Values.purchase: [Values.USD: 1000]]
      ),
      "Should match the expected events and values for the rule"
    )
    XCTAssertFalse(
      rule.isMatched(
        withRecordedEvents: [Values.activateApp, Values.purchase, Values.testEvent],
        recordedValues: nil
      ),
      "Should not match the unexpected values for the rule"
    )
    XCTAssertFalse(
      rule.isMatched(
        withRecordedEvents: [Values.activateApp, Values.purchase],
        recordedValues: [Values.purchase: [Values.USD: 1000]]
      ),
      "Should not match the unexpected events for the rule"
    )
    XCTAssertFalse(
      rule.isMatched(
        withRecordedEvents: [Values.activateApp, Values.purchase, Values.testEvent],
        recordedValues: [Values.purchase: [Values.JPY: 1000]]
      ),
      "Should not match the unexpected values for the rule"
    )
  }

  func testRuleMatchWithoutValue() {
    guard let rule = FBAEMRule(json: [
      Keys.conversionValue: 10,
      Keys.priority: 7,
      Keys.events: [
        [
          Keys.eventName: Values.activateApp,
        ],
        [
          Keys.eventName: Values.purchase,
          Keys.values: [
            [
              Keys.currency: Values.USD,
              Keys.amount: 0,
            ],
          ],
        ],
        [
          Keys.eventName: Values.testEvent,
        ],
      ],
    ]) else {
      return XCTFail("Fail to initalize AEM rule")
    }
    XCTAssertTrue(
      rule.isMatched(
        withRecordedEvents: [Values.activateApp, Values.purchase, Values.testEvent],
        recordedValues: nil
      ),
      "Should match the expected events and values for the rule"
    )
    XCTAssertTrue(
      rule.isMatched(
        withRecordedEvents: [Values.activateApp, Values.purchase, Values.testEvent],
        recordedValues: [Values.purchase: [Values.JPY: 1000]]
      ),
      "Should match the expected events and values for the rule"
    )
  }
}

#endif
