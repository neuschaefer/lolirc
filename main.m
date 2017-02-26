/*
 * Copyright (C) 2017 Jonathan Neuschäfer <j.neuschaefer@gmx.net>
 *
 * This file may be distributed under the terms of the GNU General Public
 * License version 2, which can be found in the file LICENSE.GPLv2 included
 * in the packaging of this file.
 */

#import <ObjFW/ObjFW.h>
#import <ObjIRC/IRCConnection.h>

#define PROGRAM_NAME @"LOLIRC"

@interface LOLIRC: OFObject <OFApplicationDelegate, IRCConnectionDelegate, OFKernelEventObserverDelegate>
{
	IRCConnection *_ircConnection;
	OFString *_channel;
}
@end

OF_APPLICATION_DELEGATE(LOLIRC)

@implementation LOLIRC
- (void)applicationDidFinishLaunching;
{
	of_log(@"%@ booting...", PROGRAM_NAME);

	[of_stdin asyncReadLineWithTarget: self
				 selector: @selector(stream:didReceiveLine:exception:)];
	[self setupIrcConnection];
}

- (void)setupIrcConnection
{
	of_log(@"Initializing IRC connection");
	_ircConnection = [[IRCConnection alloc] init];

	OFSettings *settings =
		[OFSettings settingsWithApplicationName: @"lolirc"];

	[_ircConnection setServer:
		[[settings stringForPath: @"connection.server"
			    defaultValue: @"chat.freenode.net"] copy]];

	[_ircConnection setPort:
		[settings integerForPath: @"connection.port"
			    defaultValue: 6667]];

	_channel = [[settings stringForPath: @"connection.channel"
			       defaultValue: @"#objfw"] copy];

	[_ircConnection setNickname:
		[[settings stringForPath: @"me.nickname"
			    defaultValue: @"lolirc"] copy]];

	[_ircConnection setUsername:
		[[settings stringForPath: @"me.username"
			    defaultValue: [self defaultUsername]] copy]];

	[_ircConnection setRealname:
		[[settings stringForPath: @"me.realname"
			   defaultValue: @"anonymous"] copy]];

	[_ircConnection setDelegate: self];

	of_log(@"Connecting to %@:%d", [_ircConnection server],
			[_ircConnection port]);
	[_ircConnection connect];
	[_ircConnection handleConnection];
}

- (OFString *)defaultUsername
{
	OFString *name = [[OFApplication environment] objectForKey: @"USER"];

	return name != nil? name : @"user";
}

- (void)connectionWasEstablished: (IRCConnection *)connection
{
	of_log(@"Connection with %@ established", [connection server]);

	of_log(@"Joining channel %@", _channel);
	[connection joinChannel: _channel];
}

- (void)connectionWasClosed: (IRCConnection *)connection
{
	of_log(@"Connection with %@ was closed :-(", [connection server]);
	[OFApplication terminate];
}

- (void)connection: (IRCConnection *)connection
  didReceiveNotice: (OFString *)notice
	      user: (IRCUser *)user
{
	[of_stdout writeFormat: @" * %@ %@\n", [user nickname], notice];
}

- (void)connection: (IRCConnection *)connection
	didSeeUser: (IRCUser *)user
       joinChannel: (OFString *)channel
{
	[of_stdout writeFormat: @" -> %@ joined channel %@\n", [user nickname], channel];
}

- (void)connection: (IRCConnection *)connection
	didSeeUser: (IRCUser *)user
      leaveChannel: (OFString *)channel
	    reason: (OFString *)reason
{
	[of_stdout writeFormat: @" <- %@ left channel %@ (%@)\n", [user nickname], channel, reason];
}

- (void)connection: (IRCConnection *)connection
	didSeeUser: (IRCUser *)user
  changeNicknameTo: (OFString *)newNick
{
	[of_stdout writeFormat: @" %@ is known as %@\n", [user nickname], newNick];
}

- (void)connection: (IRCConnection *)connection
	didSeeUser: (IRCUser *)user
	  kickUser: (OFString *)kicked
	   channel: (OFString *)channel
	    reason: (OFString *)reason
{
	[of_stdout writeFormat: @" !! %@ was kicked from %@ by %@ (%@)\n", kicked, channel, [user nickname], reason];

	if ([kicked isEqual: [connection nickname]]) {
		of_log(@"Oh no, I was kicked :-(");
		[OFApplication terminate];
	}
}

- (void)connection: (IRCConnection *)connection
    didSeeUserQuit: (IRCUser *)user
	    reason: (OFString *)reason
{
	[of_stdout writeFormat: @" <= %@ has quit (%@)\n", [user nickname], reason];
}

- (void)connection: (IRCConnection *)connection
 didReceiveMessage: (OFString *)msg
	   channel: (OFString *)channel
	      user: (IRCUser *)user
{
	[of_stdout writeFormat: @"<%@> %@\n", [user nickname], msg];
}

- (void)      connection: (IRCConnection *)connection
didReceivePrivateMessage: (OFString *)msg
		    user: (IRCUser *)user
{
	[of_stdout writeFormat: @"[%@/private] %@\n", [user nickname], msg];
}

- (bool) stream: (OFStream *)stream
 didReceiveLine: (OFString *)line
      exception: (OFException *)exception
{
	if (exception != nil) {
		of_log(@"Exception! (TODO: details)");
	}

	/*of_log(@"line! %@", line);*/

	if (_ircConnection != nil) {
		[self sendMessage: line];
	} else {
		of_log(@"Not connected");
	}

	/* schedule the same callback again */
	return true;
}

- (void) sendMessage: (OFString *)msg
{
	if (msg == nil) {
		of_log(@"Not sending empty message");
		return;
	}

	[_ircConnection sendMessage: msg
				 to: _channel];
}
@end
