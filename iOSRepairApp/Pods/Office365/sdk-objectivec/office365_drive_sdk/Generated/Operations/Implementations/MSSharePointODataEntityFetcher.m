/*******************************************************************************
 * Copyright (c) Microsoft Open Technologies, Inc.
 * All Rights Reserved
 * See License.txt in the project root for license information.
 ******************************************************************************/

#import "MSSharePointODataEntityFetcher.h"
#import "MSSharePointODataOperations.h"
#import "MSSharePointBaseODataContainerHelper.h"

@interface MSSharePointODataEntityFetcher()

@property Class entityClass;
@property MSSharePointODataExecutable* operations;

@end

/**
* The implementation file for type MSSharePointODataEntityFetcher.
*/

@implementation MSSharePointODataEntityFetcher

@synthesize Parent;
@synthesize UrlComponent;

-(id)initWith:(NSString *)urlComponent :(id<MSSharePointODataExecutable>)parent : (Class) entityClass{
    self.UrlComponent = urlComponent;
    self.Parent = parent;
    self.operations = [[MSSharePointODataOperations alloc] initOperationWithUrl:@"" Parent:parent];
    self.entityClass = entityClass;
    return self;
}

-(NSURLSessionDataTask*) oDataExecute:(id<MSODataURL>)path :(NSData *)content :(MSHttpVerb)verb :(void (^)(id<MSResponse>, NSError *))callback{
    [path appendPathComponent:self.UrlComponent];
    [MSSharePointBaseODataContainerHelper addCustomParametersToODataURL:path :[self getCustomParameters]:[self getResolver]];

    return [self.Parent oDataExecute:path :content :verb :^(id<MSResponse> r, NSError *e) {
        callback(r,e);
    }];
}

-(NSURLSessionDataTask*) update:(id)updatedEntity : (void (^)(id, NSError *))callback{
    NSString *payload = [[[self getResolver] getJsonSerializer]serialize:updatedEntity];
    
    return [self oDataExecute:[[self getResolver] createODataURL] :[payload dataUsingEncoding:NSUTF8StringEncoding] : PATCH : ^(id<MSResponse> r, NSError *e) {
        callback(updatedEntity, e);
    }];
}

-(NSURLSessionDataTask*) delete : (void (^)(id,NSError *))callback{
    return [self oDataExecute:[[self getResolver] createODataURL]  :nil :DELETE :^(id<MSResponse> r, NSError *e) {
        callback(r, e);
    }];
}

-(NSURLSessionDataTask *)execute:(void (^)(id, NSError *))callback{
    return [self oDataExecute:[[self getResolver] createODataURL]  :nil :GET :^(id<MSResponse> r, NSError *e) {
        if (e == nil) {
            id entity = [[[self getResolver] getJsonSerializer] deserialize:[r getData] :self.entityClass];
            
            callback(entity, e);
        }
        else callback(nil, e);
    }];
}

-(id<MSDependencyResolver>) getResolver{
    return [self.Parent getResolver];
}

@end
