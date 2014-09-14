//
//  OmokView.h
//  SocketOmok
//
//  Created by 이재범 on 2014. 9. 14..
//  Copyright (c) 2014년 jb. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OmokView : UIView
{
	int map[20][20];
	int x, y;
}
-(int)getX;
-(int)getY;
-(void)addStone:(int)x :(int)y :(int)Col;
@end
