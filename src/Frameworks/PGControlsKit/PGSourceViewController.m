
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

#import <PGControlsKit/PGControlsKit.h>
#import "PGSourceViewTree.h"

@interface PGSourceViewController ()
@property (readonly) PGSourceViewTree* model;
@property (weak) IBOutlet NSOutlineView* ibOutlineView;
@end

@implementation PGSourceViewController

////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)init {
    self = [super initWithNibName:@"PGSourceView" bundle:[NSBundle bundleForClass:[self class]]];
	if(self) {
		_model = [PGSourceViewTree new];
		NSParameterAssert(_model);
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize model = _model;
@synthesize ibOutlineView;

////////////////////////////////////////////////////////////////////////////////
// methods

-(void)addHeadingWithTitle:(NSString* )title {
	PGSourceViewNode* node = [[PGSourceViewNode alloc] initWithName:title];
	[[self model] addNode:node parent:nil];	
	[[self ibOutlineView] reloadData];
}

////////////////////////////////////////////////////////////////////////////////
// NSOutlineViewDataSource

-(id)outlineView:(NSOutlineView* )outlineView child:(NSInteger)index ofItem:(id)item {
	NSParameterAssert(outlineView==[self ibOutlineView]);
	NSParameterAssert(item==nil || [item isKindOfClass:[PGSourceViewNode class]]);
	return [[self model] nodeAtIndex:index parent:item];
}

-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	NSParameterAssert(outlineView==[self ibOutlineView]);
	NSParameterAssert(item==nil || [item isKindOfClass:[PGSourceViewNode class]]);
	return [[self model] numberOfChildrenOfParent:item];
}

-(BOOL)outlineView:(NSOutlineView* )outlineView isItemExpandable:(id)item {
	NSParameterAssert(outlineView==[self ibOutlineView]);
	NSParameterAssert(item==nil || [item isKindOfClass:[PGSourceViewNode class]]);
	return [[self model] numberOfChildrenOfParent:item] ? YES : NO;
}

////////////////////////////////////////////////////////////////////////////////
// NSOutlineView delegate

-(BOOL)outlineView:(NSOutlineView* )outlineView isGroupItem:(id)item {
	NSParameterAssert([item isKindOfClass:[PGSourceViewNode class]]);
	return [item isGroupItem];
}

-(BOOL)outlineView:(NSOutlineView* )outlineView shouldSelectItem:(id)item {
	NSParameterAssert([item isKindOfClass:[PGSourceViewNode class]]);
	return [item shouldSelectItem];
}

-(NSString* )outlineView:(NSOutlineView* )outlineView toolTipForCell:(NSCell* )cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tc item:(id)item mouseLocation:(NSPoint)mouseLocation {
	NSParameterAssert([item isKindOfClass:[PGSourceViewNode class]]);
	return nil;
}

-(BOOL)outlineView:(NSOutlineView* )outlineView shouldEditTableColumn:(NSTableColumn* )tableColumn item:(id)item {
	return NO;
}

-(NSView* )outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn* )tableColumn item:(id)item {
	NSParameterAssert([item isKindOfClass:[PGSourceViewNode class]]);
	NSTableCellView* result = [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
	[[result textField] setStringValue:[item name]];
    return result;
}

@end
