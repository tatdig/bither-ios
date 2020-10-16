//  BitherApi.m
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

#import "BitherApi.h"
#import "MarketUtil.h"
#import "GroupFileUtil.h"
#import "AFNetworking.h"
#import "AdUtil.h"
#import "SplitCoinUtil.h"
#import "BitherEngine.h"

static BitherApi *piApi;
#define kImgEn @"img_en"
#define kImgZhCN @"img_zh_CN"
#define kImgZhTW @"img_zh_TW"

@interface BitherApi ()
@property (nonatomic, assign) int isLoadImageNum;
@end

@implementation BitherApi

+ (BitherApi *)instance {
    @synchronized (self) {
        
        if (piApi == nil) {
            piApi = [[self alloc] init];
        }
    }
    return piApi;
}

- (void)getSpvBlock:(DictResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback {
    [self  get:BITHER_GET_ONE_SPVBLOCK_API withParams:nil networkType:BitherBC completed:^(MKNetworkOperation *completedOperation) {
        if (![StringUtil isEmpty:completedOperation.responseString]) {
            NSLog(@"spv: %s", [completedOperation.responseString UTF8String]);
            NSDictionary *dict = [completedOperation responseJSON];
            if (callback) {
                callback(dict);
            }
        }
    } andErrorCallback:^(NSError *error) {
        if (errorCallback) {
            errorCallback(error);
        }
    }];
    
}

-(void)getSpvBlockByBlockChain:(DictResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback {
    [self execGetBlockChain:BLOCKCHAIN_INFO_GET_LASTST_BLOCK withParams:nil networkType:BlockChain completed:^(MKNetworkOperation *completedOperation) {
        if (![StringUtil isEmpty:completedOperation.responseString]) {
            NSDictionary *dict = [completedOperation responseJSON];
            int latestHeight = [[dict objectForKey:@"height"] intValue];
            int height = 0;
            if (latestHeight % 1008 !=0){
                height = latestHeight - (latestHeight%1008);
            }else {
                height = latestHeight;
            }
            [self execGetBlockChain:[NSString stringWithFormat:BLOCKCHAIN_GET_ONE_SPVBLOCK_API, height] withParams:nil networkType:BlockChain completed:^(MKNetworkOperation *completedOpera) {
                NSLog(@"blockchain spv: %s", [completedOpera.responseString UTF8String]);
                NSDictionary *dic = [completedOpera responseJSON];
                NSDictionary * block = [[dic objectForKey:@"blocks"] objectAtIndex:0];
                if (callback) {
                    callback(block);
                }
            } andErrorCallback:^(NSError *error) {
                if (errorCallback) {
                    errorCallback(error);
                }
            } ssl:NO];
        }
    } andErrorCallback:^(NSError *error) {
        if (errorCallback) {
            errorCallback(error);
        }
    } ssl:NO];
}

-(void)getSpvBlockByBtcCom:(DictResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback {
    [self execGetBlockChain:BTC_COM_GET_LASTST_BLOCK withParams:nil networkType:ChainBtcCom completed:^(MKNetworkOperation *completedOperation) {
        if (![StringUtil isEmpty:completedOperation.responseString]) {
            NSDictionary *dict = [completedOperation responseJSON];
            NSDictionary *data = [self getBtcComData:dict andErrorCallBack:errorCallback];
            if (!data) {
                return;
            }
            int latestHeight = [[data objectForKey:@"height"] intValue];
            int height = 0;
            if (latestHeight % 1008 !=0){
                height = latestHeight - (latestHeight%1008);
            }else {
                height = latestHeight;
            }
            [self execGetBlockChain:[NSString stringWithFormat:BTC_COM_GET_ONE_SPVBLOCK_API, height] withParams:nil networkType:ChainBtcCom completed:^(MKNetworkOperation *completedOpera) {
                NSLog(@"blockchain spv: %s", [completedOpera.responseString UTF8String]);
                NSDictionary *dic = [completedOpera responseJSON];
                NSDictionary *block = [self getBtcComData:dic andErrorCallBack:errorCallback];
                if (!block) {
                    return;
                }
                if (callback) {
                    callback(block);
                }
            } andErrorCallback:^(NSError *error) {
                if (errorCallback) {
                    errorCallback(error);
                }
            } ssl:NO];
        } else {
            if (errorCallback) {
                errorCallback([[NSError alloc] initWithDomain:@"btc com response error" code:400 userInfo:NULL]);
            }
        }
    } andErrorCallback:^(NSError *error) {
        if (errorCallback) {
            errorCallback(error);
        }
    } ssl:NO];
}

- (NSDictionary *)getBtcComData:(NSDictionary *)dict andErrorCallBack:(ErrorHandler)errorCallback {
    if (!dict) {
        if (errorCallback) {
            errorCallback([[NSError alloc] initWithDomain:@"btc com response error" code:400 userInfo:NULL]);
        }
        return NULL;
    }
    if ([dict[@"err_no"] intValue] != 0) {
        NSString *errMsg = [dict[@"err_msg"] stringValue];
        if (errMsg) {
            errMsg = @"btc com response error";
        }
        if (errorCallback) {
            errorCallback([[NSError alloc] initWithDomain:errMsg code:400 userInfo:NULL]);
        }
        return NULL;
    }
    NSDictionary *dataDict = dict[@"data"];
    if (!dataDict) {
        if (errorCallback) {
            errorCallback([[NSError alloc] initWithDomain:@"btc com response error" code:400 userInfo:NULL]);
        }
    }
    return dataDict;
}

- (void)getInSignaturesApi:(NSString *)address fromBlock:(int)blockNo callback:(IdResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback {
    NSString *url = [NSString stringWithFormat:BITHER_IN_SIGNATURES_API, address, blockNo];
    [self          get:url withParams:nil networkType:BitherBitcoin completed:^(MKNetworkOperation *completedOperation) {
        if (callback) {
            callback(completedOperation.responseString);
        }
        
    } andErrorCallback:^(NSError *error) {
        if (errorCallback) {
            errorCallback(error);
        }
    }];
    
}

- (void)getExchangeTrend:(MarketType)marketType callback:(ArrayResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback {
    NSString *url = [NSString stringWithFormat:BITHER_TREND_URL, [GroupUtil getMarketValue:marketType]];
    [self          get:url withParams:nil networkType:BitherStats completed:^(MKNetworkOperation *completedOperation) {
        if (callback) {
            callback(completedOperation.responseJSON);
        }
        
    } andErrorCallback:^(NSError *error) {
        if (errorCallback) {
            errorCallback(error);
        }
    }];
}

- (void)getExchangeDepth:(MarketType)marketType callback:(ArrayResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback {
    //[];
}
#pragma mark - getTransactionApiFromBlockChain
- (void)getTransactionApiFromBlockChain:(NSString *)address withPage:(int)page callback:(DictResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback{
    NSString *singeTxUrl = [NSString stringWithFormat:BLOCK_INFO_ADDRESS_TX_URL,address,page];
    //NSLog(@"%@",singeTxUrl);
    [self getBlockChainTx:singeTxUrl withParams:nil networkType:BlockChain completed:^(MKNetworkOperation *completedOperation) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            DDLogDebug(@"api response:%@", completedOperation.responseString);
            if (![StringUtil isEmpty:completedOperation.responseString]) {
                NSDictionary *dict = completedOperation.responseJSON;
                if (callback) {
                    callback(dict);
                }
            }
        });
        
    } andErrorCallback:^(NSError *error) {
        if (errorCallback) {
            errorCallback(error);
        }
        
    } ssl:NO];
    
}
#pragma mark - getblockHeightApiFromBlockChain
- (void)getblockHeightApiFromBlockChain:(NSString *)address  callback:(DictResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback{
    //NSLog(@"ever Address :%@",address);
    NSString *blockHeightUrl = @"latestblock";
    [self getBlockChainBh:blockHeightUrl withParams:@{@"address": address} networkType:BlockChain completed:^(MKNetworkOperation *completedOperation) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            DDLogDebug(@"api response:%@", completedOperation.responseString);
            if (![StringUtil isEmpty:completedOperation.responseString]) {
                NSDictionary *dict = completedOperation.responseJSON;
                if (callback) {
                    callback(dict);
                }
            }
        });
        
    } andErrorCallback:^(NSError *error) {
        if (errorCallback) {
            errorCallback(error);
        }
        
        
    } ssl:NO];
    
}
#pragma mark - getTransactionApiFrom bither.net
- (void)getTransactionApi:(NSString *)address withPage:(int)page callback:(DictResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback; {
    DDLogDebug(@"get %@ tx page %d from api", address, page);
    NSString *url = [NSString stringWithFormat:BC_ADDRESS_TX_URL, address, page];
    [self          get:url withParams:nil networkType:BitherBC completed:^(MKNetworkOperation *completedOperation) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            DDLogDebug(@"api response:%@", completedOperation.responseString);
            if (![StringUtil isEmpty:completedOperation.responseString]) {
                NSDictionary *dict = completedOperation.responseJSON;
                if (callback) {
                    callback(dict);
                }
            }
        });
    } andErrorCallback:^(NSError *error) {
        if (errorCallback) {
            errorCallback(error);
        }
    }];
}

