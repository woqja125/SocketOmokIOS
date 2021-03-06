//
//  StartViewController.h
//  SocketOmok
//
//  Created by 이재범 on 2014. 9. 12..
//  Copyright (c) 2014년 jb. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JBSocket;
@interface StartViewController : UIViewController
{
    IBOutlet UITextField *ip, *nick;
	
	int serverSock;
	UIAlertView *alert1, *alert2;
	
	JBSocket *clientSocket;
	NSString *opNick;
	
	int isHost;
	
	NSThread *broadcast;
	
	NSMutableArray *Nicks, *Ips;
	IBOutlet UITableView *tv;
	IBOutlet UIButton *refreshbtn;
	
}
-(IBAction)serverClick:(id)sender;
-(IBAction)clientClick:(id)sender;
-(IBAction)refreshClick:(id)sender;
@end
