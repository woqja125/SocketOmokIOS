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
		Wthr = [[NSThread alloc] initWithTarget:self selector:@selector(write) object:nil];
		Rthr = [[NSThread alloc] initWithTarget:self selector:@selector(read) object:nil];
		[Wthr start];
		[Rthr start];
    }
    return self;
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
		
		//
		//
	}
}

-(NSString *)readString
{
	while([Input count] == 0);
	NSString *t = [Input objectAtIndex:0];
	[Input removeObjectAtIndex:0];
	return t;
}

-(void)write
{
	while(![[NSThread currentThread] isCancelled])
	{
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
		//
	}
	return false;
}

-(void)close
{
	NSLog(@"Socket Closed Fuck!!!!!!!");
	close(socketfd);
	isConnected = false;
	[Rthr cancel];
	[Wthr cancel];
}

@end