- (void)getMyTransactionApi:(NSString *)address callback:(DictResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback {
    NSString *url = [NSString stringWithFormat:BC_ADDRESS_STAT_URL, address];
    [self          get:url withParams:nil networkType:BitherBC completed:^(MKNetworkOperation *completedOperation) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            DDLogDebug(@"api response:%@", completedOperation.responseString);
            if (![StringUtil isEmpty:completedOperation.responseString]) {
                NSDictionary *dict = completedOperation.responseJSON;
                if (callback) {
                    callback(dict);
                }
            }
        });
        
    } andErrorCallback:^(NSError *error) {
        if (errorCallback) {
            errorCallback(error);
        }
    }];
}

- (void)queryAddress:(NSString *)addressesStr callback:(DictResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback {
    [self queryAddress:addressesStr firstEngine:[[BitherEngine instance] getBitherAndBtcComEngine] requestCount:1 callback:callback andErrorCallBack:errorCallback];
}

- (void)queryAddress:(NSString *)addressesStr firstEngine:(MKNetworkEngine *)firstEngine requestCount:(int)requestCount callback:(DictResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback {
    NSString *url = [NSString stringWithFormat:BitherEngine.isBtcCom ? BTC_COM_ADDRESSES_URL : BC_ADDRESSES_URL, addressesStr];
    [self get:url withParams:nil networkType:BitherAndBtcCom completed:^(MKNetworkOperation *completedOperation) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            DDLogDebug(@"api response:%@", completedOperation.responseString);
            if (![StringUtil isEmpty:completedOperation.responseString]) {
                NSDictionary *dict = completedOperation.responseJSON;
                if (callback) {
                    callback(dict);
                }
            }
        });
    } andErrorCallback:^(NSError *error) {
        [self handleError:error firstEngine:firstEngine requestCount:requestCount retry:^(int requestCount) {
            [self queryAddress:addressesStr firstEngine:firstEngine requestCount:requestCount callback:callback andErrorCallBack:errorCallback];
        } andErrorCallBack:^{
            if (errorCallback) {
                errorCallback(error);
            }
        }];
    }];
}

