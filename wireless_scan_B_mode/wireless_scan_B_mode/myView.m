//
//  myView.m
//  wireless_scan_B_mode
//
//  Created by wong on 15/11/19.
//  Copyright © 2015年 lepumedical. All rights reserved.
//


#import "myView.h"

@implementation myView

@synthesize lineCount;
@synthesize scale;
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    //获得处理的上下文
    
    CGContextRef
    context = UIGraphicsGetCurrentContext();
    
    //指定直线样式
    
    CGContextSetLineCap(context,
                        kCGLineCapSquare);
    
    //直线宽度
    
    CGContextSetLineWidth(context,
                          3.0);
    
    //设置颜色
    
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    //开始绘制
    
    CGContextBeginPath(context);
    
    //画笔移动到点(,)
    
    CGContextMoveToPoint(context,
                         rect.size.width-2, 0);
    
    //下一点
    
    CGContextAddLineToPoint(context,
                            rect.size.width-2, rect.size.height);
    
    
    float totalheight = 480.0*scale;
    float fivemmheight = (float)(rect.size.height) / totalheight * 5.0;
    float curheight = 1.0;
    bool bLong = true;
    while (curheight <= rect.size.height) {
        if (bLong) {
            CGContextMoveToPoint(context,
                                 rect.size.width-10, curheight);
        } else {
            CGContextMoveToPoint(context,
                                 rect.size.width-6, curheight);
        }
        bLong = !bLong;
        
        CGContextAddLineToPoint(context,
                                rect.size.width-5, curheight);
        curheight += fivemmheight;
    }
    
    CGContextStrokePath(context);
    
    
    
    
}


@end
