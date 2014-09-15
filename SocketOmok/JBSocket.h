//
//  JBSocket.h
//  SocketOmok
//
//  Created by 이재범 on 2014. 9. 12..
//  Copyright (c) 2014년 jb. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JBSocket : NSObject
{
	NSMutableArray *Output, *Input;
    int socketfd;
	bool isConnected;
	
	NSDate *lastPing;

}
-(id)initWithfd:(int)fd;
-(NSString *)readString;
-(void)writeString:(NSString *)str;
-(void)close;
-(bool)isConnected;
@end