//
//  OmokView.m
//  SocketOmok
//
//  Created by 이재범 on 2014. 9. 14..
//  Copyright (c) 2014년 jb. All rights reserved.
//

#import "OmokView.h"

@implementation OmokView

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        self.backgroundColor = [UIColor colorWithRed:155/255. green:113/255. blue:53/255. alpha:1];
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    int i, j;
    CGContextRef con = UIGraphicsGetCurrentContext();
    CGFloat l = self.frame.size.width;
	
	CGFloat col[]={0, 0, 0, 1};
	CGContextSetStrokeColor(con, col);
	CGContextSetLineWidth(con, 1);
	
    for(i=0; i<19; i++)
    {
        CGContextMoveToPoint(con, l/38, l/19*i+l/38);
        CGContextAddLineToPoint(con, l/38*37, l/19*i+l/38);
        CGContextStrokePath(con);
        
        CGContextMoveToPoint(con, l/19*i+l/38, l/38);
        CGContextAddLineToPoint(con, l/19*i+l/38, l/38*37);
        CGContextStrokePath(con);
    }
    
    for(i=0; i<19; i++)
    {
        for(j=0; j<19; j++)
        {
			CGFloat cx = l/19*i+l/38, cy = l/19*j+l/38, r = l/38*5/6;
			if(map[i][j] == 1)
			{
				col[0] = col[1] = col[2] = 0;
				CGContextSetFillColor(con, col);
				CGContextFillEllipseInRect(con, CGRectMake(cx-r, cy-r, 2*r, 2*r));
			}
			else if(map[i][j] == 2)
			{
				col[0] = col[1] = col[2] = 1;
				CGContextSetFillColor(con, col);
				CGContextFillEllipseInRect(con, CGRectMake(cx-r, cy-r, 2*r, 2*r));
			}
		}
	}
	
	CGFloat cx = l/19*x+l/38, cy = l/19*y+l/38, r = l/38*5/6;
	
	col[0] = 1;
	col[1] = col[2] = 0;
	CGContextSetStrokeColor(con, col);
	CGContextSetLineWidth(con, 3);
	
	CGContextMoveToPoint(con, cx-r, cy-r);
	CGContextAddLineToPoint(con, cx+r, cy+r);
	CGContextStrokePath(con);
	
	CGContextMoveToPoint(con, cx-r, cy+r);
	CGContextAddLineToPoint(con, cx+r, cy-r);
	CGContextStrokePath(con);
	
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGFloat l = self.frame.size.height;
	x = [touch locationInView:self].x/(l/19);
	y = [touch locationInView:self].y/(l/19);
	[self setNeedsDisplay];
}

-(void)addStone:(int)x :(int)y :(int)Col
{
	map[x][y] = Col;
	[self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
}

-(int)getX{return x;}
-(int)getY{return y;}

@end
