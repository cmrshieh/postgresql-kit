
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

#import "Application.h"

////////////////////////////////////////////////////////////////////////////////

NSInteger PGDatabasesTag = -100;
NSInteger PGQueriesTag = -200;

////////////////////////////////////////////////////////////////////////////////

@interface Application ()
@property (weak) IBOutlet NSWindow* window;
@property (retain) PGSourceViewNode* databases;
@property (retain) PGSourceViewNode* queries;
@end

/*
@property (weak) IBOutlet NSWindow* ibDeleteDatabaseSheet;
@property (weak) IBOutlet NSMenu* ibConnectionContextMenu;
@property (retain) NSString* ibDeleteDatabaseSheetNodeName;
*/

@implementation Application

////////////////////////////////////////////////////////////////////////////////
// constructor

-(id)init {
	self = [super init];
	if(self) {
		// set up dialog window
		_dialogWindow = [PGDialogWindow new];
		NSParameterAssert(_dialogWindow);
	
		// set up tab view
		_splitView = [PGSplitViewController new];
		NSParameterAssert(_splitView);

		// set up source view
		_sourceView = [PGSourceViewController new];
		NSParameterAssert(_sourceView);
		[_sourceView setDelegate:self];

/*
		_tabView = [PGTabViewController new];
		_helpWindow = [PGHelpWindowController new];
		_buffers = [ConsoleBuffer new];
		NSParameterAssert(_buffers);
		NSParameterAssert(_helpWindow);
		[_tabView setDelegate:self];
*/

	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@synthesize splitView = _splitView;
@synthesize sourceView = _sourceView;
@synthesize databases;
@synthesize queries;
@dynamic pool;

-(PGConnectionPool* )pool {
	return [PGConnectionPool sharedPool];
}

/*
@synthesize tabView = _tabView;
@synthesize helpWindow = _helpWindow;
*/

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)resetSourceView {
	[self setDatabases:[PGSourceViewNode headingWithName:@"DATABASES"]];
	[self setQueries:[PGSourceViewNode headingWithName:@"QUERIES"]];
	NSParameterAssert([self databases] && [self queries]);
	
	[[self sourceView] removeAllNodes];
	[[self sourceView] addNode:[self databases] parent:nil tag:PGDatabasesTag];
	[[self sourceView] addNode:[self queries] parent:nil tag:PGQueriesTag];
	NSParameterAssert([[self sourceView] count]==2);
	[[self sourceView] saveToUserDefaults];
}

-(BOOL)loadSourceView {
	[[self sourceView] loadFromUserDefaults];
	PGSourceViewNode* d = [[self sourceView] nodeForTag:PGDatabasesTag];
	PGSourceViewNode* q = [[self sourceView] nodeForTag:PGQueriesTag];
	if(d==nil || q==nil) {
		[self resetSourceView];
	} else {
		[self setDatabases:d];
		[self setQueries:q];
	}
	
	// set the child classes we're willing to accept
	[[self databases] setChildClasses:@[ NSStringFromClass([PGSourceViewConnection class]) ]];
	[[self queries] setChildClasses:@[ ]];

	if([[self sourceView] count]==2) {
		// empty source view...only the headings
		return NO;
	}
	
	// show database view
	[[self sourceView] expandNode:[self databases]];
	
	return YES;
}

-(void)addSplitView {
	NSView* contentView = [[self window] contentView];

	// add splitview to the content view
	NSView* splitView = [[self splitView] view];
	[contentView addSubview:splitView];
	[splitView setTranslatesAutoresizingMaskIntoConstraints:NO];

	// make it resize with the window
	NSDictionary* views = NSDictionaryOfVariableBindings(splitView);
	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[splitView]|" options:0 metrics:nil views:views]];
	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[splitView]|" options:0 metrics:nil views:views]];

	// add left and right views
	[[self splitView] setLeftView:[self sourceView]];

/*
	[[self splitView] setRightView:[self tabView]];

	// add menu items to split view
	NSMenuItem* menuItem1 = [[NSMenuItem alloc] initWithTitle:@"New Network Connection..." action:@selector(doNewNetworkConnection:) keyEquivalent:@""];
	[[self splitView] addMenuItem:menuItem1];

	NSMenuItem* menuItem2 = [[NSMenuItem alloc] initWithTitle:@"New Socket Connection..." action:@selector(doNewSocketConnection:) keyEquivalent:@""];
	[[self splitView] addMenuItem:menuItem2];

	NSMenuItem* menuItem5 = [[NSMenuItem alloc] initWithTitle:@"Reset Source View" action:@selector(doResetSourceView:) keyEquivalent:@""];
	[[self splitView] addMenuItem:menuItem5];
*/

	// set autosave name and set minimum split view width
	[[self splitView] setAutosaveName:@"PGSplitView"];
	[[self splitView] setMinimumSize:75.0];

}

-(void)createConnectionWithURL:(NSURL* )url comment:(NSString* )comment {
	// create a node
	PGSourceViewNode* node = [PGSourceViewNode connectionWithURL:url];
	// add node
	[[self sourceView] addNode:node parent:[self databases]];
	// connect
	NSParameterAssert([node isKindOfClass:[PGSourceViewConnection class]]);
	[self connectNode:(PGSourceViewConnection* )node];
}

-(void)connectWithPasswordForNode:(PGSourceViewConnection* )node {
	NSParameterAssert(node);
	PGDialogWindow* dialog = [self dialogWindow];
	NSParameterAssert(dialog);

	// get tag node from source view
	NSInteger tag = [[self sourceView] tagForNode:node];
	NSParameterAssert(tag);

	[dialog beginPasswordSheetSaveInKeychain:YES parentWindow:[self window] whenDone:^(NSString* password,BOOL saveInKeychain) {
		if(password) {
			[[self pool] setPassword:password forTag:tag saveInKeychain:saveInKeychain];
			[self connectNode:node];
		}
	}];
}

-(void)connectNode:(PGSourceViewConnection* )node {
	NSParameterAssert(node && [node isKindOfClass:[PGSourceViewConnection class]]);

	// get tag node from source view
	NSInteger tag = [[self sourceView] tagForNode:node];
	NSParameterAssert(tag);

	// set connection in the pool
	if([[self pool] URLForTag:tag]) {
		[[self pool] removeForTag:tag];
	}
	if([[self pool] createConnectionWithURL:[node URL] tag:tag]) {
		// display the node which is going to be connected
		[[self sourceView] expandNode:[self databases]];
		[[self sourceView] selectNode:node];
	}

	// perform connection
	[[self pool] connectForTag:tag whenDone:^(NSError* error) {
		if([error isNeedsPassword]) {
			[self connectWithPasswordForNode:node];
		} else if([error isBadPassword]) {
			[[self pool] removePasswordForTag:tag];
		}
		if(error) {
			[self beginErrorSheet:error];
		}
	}];
}

-(void)disconnectNode:(PGSourceViewConnection* )node {
	// get tag node from source view
	NSInteger tag = [[self sourceView] tagForNode:node];
	NSParameterAssert(tag);
	// perform disconnection
	[[self pool] disconnectForTag:tag];
}


-(void)beginErrorSheet:(NSError* )error {
	NSParameterAssert(error);
	NSLog(@"ERROR: %@",error);
}

-(void)reloadNode:(PGSourceViewNode* )node {
	[[self sourceView] reloadNode:node];
}

/*

-(void)_showDatabasesForNode:(PGSourceViewConnection* )node {
	// get tag node from source view
	NSInteger tag = [[self sourceView] tagForNode:node];
	NSParameterAssert(tag);
	// execute query
	PGResult* result = [[self connections] execute:@"SELECT 1" forTag:tag];
	if(result) {
		NSLog(@"%@",[result tableWithWidth:80]);
		[self _appendConsoleString:[result tableWithWidth:80] forTag:tag];
	}
}


-(void)_appendConsoleString:(NSString* )string forTag:(NSInteger)tag {
	PGConsoleViewController* controller = (PGConsoleViewController* )[_tabView selectViewWithTag:tag];
	NSParameterAssert([controller isKindOfClass:[PGConsoleViewController class]]);

	PGConsoleViewBuffer* buffer = [controller dataSource];
	NSParameterAssert(buffer);
	
	[buffer appendString:string];
	[controller reloadData];
	[controller scrollToBottom];
}

*/

////////////////////////////////////////////////////////////////////////////////
// IBActions

-(IBAction)doNewRemoteConnection:(id)sender {
	PGDialogWindow* dialog = [self dialogWindow];
	NSParameterAssert(dialog);
	[dialog beginConnectionSheetWithURL:[PGDialogWindow defaultNetworkURL] comment:nil parentWindow:[self window] whenDone:^(NSURL* url, NSString* comment) {
		if(url) {
			[self createConnectionWithURL:url comment:comment];
		}
	}];
}

-(IBAction)doNewLocalConnection:(id)sender {
	PGDialogWindow* dialog = [self dialogWindow];
	NSParameterAssert(dialog);
	[dialog beginConnectionSheetWithURL:[PGDialogWindow defaultFileURL] comment:nil parentWindow:[self window] whenDone:^(NSURL* url, NSString* comment) {
		if(url) {
			[self createConnectionWithURL:url comment:comment];
		}
	}];
}

-(IBAction)doEditConnection:(id)sender {
	PGDialogWindow* dialog = [self dialogWindow];
	NSParameterAssert(dialog);
	PGSourceViewConnection* connection = (PGSourceViewConnection* )[[self sourceView] selectedNode];
	if(connection==nil) {
		return;
	}
	NSParameterAssert(connection && [connection isKindOfClass:[PGSourceViewConnection class]]);
	[dialog beginConnectionSheetWithURL:[connection URL] comment:[connection name] parentWindow:[self window] whenDone:^(NSURL* url, NSString* comment) {
		if(url) {
			NSInteger tag = [[self sourceView] tagForNode:connection];
			NSLog(@"TODO: update URL to %@ for tag %ld",url,tag);
			[connection setURL:url];
			[connection setName:comment];
		}
	}];
}

-(IBAction)doConnect:(id)sender {
	PGSourceViewNode* connection = [[self sourceView] selectedNode];
	if([connection isKindOfClass:[PGSourceViewConnection class]]) {
		[self connectNode:(PGSourceViewConnection* )connection];
	}
}

-(IBAction)doDisconnect:(id)sender {
	PGSourceViewNode* connection = [[self sourceView] selectedNode];
	if([connection isKindOfClass:[PGSourceViewConnection class]]) {
		[self disconnectNode:(PGSourceViewConnection* )connection];
	}
}

/*
-(IBAction)doResetSourceView:(id)sender {
	// disconnect any existing connections
	[[self connections] removeAll];
	
	// connect to remote server
	[self resetSourceView];
}


-(IBAction)doHelp:(id)sender {
	// display the help window
	NSError* error = nil;
	if([[self helpWindow] displayHelpFromMarkdownResource:@"help/Introduction" bundle:[NSBundle mainBundle] error:&error]==NO) {
		NSLog(@"error: %@",error);
	}
}

-(IBAction)doAboutPanel:(id)sender {
	// display the help window
	NSError* error = nil;
	if([[self helpWindow] displayHelpFromMarkdownResource:@"NOTICE" bundle:[NSBundle mainBundle] error:&error]==NO) {
		NSLog(@"error: %@",error);
	}
}

-(IBAction)doShowDatabases:(id)sender {
	PGSourceViewNode* connection = [[self sourceView] selectedNode];
	if([connection isKindOfClass:[PGSourceViewConnection class]]) {
		[self _showDatabasesForNode:(PGSourceViewConnection* )connection];
	}
}

-(IBAction)ibButtonClicked:(id)sender {
	NSParameterAssert([sender isKindOfClass:[NSButton class]]);
	NSWindow* theWindow = [(NSButton* )sender window];
	if([[(NSButton* )sender title] isEqualToString:@"Cancel"]) {
		[[self window] endSheet:theWindow returnCode:NSModalResponseCancel];
	} else if([[(NSButton* )sender title] isEqualToString:@"OK"]) {
		[[self window] endSheet:theWindow returnCode:NSModalResponseOK];
	} else {
		// Unknown button clicked
		NSLog(@"Button clicked, ignoring: %@",sender);
	}
}
*/

////////////////////////////////////////////////////////////////////////////////
// methods - PGSourceView delegate

/*
-(void)sourceView:(PGSourceViewController* )sourceView selectedNode:(PGSourceViewNode* )node {
	NSParameterAssert(sourceView==[self sourceView]);
	NSParameterAssert(node);

	// get tag node from source view
	NSInteger tag = [[self sourceView] tagForNode:node];
	NSParameterAssert(tag);
	
	// select view
	[[self tabView] selectViewWithTag:tag];
}
*/

-(void)sourceView:(PGSourceViewController* )sourceView doubleClickedNode:(PGSourceViewNode* )node {
	NSParameterAssert(sourceView==[self sourceView]);
	NSParameterAssert(node);

	// get tag node from source view
	//NSInteger tag = [[self sourceView] tagForNode:node];
	//NSParameterAssert(tag);

	if([node isKindOfClass:[PGSourceViewConnection class]]) {
		[self doEditConnection:nil];
	}
	/*
		PGConnectionStatus status = [[self connections] statusForTag:tag];
		if(status != PGConnectionStatusConnected) {
			[self _connectNode:(PGSourceViewConnection* )node];
		}
		// set first responder
		[[self tabView] selectViewWithTag:tag];
	} else {
		NSLog(@"double clicked node = %@",node);
	}
	*/
}

/*
-(void)sourceView:(PGSourceViewController* )sourceView deleteNode:(PGSourceViewNode* )node {
	NSParameterAssert(sourceView==[self sourceView]);
	NSParameterAssert(node);

	// display confirmation sheet
	[self setIbDeleteDatabaseSheetNodeName:[node name]];
	[[self window] beginSheet:[self ibDeleteDatabaseSheet] completionHandler:^(NSModalResponse returnCode) {
		if(returnCode==NSModalResponseOK) {
			[sourceView removeNode:node];
		}
	}];
}

-(NSMenu* )sourceView:(PGSourceViewController* )sourceView menuForNode:(PGSourceViewNode* )node {
	if([node isKindOfClass:[PGSourceViewNode class]]) {
		[[self sourceView] selectNode:node];
		return [self ibConnectionContextMenu];
	}
	return nil;
}

////////////////////////////////////////////////////////////////////////////////
// PGTabViewDelegate implementation

-(NSViewController* )tabView:(PGTabViewController* )tabView newViewForTag:(NSInteger)tag {
	PGSourceViewNode* node = [[self sourceView] nodeForTag:tag];
	NSParameterAssert(node);
	
	// create a new console buffer
	PGConsoleViewBuffer* buffer = [PGConsoleViewBuffer new];
	NSParameterAssert(buffer);

	// create a console view
	PGConsoleViewController* controller = [PGConsoleViewController new];
	NSParameterAssert(controller);

	// tie up
	[controller setTitle:[node name]];
	[controller setDataSource:buffer];
	[controller setDelegate:self];
	[controller setEditable:YES];
	[controller setTag:tag];
	[_buffers setBuffer:buffer forTag:tag];
	[_buffers appendString:[node name] forTag:tag];
	
	// return controller
	return controller;
}

////////////////////////////////////////////////////////////////////////////////
// PGConsoleViewDelegate implementation

-(void)consoleView:(PGConsoleViewController* )consoleView append:(NSString* )string {
	NSInteger tag = [consoleView tag];
	NSParameterAssert(tag);
	
	// append line
	[self _appendConsoleString:string forTag:tag];
	// execute query
	PGResult* result = [[self connections] execute:string forTag:tag];
	if(result) {
		NSString* table = [result tableWithWidth:[consoleView textWidth]];
		if(table) {
			[self _appendConsoleString:table forTag:tag];
		}
		if([result affectedRows]) {
			[self _appendConsoleString:[NSString stringWithFormat:@"%ld affected row(s)",[result affectedRows]] forTag:tag];
		}
	}
}
*/

////////////////////////////////////////////////////////////////////////////////
// NSApplicationDelegate implementation

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {

	// get connection pool
	PGConnectionPool* pool = [self pool];
	[pool setDelegate:self];
	
	// load dialog window nib
	[[self dialogWindow] load];

	// add PGSplitView to the content view
	[self addSplitView];

	// load connections from user defaults, or "new" dialog
	if([self loadSourceView]==NO) {
		[self doNewRemoteConnection:nil];
	}
	
/*
	// load help from resource folder
	NSError* error = nil;
	[[self helpWindow] addPath:@"help" bundle:[NSBundle mainBundle] error:&error];
	[[self helpWindow] addResource:@"NOTICE" bundle:[NSBundle mainBundle] error:&error];
	
*/
}

-(void)applicationWillTerminate:(NSNotification *)aNotification {
	// disconnect from remote servers
	[[self pool] removeAll];

	// save user defaults
	[[self sourceView] saveToUserDefaults];
}

////////////////////////////////////////////////////////////////////////////////
// ConnectionPoolDelegate implementation

-(void)connectionForTag:(NSInteger)tag statusChanged:(PGConnectionStatus)status description:(NSString* )description {
	PGSourceViewConnection* node = (PGSourceViewConnection* )[[self sourceView] nodeForTag:tag];
	NSParameterAssert([node isKindOfClass:[PGSourceViewConnection class]]);
	NSLog(@"%@",description);
	switch(status) {
	case PGConnectionStatusConnected:
		[(PGSourceViewConnection* )node setIconStatus:PGSourceViewConnectionIconConnected];
		[self reloadNode:node];
		break;
	case PGConnectionStatusConnecting:
	case PGConnectionStatusBusy:
		[(PGSourceViewConnection* )node setIconStatus:PGSourceViewConnectionIconConnecting];
		[self reloadNode:node];
		break;
	case PGConnectionStatusRejected:
		[(PGSourceViewConnection* )node setIconStatus:PGSourceViewConnectionIconRejected];
		[self reloadNode:node];
		break;
	case PGConnectionStatusDisconnected:
	default:
		[(PGSourceViewConnection* )node setIconStatus:PGSourceViewConnectionIconDisconnected];
		[self reloadNode:node];
		break;
	}
}


/*

-(void)connectionPool:(PGConnectionPool *)pool tag:(NSInteger)tag statusChanged:(PGConnectionStatus)status {
	PGSourceViewNode* node = [[self sourceView] nodeForTag:tag];
	NSParameterAssert([node isKindOfClass:[PGSourceViewConnection class]]);
	
	switch(status) {
		case PGConnectionStatusConnected:
			[self _appendConsoleString:@"connected" forTag:tag];
			[(PGSourceViewConnection* )node setIconStatus:PGSourceViewConnectionIconConnected];
			[self _reloadNode:node];
			break;
		case PGConnectionStatusConnecting:
			[_buffers appendString:@"connecting" forTag:tag];
			[(PGSourceViewConnection* )node setIconStatus:PGSourceViewConnectionIconConnecting];
			[self _reloadNode:node];
			break;
		case PGConnectionStatusDisconnected:
			[_buffers appendString:@"disconnected" forTag:tag];
			[(PGSourceViewConnection* )node setIconStatus:PGSourceViewConnectionIconDisconnected];
			[self _reloadNode:node];
			break;
		case PGConnectionStatusRejected:
			[_buffers appendString:@"rejected" forTag:tag];
			[(PGSourceViewConnection* )node setIconStatus:PGSourceViewConnectionIconRejected];
			[self _reloadNode:node];
			break;
		default:
			[_buffers appendString:@"other connection status" forTag:tag];
			[(PGSourceViewConnection* )node setIconStatus:PGSourceViewConnectionIconDisconnected];
			[self _reloadNode:node];
			break;
	}
}

-(void)connectionPool:(PGConnectionPool* )pool tag:(NSInteger)tag error:(NSError* )error {
	[self _appendConsoleString:[error localizedDescription] forTag:tag];
}
*/

@end
