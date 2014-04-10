//
//  tilog.m
//  TIKeyfob
//
//  Created by Nathaniel Symer on 4/9/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "tilog.h"

void tilog(NSString *text, ...) {
#if(TI_DEBUG)
    va_list args;
    va_start(args, text);
    NSLogv([NSString stringWithFormat:@"TIKeyfob: %@",text], args);
    va_end(args);
#endif
}