- (void)queryAddressUnspent:(NSString *)address withPage:(int)page callback:(DictResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback {
    [self queryAddressUnspent:address withPage:page firstEngine:[[BitherEngine instance] getBitherAndBtcComEngine] requestCount:1 callback:callback andErrorCallBack:errorCallback];
}

- (void)queryAddressUnspent:(NSString *)address  withPage:(int)page firstEngine:(MKNetworkEngine *)firstEngine requestCount:(int)requestCount callback:(DictResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback {
    NSString *url = [NSString stringWithFormat:BitherEngine.isBtcCom ? BTC_COM_ADDRESS_UNSPENT_URL : BC_ADDRESS_UNSPENT_URL, address];
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"page"] = @(page);
    [self get:url withParams:dict networkType:BitherAndBtcCom completed:^(MKNetworkOperation *completedOperation) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            DDLogDebug(@"api response:%@", completedOperation.responseString);
            if (![StringUtil isEmpty:completedOperation.responseString]) {
                NSDictionary *dict = completedOperation.responseJSON;
                if (callback) {
                    callback(dict);
                }
            }
        });
    } andErrorCallback:^(NSError *error) {
        [self handleError:error firstEngine:firstEngine requestCount:requestCount retry:^(int requestCount) {
            [self queryAddressUnspent:address withPage:page firstEngine:firstEngine requestCount:requestCount callback:callback andErrorCallBack:errorCallback];
        } andErrorCallBack:^{
            if (errorCallback) {
                errorCallback(error);
            }
        }];
    }];
}

