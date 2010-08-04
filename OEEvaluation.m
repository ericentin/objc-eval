//
//  OEEvaluation.m
//  objc-eval
//
//  Created by Eric Entin on 2/21/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "OEEvaluation.h"
#import "OEEvaluator.h"

@implementation OEEvaluation

- (id)initWithCode:(NSString*)code delegate:(id<OEEvaluationDelegate>)delegate {
    if ((self = [super init])) {
        _code = [code copy];
        _delegate = delegate;
    }
    return self;
}

// Create a new, autoreleased, evaluation with a code string.
+ (OEEvaluation*)evaluationWithCode:(NSString*)code delegate:(id<OEEvaluationDelegate>)delegate {
    OEEvaluation *evaluation = [[[OEEvaluation alloc] initWithCode:code delegate:delegate] autorelease];
    return evaluation;
}

// Compile the code, load it in as a bundle, and return a value.
- (void)compileAndExecute {
    // Open this up, we're gonna need it.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Untar the template bundle to /tmp.
    NSArray *allBundles = [NSBundle allFrameworks];
    NSUInteger OEBundleIndex = [allBundles indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
        NSBundle *bundle = obj;
        NSRange range = [[bundle bundlePath] rangeOfString:@"objc-eval"];
        if (range.location == NSNotFound) {
            return NO;
        } else {
            return YES;
        }
    }];
    NSString *tarPath = [[[allBundles objectAtIndex:OEBundleIndex] resourcePath] stringByAppendingString:@"/template_bundle.tar"];
    NSString *tmpPath = @"/tmp";
    NSTask *unTarToTmp = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/tar"
                                                  arguments:[NSArray arrayWithObjects:@"-xf", tarPath, @"-C", tmpPath, nil]];
    [unTarToTmp waitUntilExit];
    
    // cd to the new path.
    NSString *untarredPath = @"/tmp/template_bundle";
    [fileManager changeCurrentDirectoryPath:untarredPath];
    
    // Get the evaluator template source.
    NSString *evaluatorSourcePath = @"/tmp/template_bundle/OEEvaluator.m";
    NSFileHandle *evaluatorSourceHandle = [NSFileHandle fileHandleForReadingAtPath:evaluatorSourcePath];
    NSMutableString *evaluatorSource = [[NSMutableString alloc] initWithData:[evaluatorSourceHandle readDataToEndOfFile] 
                                                      encoding:NSUTF8StringEncoding];
    [evaluatorSourceHandle closeFile];
        
    // Replace the sentinel with your code.
    [evaluatorSource replaceOccurrencesOfString:@"/* This comment will be replaced with your code. */" 
                                     withString:_code 
                                        options:0 
                                          range:NSMakeRange(0, [evaluatorSource length])];
    
    [fileManager removeItemAtPath:evaluatorSourcePath error:NULL];
    
    // Write it.
    [fileManager createFileAtPath:evaluatorSourcePath contents:[evaluatorSource dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    
    // Build the bundle. Is this a hack yet? ...
    NSTask *build = [[NSTask alloc] init];
    [build setLaunchPath:@"/usr/bin/xcodebuild"];
    [build setStandardError:[NSPipe pipe]];
    [build setStandardOutput:[NSPipe pipe]];
    [build launch];
    [build waitUntilExit];
    
    // Load up the bundle.
    NSString *bundlePath = @"/tmp/template_bundle/build/Release/template_bundle.bundle";
    NSBundle *compiledBundle = [NSBundle bundleWithPath:bundlePath];
    
    // Get the principle class and allocate.
    Class evaluatorClass = [compiledBundle principalClass];
    OEEvaluator *evaluator = [[evaluatorClass alloc] init];
    _evaluator = evaluator;
}

// Evaluate. This could do anything. You are warned.
- (void)startEvaluation {
    NSBlockOperation *evaluateBlock = [NSBlockOperation blockOperationWithBlock:^{
        [self compileAndExecute];
    }];
    
    [evaluateBlock setCompletionBlock:^{
        [_delegate evaluation:self evaluatedWithResult:[_evaluator eval]];
    }];
    
    [evaluateBlock start];
}

- (id)evaluateSynchronously {
    [self compileAndExecute];
    return [_evaluator eval];
}

-(void)dealloc {
    [_code release];
    [_evaluator release];
    [super dealloc];
}

@end
