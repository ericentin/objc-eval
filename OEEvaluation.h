//
//  OEEvaluation.h
//  objc-eval
//
//  Created by Eric Entin on 2/21/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEEvaluation, OEEvaluator;

@protocol OEEvaluationDelegate

// Called when the OEEvaluator finishes evaluating, returning absolutely
// anything from the objective-c code represented by code.
// Could be a long time before you recieve this.
- (void)evaluation:(OEEvaluation*)evaluator
        evaluatedWithResult:(id)absolutelyAnything;

@end

@interface OEEvaluation : NSObject {
    NSString *_code;
    id<OEEvaluationDelegate> _delegate;
    OEEvaluator *_evaluator;
}

// Create a new, autoreleased, evaluation with a code string.
+ (OEEvaluation*)evaluationWithCode:(NSString*)code delegate:(id<OEEvaluationDelegate>)delegate;

// Evaluate with delegate callback. This could do anything. You are warned.
- (void)startEvaluation;

// Evaluate synchronously. Will block until result is delivered. This could do anything. You are warned.
- (id)evaluateSynchronously;

@end