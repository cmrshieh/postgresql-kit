
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

#import <Foundation/Foundation.h>

@interface PGQuery : NSObject {
	NSDictionary* _dictionary;
}

// constructors
+(PGQuery* )queryWithDictionary:(NSDictionary* )dictionary;
+(PGQuery* )queryWithString:(NSString* )statement;

// properties
@property (readonly) NSDictionary* dictionary;

// methods to manipulate the dictionary
-(void)setObject:(id)object forKey:(NSString* )key;
-(id)objectForKey:(NSString* )key;

// methods to generate an SQL statement
-(NSString* )statementForConnection:(PGConnection* )connection;

@end
