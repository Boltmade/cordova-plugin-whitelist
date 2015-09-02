/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "CDVNavigationWhitelistPlugin.h"
#import <Cordova/CDVViewController.h>

#pragma mark CDVNavigationWhitelistConfigParser

@interface CDVNavigationWhitelistConfigParser : NSObject <NSXMLParserDelegate> {}

@property (nonatomic, strong) NSMutableArray* whitelistHosts;

@end

@implementation CDVNavigationWhitelistConfigParser

@synthesize whitelistHosts;

- (id)init
{
    self = [super init];
    if (self != nil) {
        self.whitelistHosts = [[NSMutableArray alloc] initWithCapacity:30];
        [self.whitelistHosts addObject:@"file:///*"];
        [self.whitelistHosts addObject:@"content:///*"];
        [self.whitelistHosts addObject:@"data:///*"];
    }
    return self;
}

- (void)parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qualifiedName attributes:(NSDictionary*)attributeDict
{
    if ([elementName isEqualToString:@"allow-navigation"]) {
        [whitelistHosts addObject:attributeDict[@"href"]];
    }
}

- (void)parser:(NSXMLParser*)parser didEndElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qualifiedName
{
}

- (void)parser:(NSXMLParser*)parser parseErrorOccurred:(NSError*)parseError
{
    NSAssert(NO, @"config.xml parse error line %ld col %ld", (long)[parser lineNumber], (long)[parser columnNumber]);
}


@end

#pragma mark CDVNavigationWhitelistPlugin

@interface CDVNavigationWhitelistPlugin () {}
@property (nonatomic, strong) CDVWhitelist* whitelist;
@end

@implementation CDVNavigationWhitelistPlugin

@synthesize whitelist;

- (void)parseSettingsWithParser:(NSObject <NSXMLParserDelegate>*)delegate
{
    // read from config.xml in the app bundle
    NSString* path = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"xml"];

    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSAssert(NO, @"ERROR: config.xml does not exist. Please run cordova-ios/bin/cordova_plist_to_config_xml path/to/project.");
        return;
    }

    NSURL* url = [NSURL fileURLWithPath:path];

    NSXMLParser *configParser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    if (configParser == nil) {
        NSLog(@"Failed to initialize XML parser.");
        return;
    }
    [configParser setDelegate:((id < NSXMLParserDelegate >)delegate)];
    [configParser parse];
}

- (void)setViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[CDVViewController class]]) {
        CDVNavigationWhitelistConfigParser *whitelistConfigParser = [[CDVNavigationWhitelistConfigParser alloc] init];
        [self parseSettingsWithParser:whitelistConfigParser];
        self.whitelist = [[CDVWhitelist alloc] initWithArray:whitelistConfigParser.whitelistHosts];
    }
}

 - (BOOL)shouldOverrideLoadWithRequest:(NSURLRequest*)request navigationType:(int)type
 {
    NSURL *url = request.URL;
    if ([self.whitelist URLIsAllowed:url]) {
     return NO;
    } else {
      if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
      }
      return YES;
    }
 }

- (BOOL)shouldAllowNavigationToURL:(NSURL *)url
{
    return [self.whitelist URLIsAllowed:url];
}
@end
