//
//  OmokViewController.h
//  SocketOmok
//
//  Created by 이재범 on 2014. 9. 12..
//  Copyright (c) 2014년 jb. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JBSocket;
@class OmokView;

@interface OmokViewController : UIViewController
{
    NSString *nickName, *opnickName;
    IBOutlet UILabel *nickNameView, *opnickNameView;
	IBOutlet UIView *StoneME, *StoneOP;
	IBOutlet UIButton *OKbtn;
	
	JBSocket *socket;
	int isHost;
	
	int Col, NowTurn;
	int map[20][20];
	IBOutlet OmokView *omok;
	
	bool CloseMyself;
}
-(void)setNickName:(NSString *)nick;
-(void)setopNickName:(NSString *)opnick;
-(void)setSock:(JBSocket*)sock;
-(void)setHost:(int)X;
@end
