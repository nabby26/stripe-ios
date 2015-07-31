//
//  STPCardValidatorTest.m
//  Stripe
//
//  Created by Jack Flintermann on 7/24/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

@import UIKit;
@import XCTest;

#import "STPCardValidator.h"

@interface STPCardValidatorTest : XCTestCase
@end

@implementation STPCardValidatorTest

+ (NSArray *)cardData {
    return @[
             @[@(STPCardBrandVisa), @"4242424242424242", @(STPCardValidationStateValid)],
             @[@(STPCardBrandVisa), @"4012888888881881", @(STPCardValidationStateValid)],
             @[@(STPCardBrandVisa), @"4000056655665556", @(STPCardValidationStateValid)],
             @[@(STPCardBrandMasterCard), @"5555555555554444", @(STPCardValidationStateValid)],
             @[@(STPCardBrandMasterCard), @"5200828282828210", @(STPCardValidationStateValid)],
             @[@(STPCardBrandMasterCard), @"5105105105105100", @(STPCardValidationStateValid)],
             @[@(STPCardBrandAmex), @"378282246310005", @(STPCardValidationStateValid)],
             @[@(STPCardBrandAmex), @"371449635398431", @(STPCardValidationStateValid)],
             @[@(STPCardBrandDiscover), @"6011111111111117", @(STPCardValidationStateValid)],
             @[@(STPCardBrandDiscover), @"6011000990139424", @(STPCardValidationStateValid)],
             @[@(STPCardBrandDinersClub), @"30569309025904", @(STPCardValidationStateValid)],
             @[@(STPCardBrandDinersClub), @"38520000023237", @(STPCardValidationStateValid)],
             @[@(STPCardBrandJCB), @"3530111333300000", @(STPCardValidationStateValid)],
             @[@(STPCardBrandJCB), @"3566002020360505", @(STPCardValidationStateValid)],
             @[@(STPCardBrandUnknown), @"1234567812345678", @(STPCardValidationStateInvalid)],
             ];
}

- (void)testNumberSanitization {
    NSArray *tests = @[
                       @[@"4242424242424242", @"4242424242424242"],
                       @[@"XXXXXX", @""],
                       @[@"424242424242424X", @"424242424242424"],
                       ];
    for (NSArray *test in tests) {
        XCTAssertEqualObjects([STPCardValidator sanitizedNumericStringForString:test[0]], test[1]);
    }
}

- (void)testNumberValidation {
    NSMutableArray *tests = [@[] mutableCopy];
    
    for (NSArray *card in [self.class cardData]) {
        [tests addObject:@[card[2], card[1]]];
    }
    
    NSArray *badCardNumbers = @[
                                @"1",
                                @"1234123412341234",
                                @"xxx",
                                @"9999999999999999999999",
                                @"42424242424242424242",
                                ];
    
    for (NSString *card in badCardNumbers) {
        [tests addObject:@[@(STPCardValidationStateInvalid), card]];
    }
    
    NSArray *possibleCardNumbers = @[
                                     @"4242",
                                     @"5",
                                     @"3",
                                     @"",
                                     @"6011",
                                     ];
    
    for (NSString *card in possibleCardNumbers) {
        [tests addObject:@[@(STPCardValidationStatePossible), card]];
    }
    
    for (NSArray *test in tests) {
        NSString *card = test[1];
        NSNumber *validationState = @([STPCardValidator validationStateForNumber:card]);
        NSNumber *expected = test[0];
        if (![validationState isEqual:expected]) {
            XCTFail();
        }
    }
}

- (void)testBrand {
    for (NSArray *test in [self.class cardData]) {
        XCTAssertEqualObjects(@([STPCardValidator brandForNumber:test[1]]), test[0]);
    }
}

- (void)testBrandNumberLength {
    NSArray *tests = @[
                       @[@(STPCardBrandVisa), @16],
                       @[@(STPCardBrandMasterCard), @16],
                       @[@(STPCardBrandAmex), @15],
                       @[@(STPCardBrandDiscover), @16],
                       @[@(STPCardBrandDinersClub), @14],
                       @[@(STPCardBrandJCB), @16],
                       @[@(STPCardBrandUnknown), @16],
                       ];
    for (NSArray *test in tests) {
        XCTAssertEqualObjects(@([STPCardValidator lengthForCardBrand:[test[0] integerValue]]), test[1]);
    }
}

