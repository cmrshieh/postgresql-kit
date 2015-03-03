
// Copyright 2009-2015 David Thorpe
// https://github.com/djthorpe/postgresql-kit
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

#import <PGClientKit/PGClientKit.h>
#import <PGClientKit/PGClientKit+Private.h>

@implementation PGConnection (Execute)

////////////////////////////////////////////////////////////////////////////////
#pragma mark private methods - statement execution
////////////////////////////////////////////////////////////////////////////////

-(void)_execute:(NSString* )query format:(PGClientTupleFormat)format values:(NSArray* )values whenDone:(void(^)(PGResult* result,NSError* error)) callback {
	NSParameterAssert(query && [query isKindOfClass:[NSString class]]);
	NSParameterAssert(format==PGClientTupleFormatBinary || format==PGClientTupleFormatText);
	if(_connection==nil) {
		callback(nil,[self _errorWithCode:PGClientErrorState url:nil]);
		return;
	}
	if([self state] != PGConnectionStateNone) {
		callback(nil,[self _errorWithCode:PGClientErrorState url:nil]);
		return;
	}
	// create parameters object
	PGClientParams* params = _paramAllocForValues(values);
	if(params==nil) {
		callback(nil,[self _errorWithCode:PGClientErrorParameters url:nil]);
		return;
	}
	// convert parameters
	for(NSUInteger i = 0; i < [values count]; i++) {
		id obj = [values objectAtIndex:i];
		if([obj isKindOfClass:[NSNull class]]) {
			_paramSetNull(params,i);
			continue;
		}
		if([obj isKindOfClass:[NSString class]]) {
			NSData* data = [(NSString* )obj dataUsingEncoding:NSUTF8StringEncoding];
			_paramSetBinary(params,i,data,(Oid)25);
			continue;
		}
		// TODO - other kinds of parameters
		NSLog(@"TODO: Turn %@ into arg",[obj class]);		
		_paramSetNull(params,i);
	}
	// check number of parameters
	if(params->size > INT_MAX) {
		_paramFree(params);
		callback(nil,[self _errorWithCode:PGClientErrorParameters url:nil]);
		return;
	}
	
	// execute the command, free parameters
	int resultFormat = (format==PGClientTupleFormatBinary) ? 1 : 0;
	int returnCode = PQsendQueryParams(_connection,[query UTF8String],(int)params->size,params->types,(const char** )params->values,params->lengths,params->formats,resultFormat);
	_paramFree(params);
	if(!returnCode) {
		callback(nil,[self _errorWithCode:PGClientErrorExecute url:nil reason:[NSString stringWithUTF8String:PQerrorMessage(_connection)]]);
		return;
	}
	
	// set state, update status
	[self setState:PGConnectionStateQuery];
	[self _updateStatus];
	NSParameterAssert(_callback==nil);
	_callback = (__bridge_retained void* )[callback copy];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark public methods - execution
////////////////////////////////////////////////////////////////////////////////

-(void)executeQuery:(id)query whenDone:(void(^)(PGResult* result,NSError* error)) callback {
	NSParameterAssert([query isKindOfClass:[NSString class]] || [query isKindOfClass:[PGQuery class]]);
	NSParameterAssert(callback);
	if([query isKindOfClass:[PGQuery class]]) {
		NSString* queryString = [(PGQuery* )query statementForConnection:self];
		[self _execute:queryString format:PGClientTupleFormatText values:nil whenDone:callback];
	} else {
		NSParameterAssert([query isKindOfClass:[NSString class]]);
		[self _execute:query format:PGClientTupleFormatText values:nil whenDone:callback];
	}
}

@end


