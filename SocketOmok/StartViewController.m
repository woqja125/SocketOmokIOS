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

#define OMOK_PORT 5252
//#define OMOK_PORT 1234
@interface StartViewController ()

@end

@implementation StartViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	Ips = [[NSMutableArray alloc] init];
	Nicks = [[NSMutableArray alloc] init];
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
    sin.sin_family = AF_INET;
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
	
	broadcast = [[NSThread alloc] initWithTarget:self selector:@selector(broadcast:) object:nick.text];
	[broadcast start];
	
}

- (void)broadcast:(NSString *)data {
	while(![[NSThread currentThread] isCancelled])
	{
		[NSThread sleepForTimeInterval:5];
		int fd = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
		
		struct sockaddr_in addr4client;
		memset(&addr4client, 0, sizeof(addr4client));
		addr4client.sin_len = sizeof(addr4client);
		addr4client.sin_family = AF_INET;
		addr4client.sin_port = htons(OMOK_PORT);
		addr4client.sin_addr.s_addr = htonl(INADDR_BROADCAST);
		
		int yes = 1;
		if (setsockopt(fd, SOL_SOCKET, SO_BROADCAST, (void *)&yes, sizeof(yes)) == -1) {
			NSLog(@"Failure to set broadcast! : %d", errno);
		}
		
		const char *toSend = data.UTF8String;
		if (sendto(fd, toSend, [data length], 0, (struct sockaddr *)&addr4client, sizeof(addr4client)) == -1) {
			NSLog(@"Failure to send! : %d", errno);
		}
		close(fd);
	}
}

-(void)waitforClient
{
    struct sockaddr_in peer_name;
    unsigned socklen = sizeof(peer_name);
	int sock = accept(serverSock, (struct sockaddr*)&peer_name, &socklen);
	if(sock < 0) return;
	clientSocket = [[JBSocket alloc] initWithfd:sock];
	opNick = [clientSocket readString];
	[self performSelectorOnMainThread:@selector(findClient:) withObject:opNick waitUntilDone:NO];
}

-(void)findClient:(NSString *)nickname
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"find Client!" message:nickname delegate:self cancelButtonTitle:@"취소" otherButtonTitles:@"OK", nil];
	alert.tag = ACCEPT_CLIENT_ALERT;
	[alert show];
}

-(IBAction)refreshClick:(id)sender
{
	refreshbtn.enabled = NO;
	[Ips removeAllObjects];
	[Nicks removeAllObjects];
	[self performSelectorInBackground:@selector(listenForPackets) withObject:nil];
}

- (void)listenForPackets
{
	NSDate *st = [NSDate date];
	while(-[st timeIntervalSinceNow] <= 5)
	{
		int listeningSocket = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
		if (listeningSocket <= 0) {
			NSLog(@"Error: listenForPackets - socket() failed.");
			return;
		}
		
		struct sockaddr_in sockaddr;
		memset(&sockaddr, 0, sizeof(sockaddr));
		
		sockaddr.sin_len = sizeof(sockaddr);
		sockaddr.sin_family = AF_INET;
		sockaddr.sin_port = htons(OMOK_PORT);
		sockaddr.sin_addr.s_addr = htonl(INADDR_ANY);
		
		int status = bind(listeningSocket, (struct sockaddr *)&sockaddr, sizeof(sockaddr));
		if (status == -1) {
			close(listeningSocket);
			NSLog(@"Error: listenForPackets - bind() failed.");
			return;
		}
		
		// receive
		struct sockaddr_in receiveSockaddr;
		socklen_t receiveSockaddrLen = sizeof(receiveSockaddr);
		
		size_t bufSize = 9216;
		void *buf = malloc(bufSize);
		ssize_t result = recvfrom(listeningSocket, buf, bufSize, 0, (struct sockaddr *)&receiveSockaddr, &receiveSockaddrLen);
		
		NSData *data = nil;
	 
		if (result >= 0) {
			if ((size_t)result != bufSize) {
				buf = realloc(buf, result);
			}
			data = [NSData dataWithBytesNoCopy:buf length:result freeWhenDone:YES];
			
			char addrBuf[INET_ADDRSTRLEN];
			if (inet_ntop(AF_INET, &receiveSockaddr.sin_addr, addrBuf, (size_t)sizeof(addrBuf)) == NULL) {
				addrBuf[0] = '\0';
			}
			
			NSString *address = [NSString stringWithCString:addrBuf encoding:NSASCIIStringEncoding];
			NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[self didReceiveMessage:msg fromAddress:address];
			});
			
		} else {
			free(buf);
		}
		
		close(listeningSocket);
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		refreshbtn.enabled = true;
	});
}

- (void)didReceiveMessage:(NSString *)message fromAddress:(NSString *)address
{
	for(NSString *str in Ips)
		if([str isEqualToString:address])return;
	[Ips addObject:address];
	[Nicks addObject:message];
	[tv reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [Nicks count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *Id = @"ServerList";
	UITableViewCell *tc=[tableView dequeueReusableCellWithIdentifier:Id];
	if(tc == nil) tc = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:Id];
	int n = [indexPath row];
	tc.textLabel.text = [Nicks objectAtIndex:n];
	tc.detailTextLabel.text = [Ips objectAtIndex:n];
	return tc;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	ip.text = [Ips objectAtIndex:[indexPath row]];
	return indexPath;
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
			if(buttonIndex == 0)
			{
				[broadcast cancel];
				close(serverSock);
			}
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
		[view setSolo:false];
	}
	if([segue.identifier isEqualToString:@"StartSoloGame"])
	{
		OmokViewController *view =[segue destinationViewController];
		[view setSolo:true];
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