- (void)getUnspentTxs:(NSString *)txHashs callback:(DictResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback {
    [self getUnspentTxs:txHashs firstEngine:[[BitherEngine instance] getBCNetworkEngine] requestCount:1 callback:callback andErrorCallBack:errorCallback];
}

- (void)getUnspentTxs:(NSString *)txHashs firstEngine:(MKNetworkEngine *)firstEngine requestCount:(int)requestCount callback:(DictResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback {
    NSString *url = [NSString stringWithFormat:BC_ADDRESS_UNSPENT_TXS_URL, txHashs];
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"verbose"] = @(3);
    [self get:url withParams:dict networkType:BitherBC completed:^(MKNetworkOperation *completedOperation) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            DDLogDebug(@"api response:%@", completedOperation.responseString);
            if (![StringUtil isEmpty:completedOperation.responseString]) {
                NSDictionary *dict = completedOperation.responseJSON;
                if (callback) {
                    callback(dict);
                }
            }
        });
    } andErrorCallback:^(NSError *error) {
        [self handleBcError:error firstEngine:firstEngine requestCount:requestCount retry:^(int requestCount) {
            [self getUnspentTxs:txHashs firstEngine:firstEngine requestCount:requestCount callback:callback andErrorCallBack:errorCallback];
        } andErrorCallBack:^{
            if (errorCallback) {
                errorCallback(error);
            }
        }];
    }];
}

- (void)getExchangeTicker:(VoidBlock)callback andErrorCallBack:(ErrorHandler)errorCallback {
    [self          get:BITHER_EXCHANGE_TICKER withParams:nil networkType:BitherStats completed:^(MKNetworkOperation *completedOperation) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            if (![StringUtil isEmpty:completedOperation.responseString]) {
                [GroupFileUtil setTicker:completedOperation.responseString];
                NSDictionary *dict = completedOperation.responseJSON;
                [MarketUtil handlerResult:dict];
                
                if (callback) {
                    callback();
                }
            }
            
        });
    } andErrorCallback:^(NSError *error) {
        if (errorCallback) {
            errorCallback(error);
        }
        
    }];
    
}

- (void)uploadCrash:(NSString *)data callback:(DictResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[@"error_msg"] = data;
    [self         post:BITHER_ERROR_API withParams:dict networkType:BitherUser completed:^(MKNetworkOperation *completedOperation) {
        if (callback) {
            callback(nil);
        }
    } andErrorCallBack:^(NSError *error) {
        if (errorCallback) {
            errorCallback(error);
        }
    }];
}

- (void)handleBcError:(NSError *)error firstEngine:(MKNetworkEngine *)firstEngine requestCount:(int)requestCount retry:(RetryBlock)retry andErrorCallBack:(VoidBlock)errorCallback {
    if (requestCount > kTIMEOUT_REREQUEST_CNT) {
        if ([BitherEngine getNextBitherEngineWithFirstBitherEngine:firstEngine]) {
            if (retry) {
                retry(requestCount);
            }
        } else{
            if (errorCallback) {
                errorCallback();
            }
        }
    } else {
        [NSThread sleepForTimeInterval:kTIMEOUT_REREQUEST_DELAY * requestCount];
        if (retry) {
            retry(requestCount + 1);
        }
    }
}

- (void)handleError:(NSError *)error firstEngine:(MKNetworkEngine *)firstEngine requestCount:(int)requestCount retry:(RetryBlock)retry andErrorCallBack:(VoidBlock)errorCallback {
    if (requestCount > kTIMEOUT_REREQUEST_CNT) {
        if ([BitherEngine getNextBitherAndBtcComEngineWithFirstBitherAndBtcComEngine:firstEngine]) {
            if (retry) {
                retry(requestCount);
            }
        } else{
            if (errorCallback) {
                errorCallback();
            }
        }
    } else {
        [NSThread sleepForTimeInterval:kTIMEOUT_REREQUEST_DELAY * requestCount];
        if (retry) {
            retry(requestCount + 1);
        }
    }
}

- (void)queryStatsDynamicFeeBaseCallback:(UInt64ResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback {
    NSString *url = BC_Q_STATS_DYNAMIC_FEE;
    [self get:url withParams:nil networkType:BitherBC completed:^(MKNetworkOperation *completedOperation) {
        if (![StringUtil isEmpty:completedOperation.responseString]) {
            NSDictionary *dict = completedOperation.responseJSON;
            if (dict && dict[@"fee_base"]) {
                uint64_t feeBase = [[dict objectForKey:@"fee_base"] unsignedLongValue];
                if (feeBase > 0 && callback) {
                    callback(feeBase);
                    return;
                }
            }
        }
        if (errorCallback) {
            errorCallback([[NSError alloc] initWithDomain:@"data error" code:400 userInfo:NULL]);
        }
    } andErrorCallback:^(NSError *error) {
        if (errorCallback) {
            errorCallback(error);
        }
    }];
}

#pragma mark - Ad api

- (void)getAdApi {
    NSString *url = @"https://bitpie.com/bither/bither_ad.json";
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager.requestSerializer setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    self.isLoadImageNum = 0;
    
    [manager GET:url parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:nil];
            if ([AdUtil isDownloadImageForNewAdDic:responseDic]) {
                [[BitherApi instance] getAdImageWithResponseDic:responseDic imageKey:kImgEn];
                [[BitherApi instance] getAdImageWithResponseDic:responseDic imageKey:kImgZhCN];
                [[BitherApi instance] getAdImageWithResponseDic:responseDic imageKey:kImgZhTW];
            }
        });
    } failure:nil];
}

