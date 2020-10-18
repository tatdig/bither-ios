//  BitherEngine.m
//  bither-ios
//
//  Copyright 2014 http://Bither.net
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "BitherEngine.h"

static BitherEngine *bitherEngine;
static MKNetworkEngine *userNetworkEngine;
static MKNetworkEngine *statsNetworkEngine;
static MKNetworkEngine *bitcoinNetworkEngine;
static MKNetworkEngine *bcNetworkEngine;
static MKNetworkEngine *hdmNetworkEngine;
static MKNetworkEngine *blockChainEngine;
static MKNetworkEngine *chainBtcComEngine;
static MKNetworkEngine *blockchairEngine;
static MKNetworkEngine *bitherAndBtcComEngine;

@implementation BitherEngine
+ (BitherEngine *)instance {
    @synchronized (self) {
        if (bitherEngine == nil) {
            bitherEngine = [[self alloc] init];
            NSMutableDictionary *headerFields = [NSMutableDictionary dictionary];
            [headerFields setValue:@"application/json" forKey:@"Accept"];
            userNetworkEngine = [[MKNetworkEngine alloc] initWithHostName:@"www.tdcoincore.org" customHeaderFields:headerFields];
            statsNetworkEngine = [[MKNetworkEngine alloc] initWithHostName:@"www.tdcoincore.org" customHeaderFields:headerFields];
            bitcoinNetworkEngine = [[MKNetworkEngine alloc] initWithHostName:@"b.getcai.com" customHeaderFields:headerFields];
            bcNetworkEngine = [[MKNetworkEngine alloc]
                initWithHostName:@"www.tdcoincore.org" customHeaderFields:headerFields];
            hdmNetworkEngine = [[MKNetworkEngine alloc] initWithHostName:@"hdm.bither.net" customHeaderFields:headerFields];
            blockChainEngine = [[MKNetworkEngine alloc]
                initWithHostName:@"blockchain.info" customHeaderFields:headerFields];
            chainBtcComEngine = [[MKNetworkEngine alloc]
                initWithHostName:@"chain.api.btc.com" customHeaderFields:headerFields];
            blockchairEngine = [[MKNetworkEngine alloc]
            initWithHostName:@"api.blockchair.com" customHeaderFields:headerFields];
            bitherAndBtcComEngine = chainBtcComEngine;
        }
    }
    return bitherEngine;
}

- (MKNetworkEngine *)getUserNetworkEngine {
    return userNetworkEngine;
}

- (MKNetworkEngine *)getStatsNetworkEngine {
    return statsNetworkEngine;
}

- (MKNetworkEngine *)getBitcoinNetworkEngine {
    return bitcoinNetworkEngine;
}

- (MKNetworkEngine *)getBCNetworkEngine {
    return bcNetworkEngine;
}

- (MKNetworkEngine *)getHDMNetworkEngine {
    return hdmNetworkEngine;
}

- (MKNetworkEngine *)getBlockChainEngine {
    return blockChainEngine;
}

- (MKNetworkEngine *)getChainBtcComEngine {
    return chainBtcComEngine;
}

- (MKNetworkEngine *)getBlockchairEngine {
    return blockchairEngine;
}

- (MKNetworkEngine *)getBitherAndBtcComEngine {
    return bitherAndBtcComEngine;
}

- (NSArray *)getCookies {
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", userNetworkEngine.readonlyHostName]]];
    return cookies;
}

+ (MKNetworkEngine *)getNextBitherAndBtcComEngineWithFirstBitherAndBtcComEngine:(MKNetworkEngine *)first {
    MKNetworkEngine *current = [BitherEngine instance].getBitherAndBtcComEngine;
    MKNetworkEngine *next;
    NSMutableDictionary *headerFields = [NSMutableDictionary dictionary];
    [headerFields setValue:@"application/json" forKey:@"Accept"];
    if ([current.readonlyHostName isEqualToString:@"chain.api.btc.com"]) {
        next = [[MKNetworkEngine alloc] initWithHostName:@"www.tdcoincore.org" customHeaderFields:headerFields];
    } else if ([current.readonlyHostName isEqualToString:@"www.tdcoincore.org"]) {
        next = [[MKNetworkEngine alloc] initWithHostName:@"bc2.bithernet.com" customHeaderFields:headerFields];
    } else if ([current.readonlyHostName isEqualToString:@"bc2.bithernet.com"]) {
        next = [[MKNetworkEngine alloc] initWithHostName:@"bc3.bithernet.com" customHeaderFields:headerFields];
    } else {
        next = [[MKNetworkEngine alloc] initWithHostName:@"chain.api.btc.com" customHeaderFields:headerFields];
    }
    [[BitherEngine instance] setBitherAndBtcComEngine:next];
    return [next.readonlyHostName isEqualToString:first.readonlyHostName] ? NULL : next;
}

