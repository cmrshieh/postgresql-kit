
#import <Foundation/Foundation.h>
#import "PGServerKit.h"

extern NSUInteger PGServerDefaultPort;

@interface PGServer : NSObject {
	PGServerState _state;
	NSString* _hostname;
	NSUInteger _port;
	NSString* _dataPath;
	NSTask* _currentTask;
	NSTimer* _timer;
	int _pid;
	PGServerPreferences* _authentication;
	PGServerPreferences* _configuration;
}

// properties
@property id delegate;
@property (readonly) NSString* version;
@property (readonly) PGServerState state;
@property (readonly) NSString* hostname;
@property (readonly) NSUInteger port;
@property (readonly) NSString* dataPath;

// return shared server object
+(PGServer* )sharedServer;

// start, stop, restart and reload the server
-(BOOL)startWithDataPath:(NSString* )thePath;
-(BOOL)startWithDataPath:(NSString* )thePath hostname:(NSString* )hostname port:(NSUInteger)port;
-(BOOL)stop;
-(BOOL)restart;
-(BOOL)reload;

// read authentication and configuration
-(PGServerPreferences* )authentication;
-(PGServerPreferences* )configuration;


// utility methods
+(NSString* )stateAsString:(PGServerState)theState;

@end