- (void)getHasSplitCoinAddress:(NSString *)address splitCoin:(SplitCoin)splitCoin callback:(DictResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback {
    NSString *url = [NSString stringWithFormat:SPLIT_HAS_ADDRESS,[SplitCoinUtil getPathCoinCodee:splitCoin],address];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:url parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:nil];
        if (callback) {
            callback(responseDic);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (errorCallback) {
            errorCallback(error);
        }
    }];
}

- (void)getBcdPreBlockHashCallback:(DictResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback {
    NSString *urlStr = BCD_PREBLOCKHASH;
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:urlStr parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:nil];
        if (callback) {
            callback(responseDic);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (errorCallback) {
            errorCallback(error);
        }
    }];
}

- (void)postSplitCoinBroadcast:(BTTx *)tx splitCoin:(SplitCoin)splitCoin callback:(DictResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback {
    NSDictionary *dict;
    if(splitCoin == SplitBCD) {
        dict = @{@"raw_tx": [NSString hexWithData:tx.bcdToData]};
    }else{
        dict = @{@"raw_tx": [NSString hexWithData:tx.toData]};
    }

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html", @"text/plain", nil];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager.requestSerializer setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    NSString *urlStr = [NSString stringWithFormat:SPLIT_BROADCAST, [SplitCoinUtil getPathCoinCodee:splitCoin]];
    [manager POST:urlStr parameters:dict headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *responseDic = responseObject;
        if (callback) {
            callback(responseDic);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (errorCallback) {
            errorCallback(error);
        }
    }];
}

- (void)getAdImageWithResponseDic:(NSDictionary *)responseDic imageKey:(NSString *)imageKey {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    NSURL *URL = [NSURL URLWithString:responseDic[imageKey]];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    NSString *imageName = [NSString stringWithFormat:@"%@%@.png", imageKey, [self getNowTime]];
    NSString *imgPath = [AdUtil createCacheImgPathForFileName:imageKey];
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@", imgPath]];
        return [documentsDirectoryURL URLByAppendingPathComponent:imageName];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        self.isLoadImageNum += 1;
        if (self.isLoadImageNum == 3) {
            NSString *adPath = [AdUtil createCacheAdDicPath];
            [responseDic writeToFile:adPath atomically:YES];
        }
    }];
    [downloadTask resume];
}

- (NSString *)getNowTime {
    NSDate *nowDate = [NSDate date];
    NSString *timeSp = [NSString stringWithFormat:@"%d",(int)[nowDate timeIntervalSince1970]];
    return timeSp;
}