- (void)testFragmentLength {
    NSArray *tests = @[
                       @[@(STPCardBrandVisa), @4],
                       @[@(STPCardBrandMasterCard), @4],
                       @[@(STPCardBrandAmex), @5],
                       @[@(STPCardBrandDiscover), @4],
                       @[@(STPCardBrandDinersClub), @2],
                       @[@(STPCardBrandJCB), @4],
                       @[@(STPCardBrandUnknown), @4],
                       ];
    for (NSArray *test in tests) {
        XCTAssertEqualObjects(@([STPCardValidator fragmentLengthForCardBrand:[test[0] integerValue]]), test[1]);
    }
}

- (void)testMonthValidation {
    NSArray *tests = @[
                       @[@"", @(STPCardValidationStatePossible)],
                       @[@"0", @(STPCardValidationStatePossible)],
                       @[@"1", @(STPCardValidationStatePossible)],
                       @[@"2", @(STPCardValidationStateValid)],
                       @[@"9", @(STPCardValidationStateValid)],
                       @[@"10", @(STPCardValidationStateValid)],
                       @[@"12", @(STPCardValidationStateValid)],
                       @[@"13", @(STPCardValidationStateInvalid)],
                       @[@"x", @(STPCardValidationStateInvalid)],
                       @[@"100", @(STPCardValidationStateInvalid)],
                       @[@"00", @(STPCardValidationStateInvalid)],
                       @[@"13", @(STPCardValidationStateInvalid)],
                       ];
    for (NSArray *test in tests) {
        XCTAssertEqualObjects(@([STPCardValidator validationStateForExpirationMonth:test[0]]), test[1]);
    }
}

- (void)testYearValidation {
    NSArray *tests = @[
                       @[@"12", @"15", @(STPCardValidationStateValid)],
                       @[@"8", @"15", @(STPCardValidationStateValid)],
                       @[@"9", @"15", @(STPCardValidationStateValid)],
                       @[@"11", @"16", @(STPCardValidationStateValid)],
                       @[@"11", @"99", @(STPCardValidationStateValid)],
                       @[@"00", @"99", @(STPCardValidationStateValid)],
                       @[@"12", @"14", @(STPCardValidationStateInvalid)],
                       @[@"7", @"15", @(STPCardValidationStateInvalid)],
                       @[@"12", @"00", @(STPCardValidationStateInvalid)],
                       @[@"12", @"2", @(STPCardValidationStatePossible)],
                       @[@"12", @"1", @(STPCardValidationStatePossible)],
                       @[@"12", @"0", @(STPCardValidationStatePossible)],
                       ];
    
    for (NSArray *test in tests) {
        STPCardValidationState state = [STPCardValidator validationStateForExpirationYear:test[1] inMonth:test[0] inCurrentYear:15 currentMonth:8];
        XCTAssertEqualObjects(@(state), test[2]);
    }
}

- (void)testCVCLength {
    NSArray *tests = @[
                       @[@(STPCardBrandVisa), @3],
                       @[@(STPCardBrandMasterCard), @3],
                       @[@(STPCardBrandAmex), @4],
                       @[@(STPCardBrandDiscover), @3],
                       @[@(STPCardBrandDinersClub), @3],
                       @[@(STPCardBrandJCB), @3],
                       @[@(STPCardBrandUnknown), @4],
                       ];
    for (NSArray *test in tests) {
        XCTAssertEqualObjects(@([STPCardValidator maxCvcLengthForCardBrand:[test[0] integerValue]]), test[1]);
    }
}

- (void)testCVCValidation {
    NSArray *tests = @[
                       @[@"x", @(STPCardBrandVisa), @(STPCardValidationStateInvalid)],
                       @[@"", @(STPCardBrandVisa), @(STPCardValidationStatePossible)],
                       @[@"1", @(STPCardBrandVisa), @(STPCardValidationStatePossible)],
                       @[@"12", @(STPCardBrandVisa), @(STPCardValidationStatePossible)],
                       @[@"123", @(STPCardBrandVisa), @(STPCardValidationStateValid)],
                       @[@"123", @(STPCardBrandAmex), @(STPCardValidationStatePossible)],
                       @[@"123", @(STPCardBrandUnknown), @(STPCardValidationStatePossible)],
                       @[@"1234", @(STPCardBrandVisa), @(STPCardValidationStateInvalid)],
                       @[@"1234", @(STPCardBrandAmex), @(STPCardValidationStateValid)],
                       @[@"12345", @(STPCardBrandAmex), @(STPCardValidationStateInvalid)],
                       ];
    
    for (NSArray *test in tests) {
        STPCardValidationState state = [STPCardValidator validationStateForCVC:test[0] cardBrand:[test[1] integerValue]];
        XCTAssertEqualObjects(@(state), test[2]);
    }
}


@end