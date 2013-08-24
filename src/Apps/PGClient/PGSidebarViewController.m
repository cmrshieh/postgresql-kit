

#import <Cocoa/Cocoa.h>
#import "PGSidebarViewController.h"
#import "PGSidebarDataSource.h"
#import "PGClientApplication.h"
#import "PGSidebarNode.h"

@implementation PGSidebarViewController

////////////////////////////////////////////////////////////////////////////////
// initializers

-(id)init {
    self = [super init];
    if (self) {
		_datasource = [[PGSidebarDataSource alloc] init];
    }
    return self;
}

-(void)applicationDidFinishLaunching:(NSNotification* )aNotification {
	// call awakeFromNib - setup datasource
	[[self datasource] awakeFromNib];
	// set view datasource
	NSParameterAssert([[self view] isKindOfClass:[NSOutlineView class]]);
	NSOutlineView* view = (NSOutlineView* )[self view];
	[view setDataSource:[self datasource]];
	// set row height
	[view setRowHeight:20.0];
	// expand all group
	for(PGSidebarNode* group in [[self datasource] groups]) {
		[view expandItem:group];
	}
	// register for dragging
	[view registerForDraggedTypes:[NSArray arrayWithObject:PGSidebarDragType]];
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize datasource = _datasource;
@dynamic canOpen;
@dynamic canClose;
@dynamic canDelete;

-(BOOL)canOpen {
	PGSidebarNode* node = [self selectedNode];
	if(node==nil) {
		return NO;
	}
	if([node type]==PGSidebarNodeTypeServer) {
		// TODO: Check to make sure not already opened
		return YES;
	}
	return NO;
}

-(BOOL)canClose {
	PGSidebarNode* node = [self selectedNode];
	if(node==nil) {
		return NO;
	}
	if([node type]==PGSidebarNodeTypeServer) {
		// TODO: Check to make sure not already closed
		return YES;
	}
	return NO;	
}

-(BOOL)canDelete {
	PGSidebarNode* node = [self selectedNode];
	if(node==nil) {
		return NO;
	}
	if([node type]==PGSidebarNodeTypeServer && [node key]==PGSidebarNodeKeyInternalServer) {
		return NO;
	}
	if([node type]==PGSidebarNodeTypeServer) {
		// TODO: Can't delete if server is connected
		return YES;
	}
	return NO;
}

////////////////////////////////////////////////////////////////////////////////
// methods

-(PGSidebarNode* )selectedNode {
	NSOutlineView* view = (NSOutlineView* )[self view];
	NSInteger row = [view selectedRow];
	if(row < 0) {
		return nil;
	}
	PGSidebarNode* node = [view itemAtRow:row];
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
	return node;
}

-(void)selectNode:(PGSidebarNode* )node {
	NSOutlineView* view = (NSOutlineView* )[self view];
	if(node==nil) {
		[view deselectAll:self];
	} else {
		NSInteger rowIndex = [view rowForItem:node];
		NSParameterAssert([node type] != PGSidebarNodeTypeGroup);
		NSParameterAssert(rowIndex >= 0);
		[view selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
	}
}

-(void)deleteNode:(PGSidebarNode* )node {
	[[self datasource] deleteNode:node];
	[(NSOutlineView* )[self view] reloadData];
	[self selectNode:nil];
}

////////////////////////////////////////////////////////////////////////////////
// Notification

-(void)ibNotificationAddConnection:(NSNotification* )notification {
	NSURL* url = [notification object];
	NSParameterAssert([url isKindOfClass:[NSURL class]]);
	
	// create name for the server
	NSString* name = [NSString stringWithFormat:@"%@@localhost",[url user]];
	PGSidebarNode* node = [[PGSidebarNode alloc] initAsServerWithKey:[[self datasource] nextKey] name:name];
	NSParameterAssert(node);

	// add URL to the node
	[node setURL:url];
	
	// datasource
	[[self datasource] addServer:node];
	// reload view
	NSOutlineView* view = (NSOutlineView* )[self view];
	[view reloadData];
	// select item
	[self selectNode:node];
}

////////////////////////////////////////////////////////////////////////////////
// NSOutlineView delegate

-(BOOL)outlineView:(NSOutlineView*)outlineView isGroupItem:(id)item {
	PGSidebarNode* node = (PGSidebarNode* )item;
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
	return [node type]==PGSidebarNodeTypeGroup;
}

-(BOOL)outlineView:(NSOutlineView*) outlineView shouldSelectItem:(id)item {
	PGSidebarNode* node = (PGSidebarNode* )item;
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
	return [node type]!=PGSidebarNodeTypeGroup;
}

-(NSString* )outlineView:(NSOutlineView *)outlineView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tc item:(id)item mouseLocation:(NSPoint)mouseLocation {
	// show tooltip of the server URL for server items
	PGSidebarNode* node = (PGSidebarNode* )item;
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
	if([node type]==PGSidebarNodeTypeServer) {
		return [[node URL] absoluteString];
	}
	return nil;
}

-(BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	// prevent editing of the internal server name
	PGSidebarNode* node = (PGSidebarNode* )item;
	NSParameterAssert([node isKindOfClass:[PGSidebarNode class]]);
	if([node key]==PGSidebarNodeKeyInternalServer) {
		return NO;
	}
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)doOpen:(id)sender {
	PGSidebarNode* node = [self selectedNode];
	NSParameterAssert(node);
	if([self canOpen] && [node type]==PGSidebarNodeTypeServer) {
		[[NSNotificationCenter defaultCenter] postNotificationName:PGClientNotificationOpenConnection object:node];
	}
}

-(IBAction)doClose:(id)sender {
	PGSidebarNode* node = [self selectedNode];
	NSParameterAssert(node);
	if([self canClose] && [node type]==PGSidebarNodeTypeServer) {
		[[NSNotificationCenter defaultCenter] postNotificationName:PGClientNotificationCloseConnection object:node];
	}
}

-(IBAction)doDelete:(id)sender {
	PGSidebarNode* node = [self selectedNode];
	NSParameterAssert(node);
	if([self canDelete] && [node type]==PGSidebarNodeTypeServer) {
		[[NSNotificationCenter defaultCenter] postNotificationName:PGClientNotificationDeleteConnection object:node];
	}
}

@end