//#pragma mark - hdm api
//- (void)getHDMPasswordRandomWithHDMBid:(NSString *) hdmBid callback:(IdResponseBlock) callback andErrorCallBack:(ErrorHandler)errorCallback;{
//    [self get:[NSString stringWithFormat:@"api/v1/%@/hdm/password", hdmBid] withParams:nil networkType:BitherHDM completed:^(MKNetworkOperation *completedOperation) {
//        NSNumber *random = @([completedOperation.responseString longLongValue]);
//        NSLog(@"hdm password random:%@", random);
//        if (callback != nil) {
//            callback(random);
//        }
//    } andErrorCallback:^(NSOperation *errorOp, NSError *error) {
//        if (errorCallback) {
//            errorCallback(errorOp, error);
//        }
//    } ssl:YES];
//}
//
////- (void)changeHDMPasswordWithHDMBid:(NSString *)hdmBid andPassword:(NSString *)password
////                       andSignature:(NSString *)signature andHotAddress:(NSString *)hotAddress
////                           callback:(VoidResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback; {
////    NSDictionary *params = @{@"password" : [[password hexToData] base64EncodedString], @"signature" : signature,
////            @"hot_address" : hotAddress};
////    [self post:[NSString stringWithFormat:@"api/v1/%@/hdm/password",hdmBid] withParams:params networkType:BitherHDM completed:^(MKNetworkOperation *completedOperation) {
////        NSDictionary *dict = completedOperation.responseJSON;
////        if ([dict[@"result"] isEqualToString:@"ok"] && callback != nil) {
////            callback();
////        }
////    } andErrorCallBack:^(NSOperation *errorOp, NSError *error) {
////        if (errorCallback) {
////            errorCallback(errorOp, error);
////        }
////    } ssl:YES];
////};
////
////- (void)createHDMAddressWithHDMBid:(NSString *)hdmBid andPassword:(NSString *)password start:(int)start end:(int)end
////                           pubHots:(NSArray *) pubHots pubColds:(NSArray *)pubColds
////                          callback:(ArrayResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback; {
////    NSDictionary *params = @{@"password" : [[password hexToData] base64EncodedString], @"start" : @(start), @"end": @(end),
////            @"pub_hot": [self connect:pubHots], @"pub_cold": [self connect:pubColds]};
////    [self post:[NSString stringWithFormat:@"api/v1/%@/hdm/address/create", hdmBid] withParams:params networkType:BitherHDM completed:^(MKNetworkOperation *completedOperation) {
////        NSArray *pubRemotes = [self split:completedOperation.responseString];
////        if (callback != nil) {
////            callback(pubRemotes);
////        }
////    } andErrorCallBack:^(NSOperation *errorOp, NSError *error) {
////        if (errorCallback) {
////            errorCallback(errorOp, error);
////        }
////    } ssl:YES];
////}
////
////- (void)signatureByRemoteWithHDMBid:(NSString *)hdmBid andPassword:(NSString *)password andUnsignHash:(NSData *)unsignHash
////                           callback:(IdResponseBlock) callback andErrorCallBack:(ErrorHandler)errorCallback;{
////    NSDictionary *params = @{@"password" : [[password hexToData] base64EncodedString], @"unsign": [unsignHash base64EncodedString]};
////    [self post:[NSString stringWithFormat:@""] withParams:params networkType:BitherHDM completed:^(MKNetworkOperation *completedOperation) {
////        if (callback != nil) {
////            callback(completedOperation.responseString);
////        }
////    } andErrorCallBack:^(NSOperation *errorOp, NSError *error) {
////        if (errorCallback) {
////            errorCallback(errorOp, error);
////        }
////    } ssl:YES];
////}
////
////- (void)recoverHDMAddressWithHDMBid:(NSString *)hdmBid andPassword:(NSString *)password andSignature:(NSString *)signature
////                           callback:(DictResponseBlock)callback andErrorCallBack:(ErrorHandler)errorCallback; {
////    NSDictionary *params = @{@"password" : [[password hexToData] base64EncodedString], @"signature" : signature};
////    [self post:[NSString stringWithFormat:@""] withParams:params networkType:BitherHDM completed:^(MKNetworkOperation *completedOperation) {
////        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:completedOperation.responseJSON];
////        dict[@"pub_hot"] = [self split:dict[@"pub_hot"]];
////        dict[@"pub_cold"] = [self split:dict[@"pub_cold"]];
////        dict[@"pub_server"] = [self split:dict[@"pub_server"]];
////        if (callback != nil) {
////            callback(dict);
////        }
////    } andErrorCallBack:^(NSOperation *errorOp, NSError *error) {
////        if (errorCallback) {
////            errorCallback(errorOp, error);
////        }
////    } ssl:YES];
////}

//- (NSString *)connect:(NSArray *)dataList;{
//    NSMutableData *result = [NSMutableData secureData];
//    for (NSData *each in dataList) {
//        [result appendUInt8:(uint8_t) each.length];
//        [result appendData:each];
//    }
//    return [result base64EncodedString];
//}
//
//- (NSArray *)split:(NSString *)str; {
//    NSData *data = [NSData dataFromBase64String:str];
//    NSMutableArray *result = [NSMutableArray new];
//    NSUInteger index = 0;
//    while (str.length > index) {
//        uint8_t l = [data UInt8AtOffset:index];
//        NSData *each = [data dataAtOffset:index + 1 length:&l];
//        index += l + 1;
//        [result addObject:each];
//    }
//    return result;
//}
//
//- (NSError *)formatHDMErrorWithOP:(MKNetworkOperation *)errorOp andError:(NSError *)error;{
//    return nil;
//}
@end
