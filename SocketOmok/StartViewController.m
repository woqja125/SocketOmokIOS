//
//  StartViewController.m
//  SocketOmok
//
//  Created by 이재범 on 2014. 9. 12..
//  Copyright (c) 2014년 jb. All rights reserved.
//

#import "StartViewController.h"
#import "OmokViewController.h"
#import "JBSocket.h"
#import <ifaddrs.h>
#import <arpa/inet.h>

#define ACCEPT_CLIENT_ALERT 1
#define WAITING_CLIENT_ALERT 2
#define WAITING_SERVER_ALERT 3

//#define OMOK_PORT 5252
#define OMOK_PORT 1234
@interface StartViewController ()

@end

@implementation StartViewController

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
    // Do any additional setup after loading the view.
}

-(IBAction)serverClick:(id)sender
{
	
    serverSock = socket( AF_INET, SOCK_STREAM, 0 );
    if(serverSock < 0)
	{
		[self error:@"error Socket"];
		return;
	}
    struct sockaddr_in sin;
    memset(&sin, 0, sizeof(sin));
    sin.sin_len = sizeof(sin);
    sin.sin_family = AF_INET; // or AF_INET6 (address family)
    sin.sin_port = htons(OMOK_PORT);
    sin.sin_addr.s_addr= INADDR_ANY;
	
	int bf = 1;
	setsockopt(serverSock, SOL_SOCKET, SO_REUSEADDR, (char *)&bf, (int)sizeof(bf));

    if(bind(serverSock, (struct sockaddr *)&sin, sizeof(sin))<0)
	{
		[self error:@"error bind"];
		return;
	}
    if(listen(serverSock, 50)<0)
	{
		close(serverSock);
		[self error:@"error listen"];
		return;
	}
    
    [self performSelectorInBackground:@selector(waitforClient) withObject:nil];
	
	alert1 = [[UIAlertView alloc] initWithTitle:@"기다리는중...." message:[NSString stringWithFormat:@"IP : %@", [self getIPAddress]] delegate:self cancelButtonTitle:@"취소" otherButtonTitles:nil];
	alert1.tag = WAITING_CLIENT_ALERT;
	[alert1 show];
	
}

-(void)waitforClient
{
    struct sockaddr_in peer_name;
    int socklen = sizeof(peer_name);
	int sock = accept(serverSock, (struct sockaddr*)&peer_name, &socklen);
	if(sock < 0) return;
	clientSocket = [[JBSocket alloc] initWithfd:sock];
	opNick = [clientSocket readString];
	[self performSelectorOnMainThread:@selector(findClient:) withObject:opNick waitUntilDone:NO];
}

-(void)findClient:(NSString *)nick
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"find Client!" message:nick delegate:self cancelButtonTitle:@"취소" otherButtonTitles:@"OK", nil];
	alert.tag = ACCEPT_CLIENT_ALERT;
	[alert show];
}

-(IBAction)clientClick:(id)sender
{
    int socketfd = socket( AF_INET, SOCK_STREAM, 0 );
    if(socketfd < 0)
	{
		[self error:@"error make socket"];
		return;
	}
	
    struct sockaddr_in serverAddress;
    bzero( &serverAddress, sizeof(serverAddress) );
    serverAddress.sin_family = AF_INET;
    serverAddress.sin_port = htons( OMOK_PORT );
    serverAddress.sin_addr.s_addr = inet_addr(ip.text.UTF8String);
	
    int r = connect(socketfd, (struct sockaddr*)&serverAddress, sizeof(serverAddress));
    if(r<0)
	{
		[self error:@"error connect"];
		return;
	}
	clientSocket = [[JBSocket alloc] initWithfd:socketfd];
	[clientSocket writeString:nick.text];
	[self performSelectorInBackground:@selector(waitServerAceept) withObject:nil];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Waiting Server!" message:@"Wait..." delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
	alert.tag = WAITING_SERVER_ALERT;
	[alert show];
	alert2 = alert;
}

-(void)waitServerAceept
{
	NSString *str = [clientSocket readString];
	[self performSelectorOnMainThread:@selector(closeAlert:) withObject:alert2 waitUntilDone:YES];
	if([str isEqualToString:@"YES"])
	{
		opNick = [clientSocket readString];
		isHost = -1;
		[self performSelectorOnMainThread:@selector(startGame) withObject:nil waitUntilDone:NO];
	}
	else
	{
		[self performSelectorOnMainThread:@selector(error:) withObject:@"거절당함 ㅠ" waitUntilDone:NO];
	}
}

-(void)closeAlert:(UIAlertView *)v
{
	[v dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (alertView.tag)
	{
		case ACCEPT_CLIENT_ALERT:
			if(buttonIndex == 1)
			{
				[clientSocket writeString:@"YES"];
				[clientSocket writeString:nick.text];
				//close(serverSock);
				[alert1 dismissWithClickedButtonIndex:0 animated:YES];
				isHost = serverSock;
				[self startGame];
			}
			else
			{
				[clientSocket writeString:@"NO"];
				[self performSelectorInBackground:@selector(waitforClient) withObject:nil];
			}
			break;
		case WAITING_CLIENT_ALERT:
//			close(serverSock);
			break;
	}
}

-(void)startGame
{
	[self performSegueWithIdentifier:@"StartGame" sender:self];
}

-(void)error:(NSString *)msg
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"error" message:msg delegate:self cancelButtonTitle:@"취소" otherButtonTitles:nil, nil];
	[alert show];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if([segue.identifier isEqualToString:@"StartGame"])
	{
        OmokViewController *view =[segue destinationViewController];
		[view setSock:clientSocket];
		[view setHost:isHost];
		[view setNickName:nick.text];
		[view setopNickName:opNick];
	}
}

- (NSString *)getIPAddress {
    
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    
                }
                
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
    
}


@end