+ (MKNetworkEngine *)getNextBitherEngineWithFirstBitherEngine:(MKNetworkEngine *)first {
    MKNetworkEngine *current = [BitherEngine instance].getBCNetworkEngine;
    MKNetworkEngine *next;
    NSMutableDictionary *headerFields = [NSMutableDictionary dictionary];
    [headerFields setValue:@"application/json" forKey:@"Accept"];
    if ([current.readonlyHostName isEqualToString:@"www.tdcoincore.org"]) {
        next = [[MKNetworkEngine alloc] initWithHostName:@"bc2.bithernet.com" customHeaderFields:headerFields];
    } else if ([current.readonlyHostName isEqualToString:@"bc2.bithernet.com"]) {
        next = [[MKNetworkEngine alloc] initWithHostName:@"bc3.bithernet.com" customHeaderFields:headerFields];
    } else {
        next = [[MKNetworkEngine alloc] initWithHostName:@"chain.api.btc.com" customHeaderFields:headerFields];
    }
    [[BitherEngine instance] setBitherEngine:next];
    return [next.readonlyHostName isEqualToString:first.readonlyHostName] ? NULL : next;
}

- (void)setBitherAndBtcComEngine:(MKNetworkEngine *)engine {
    bitherAndBtcComEngine = engine;
}

- (void)setBitherEngine:(MKNetworkEngine *)engine {
    bcNetworkEngine = engine;
}

+ (MKNetworkEngine *)getNextBlockchairEngineWithFirstBlockchairEngine:(MKNetworkEngine *)first {
    MKNetworkEngine *current = [BitherEngine instance].getBlockchairEngine;
    MKNetworkEngine *next;
    NSMutableDictionary *headerFields = [NSMutableDictionary dictionary];
    [headerFields setValue:@"application/json" forKey:@"Accept"];
    if ([current.readonlyHostName isEqualToString:@"api.blockchair.com"]) {
        next = [[MKNetworkEngine alloc] initWithHostName:@"www.tdcoincore.org/blockchair" customHeaderFields:headerFields];
    } else {
        next = [[MKNetworkEngine alloc] initWithHostName:@"api.blockchair.com" customHeaderFields:headerFields];
    }
    [[BitherEngine instance] setBlockchairEngine:next];
    return [next.readonlyHostName isEqualToString:first.readonlyHostName] ? NULL : next;
}

- (void)setBlockchairEngine:(MKNetworkEngine *)engine {
    blockchairEngine = engine;
}

+ (BOOL)isBtcCom {
    return [[BitherEngine instance].getBitherAndBtcComEngine.readonlyHostName isEqualToString:@"chain.api.btc.com"];
}

- (void)setEngineCookie {
    [self setCookieOfDomain:statsNetworkEngine.readonlyHostName];
    [self setCookieOfDomain:bitcoinNetworkEngine.readonlyHostName];
}

- (void)setCookieOfDomain:(NSString *)domain {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookies = [cookieStorage cookiesForURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", userNetworkEngine.readonlyHostName]]];
    for (NSHTTPCookie *cookie in cookies) {
        NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
        [cookieProperties setObject:cookie.name forKey:NSHTTPCookieName];
        [cookieProperties setObject:cookie.value forKey:NSHTTPCookieValue];
        [cookieProperties setObject:domain forKey:NSHTTPCookieDomain];
        [cookieProperties setObject:domain forKey:NSHTTPCookieOriginURL];
        [cookieProperties setObject:cookie.path forKey:NSHTTPCookiePath];
        [cookieProperties setObject:[NSNumber numberWithInt:(int)cookie.version] forKey:NSHTTPCookieVersion];
        [cookieProperties setObject:cookie.expiresDate forKey:NSHTTPCookieExpires];
        NSHTTPCookie *newCookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
        [cookieStorage setCookie:newCookie];
    }
    NSArray *cookies1 = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", domain]]];
    NSLog(@"cook %@", cookies1);
}

@end
