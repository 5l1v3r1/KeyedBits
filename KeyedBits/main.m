//
//  main.m
//  KeyedBits
//
//  Created by Alex Nichol on 9/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+KeyedBits.h"
#import "NSObject+SBJson.h"

void TestString (void);
void TestData (void);
void TestArray (void);
void TestInteger (void);
void TestFloating (void);
void TestDictionary (void);
void Benchmark (void);

int main (int argc, const char * argv[]) {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	TestString();
	TestData();
	TestInteger();
	TestFloating();
	TestArray();
	TestDictionary();
	Benchmark();
	
	while (1) {
		
	}
	
	[pool drain];
    return 0;
}

void TestString (void) {
	NSData * encoded = [[@"Hello, KeyedBits!" keyedBitsValue] encodeValue];
	NSString * decoded = [NSString objectWithKeyedBitsData:encoded];
	NSLog(@"%@", decoded);
}

void TestData (void) {
	NSData * encodeMe = [@"Hello, ASCII data!" dataUsingEncoding:NSASCIIStringEncoding];
	NSData * encoded = [[encodeMe keyedBitsValue] encodeValue];
	NSData * decoded = [NSData objectWithKeyedBitsData:encoded];
	NSString * message = [[NSString alloc] initWithData:(NSData *)decoded encoding:NSASCIIStringEncoding];
	NSLog(@"%@", message);
	[message release];
}

void TestArray (void) {
	NSArray * messages = [NSArray arrayWithObjects:@"This", @"Is", @"A", @"Test", nil];
	NSData * encoded = [[messages keyedBitsValue] encodeValue];
	NSArray * decoded = [NSArray objectWithKeyedBitsData:encoded];
	NSLog(@"%@", decoded);
	
	NSArray * mixed = [NSArray arrayWithObjects:[NSNumber numberWithInt:17],
					   [NSData dataWithBytes:"\x02\x00\x01" length:3],
												@"Foobar",
												messages,
												[NSNull null],
												[NSNumber numberWithDouble:3.1415],
												nil];
	encoded = [[mixed keyedBitsValue] encodeValue];
	decoded = [NSArray objectWithKeyedBitsData:encoded];
	NSLog(@"%@", decoded);
	NSCAssert([mixed isEqual:decoded], @"Must decode to equal array");
}

void TestInteger (void) {
	NSNumber * integer = [NSNumber numberWithInt:15];
	NSNumber * negative = [NSNumber numberWithInt:-1337];
	NSData * encoded = [[integer keyedBitsValue] encodeValue];
	NSNumber * decoded = [NSNumber objectWithKeyedBitsData:encoded];
	NSLog(@"15 = %@", decoded);
	encoded = [[negative keyedBitsValue] encodeValue];
	decoded = [NSNumber objectWithKeyedBitsData:encoded];
	NSLog(@"-1337 = %@", decoded);
}

void TestFloating (void) {
	NSNumber * aNumber = [NSNumber numberWithDouble:13.37];
	NSData * encoded = [[aNumber keyedBitsValue] encodeValue];
	NSNumber * decoded = [NSNumber objectWithKeyedBitsData:encoded];
	NSLog(@"13.37 = %@", decoded);
}

void TestDictionary (void) {
	NSDictionary * dog = [NSDictionary dictionaryWithObjectsAndKeys:@"Binary", @"name", 
						  @"Goldendoodle", @"breed", nil];
	NSArray * pets = [NSArray arrayWithObjects:dog, nil];
	NSDictionary * education = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"High School",
								[NSNumber numberWithBool:NO], @"College", @"Private", @"High School Type", nil];
	NSDictionary * dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"Alex", @"name",
								 [NSNumber numberWithInt:14], @"age", 
								 education, @"education", pets, @"pets", nil];
	NSData * encoded = [[dictionary keyedBitsValue] encodeValue];
	NSDictionary * decoded = [NSDictionary objectWithKeyedBitsData:encoded];
	NSLog(@"%@", decoded);
	NSCAssert([decoded isEqualToDictionary:dictionary], @"Must decode to equal dictionary");
}

void Benchmark (void) {
	NSData * benchmarkFile = [NSData dataWithContentsOfFile:@"/Users/alex/Desktop/benchmark.json"];
	NSString * benchmarkString = [[NSString alloc] initWithData:benchmarkFile encoding:NSUTF8StringEncoding];
	if (!benchmarkString) {
		NSLog(@"Failed to read benchmark file.");
		return;
	}
	NSDictionary * benchmark = [benchmarkString JSONValue];
	[benchmarkString release];
	
	if (!benchmark) {
		NSLog(@"Failed to parse benchmark.");
		return;
	}
	
	NSInteger keyedBitsSize = 0;
	NSInteger jsonSize = 0;
	
	NSLog(@"Begin benchmark");
	NSDate * start = [NSDate date];
	for (int i = 0; i < 200; i++) {
		NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		NSData * encoded = [[benchmark keyedBitsValue] encodeValue];
		NSDictionary * decoded = [NSDictionary objectWithKeyedBitsData:encoded];
		if (!decoded) {
			NSLog(@"Decode/encode of benchmark failed.");
			[pool drain];
			return;
		}
		keyedBitsSize = [encoded length];
		[pool drain];
	}
	NSLog(@"Benchmark complete: %lf", [[NSDate date] timeIntervalSinceDate:start]);
	
	NSLog(@"Begin benchmark (JSON framework)");
	start = [NSDate date];
	for (int i = 0; i < 200; i++) {
		NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		NSString * encoded = [benchmark JSONRepresentation];
		NSDictionary * decoded = [encoded JSONValue];
		if (!decoded) {
			NSLog(@"Decode/encode of benchmark failed.");
			[pool drain];
			return;
		}
		jsonSize = [encoded length];
		[pool drain];
	}
	NSLog(@"Benchmark complete: %lf", [[NSDate date] timeIntervalSinceDate:start]);
	
	NSLog(@"KeyedBits size: %ld", keyedBitsSize);
	NSLog(@"JSON size: %ld", jsonSize);
}
