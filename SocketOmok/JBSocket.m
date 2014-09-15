//
//  JBSocket.m
//  SocketOmok
//
//  Created by 이재범 on 2014. 9. 12..
//  Copyright (c) 2014년 jb. All rights reserved.
//

#import "JBSocket.h"
#import <sys/types.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <netdb.h>

@implementation JBSocket

-(id)initWithfd:(int)fd
{
    self = [super init];
    if(self)
    {
        socketfd = fd;
		Output = [[NSMutableArray alloc] init];
		Input = [[NSMutableArray alloc] init];
		lastPing = [[NSDate alloc] init];
		isConnected = true;
		[self performSelectorInBackground:@selector(write) withObject:nil];
		[self performSelectorInBackground:@selector(read) withObject:nil];
		[self performSelectorInBackground:@selector(Ping) withObject:nil];
    }
    return self;
}

-(void)Ping
{
	while([self isConnected])
	{
		[NSThread sleepForTimeInterval:1];
		[self writeString:@"__Ping__"];
	}
}

-(void)read
{
	while(![[NSThread currentThread] isCancelled])
	{
		NSString *t;
		
		int n=2, d=0, c;
		char buff[513], str[10000];
		while(n>0)
		{
			c = recv(socketfd, buff, n, 0);
			if(c<0)
			{
				[self close];
				return;
			}
			n -= c;
			for(int i=0; i<c; i++) d = d*16+buff[i];
			[NSThread sleepForTimeInterval:0.01];
		}
		c = 0;
		int l = 0;
		while(d>0)
		{
			c = read(socketfd, buff, d<513?d:10000);
			if(c<0)
			{
				[self close];
				return;
			}
			d -= c;
			for(int i=0; i<c; i++) str[l++] = buff[i];
		}
		str[l] = 0;
		t = [NSString stringWithUTF8String:str];
		
		if([t isEqualToString:@"__Ping__"])
			lastPing = [NSDate date];
		else [Input addObject:t];
	}
}

-(NSString *)readString
{
	while([self isConnected] && [Input count] == 0)[NSThread sleepForTimeInterval:0.01];
	if([Input count] == 0) return @"error";
	NSString *t = [Input objectAtIndex:0];
	[Input removeObjectAtIndex:0];
	return t;
}

-(void)write
{
	while(![[NSThread currentThread] isCancelled])
	{
		[NSThread sleepForTimeInterval:0.01];
		if([Output count] == 0) continue;
		NSString *t = [Output firstObject];
		[self sendString:t];
		[Output removeObjectAtIndex:0];
	}
}

-(void)sendString:(NSString *)str
{
	char buff[1000], *tmp;
	int l, s;
	s = 0;
	l = 0;
	tmp = [str UTF8String];
	int len = strlen(tmp);
	buff[l++] = len/16;
	buff[l++] = len%16;
	for(int i=0; tmp[i]!=0; i++)
	{
		buff[l++] = tmp[i];
	}
	while(l>0)
	{
		int c = send(socketfd, buff+s, l, 0);
		if(c<0)
		{
			[self close];
			return;
		}
		l -= c;
		s += c;
	}
}

-(void)writeString:(NSString *)str
{
	[Output addObject:str];
}

-(bool)isConnected
{
	if(isConnected)
	{
		NSDate *t = lastPing;
		NSTimeInterval secondsBetweenDates = [t timeIntervalSinceNow];
		if(secondsBetweenDates <= 2) return true;
	}
	return isConnected = false;
}

-(void)close
{
	close(socketfd);
	isConnected = false;
}

@end
