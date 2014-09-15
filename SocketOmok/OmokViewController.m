//
//  OmokViewController.m
//  SocketOmok
//
//  Created by 이재범 on 2014. 9. 12..
//  Copyright (c) 2014년 jb. All rights reserved.
//

#import "OmokViewController.h"
#import "JBSocket.h"
#import "OmokView.h"

@interface OmokViewController ()

@end

@implementation OmokViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	nickNameView.text = nickName;
	nickNameView.font = [UIFont systemFontOfSize:40];
	nickNameView.textAlignment = NSTextAlignmentCenter;
	opnickNameView.text = opnickName;
	opnickNameView.font = [UIFont systemFontOfSize:40];
	opnickNameView.textAlignment = NSTextAlignmentCenter;
	srand(time(NULL));
	if(isHost != -1)
	{
		if(rand()%2 == 0)
		{
			Col = 1;
			[socket writeString:@"2"];
		}
		else
		{
			Col = 2;
			[socket writeString:@"1"];
		}
	}
	else
	{
		NSString *t = [socket readString];
		if([t isEqualToString:@"2"]) Col = 2;
		else if([t isEqualToString:@"1"]) Col = 1;
		else
		{
			NowTurn = Col = 1;
			[self EndGameWithErr];
		}
	}
	StoneME.layer.cornerRadius = 20;
	StoneOP.layer.cornerRadius = 20;
	if(Col == 1)
	{
		StoneME.backgroundColor = [UIColor blackColor];
		StoneOP.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
	}
	else
	{
		StoneME.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
		StoneOP.backgroundColor = [UIColor blackColor];
	}
	NowTurn = 2;
	CloseMyself = false;
	[self nextTurn];
}

-(int)isGameEnd
{
	int i, j, k, l;
	int dx[]={0, 1, 1, 1};
	int dy[]={1, -1, 0, 1};
	for(i=0; i<19; i++)
	{
		for(j=0; j<19; j++)
		{
			if(map[i][j] == 0) continue;
			for(k=0; k<4; k++)
			{
				for(l=0; l<5; l++)
				{
					int x = i+dx[k]*l;
					int y = j+dy[k]*l;
					if(x<0 || y<0 || x>=19 || y>=19 || map[x][y] != map[i][j]) break;
				}
				if(l==5) return map[i][j];
			}
		}
	}
	return 0;
}

-(void)nextTurn
{
	NowTurn = 3-NowTurn;
	int t = [self isGameEnd];
	if(t != 0)
	{
		[self EndGame:t];
		return;
	}
	if(NowTurn == Col)
		[self getFromUser];
	else
		[self getFromNetwork];
}

-(void)EndGame:(int)x
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"GameEnd" message:(x==Col)?@"WIN":@"LOSE" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
}

-(void)EndGameWithErr
{
	NSLog(@"Error");
	[self EndGame:Col];
}

-(void)getFromUser
{
	OKbtn.enabled = YES;
}

-(void)getFromNetwork
{
	OKbtn.enabled = NO;
	[self performSelectorInBackground:@selector(waitForOP) withObject:nil];
}

-(void)waitForOP
{
	NSString *t = [socket readString];
	int x, y;
	if(![socket isConnected])
	{
		if(CloseMyself != true) [self performSelectorOnMainThread:@selector(EndGameWithErr) withObject:nil waitUntilDone:NO];
		return;
	}
	sscanf(t.UTF8String, "%d %d", &x, &y);
	map[x][y] = NowTurn;
	[omok addStone:x :y :NowTurn];
	[self performSelectorOnMainThread:@selector(nextTurn) withObject:nil waitUntilDone:NO];
}

-(IBAction)OKClicked:(id)sender
{
	if(NowTurn != Col) return;
	int x = [omok getX];
	int y = [omok getY];
	if(map[x][y] != 0) return;
	map[x][y] = Col;
	[omok addStone:x :y :Col];
	[socket writeString:[NSString stringWithFormat:@"%d %d", x, y]];
	if(![socket isConnected])
	{
		[self EndGameWithErr];
		return;
	}
	[self nextTurn];
}

-(void)checkPoint:(int)x :(int)y
{
	map[x][y] = Col;
	[omok addStone:x :y :NowTurn];
	[self nextTurn];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[[self navigationController] popViewControllerAnimated:YES];
}

-(void) viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound)
	{
		CloseMyself = true;
		[socket close];
		if (isHost != -1) {
			close(isHost);
		}
    }
    [super viewWillDisappear:animated];
}

-(void)setNickName:(NSString *)nick{nickName = nick;}
-(void)setopNickName:(NSString *)opnick{opnickName = opnick;}
-(void)setSock:(JBSocket*)sock{socket = sock;}
-(void)setHost:(BOOL)X{isHost = X;}
@end
