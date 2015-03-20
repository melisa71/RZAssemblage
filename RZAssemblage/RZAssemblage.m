//
//  RZBaseAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblage+Private.h"
#import "NSIndexPath+RZAssemblage.h"
#import "RZAssemblageProtocols.h"
#import "RZAssemblageDefines.h"
#import "RZIndexPathSet.h"

@implementation RZAssemblage

@synthesize delegate = _delegate;

- (instancetype)initWithArray:(NSArray *)array representingObject:(id)representingObject;
{
    self = [super init];
    if ( self ) {
        _childrenStorage = [array isKindOfClass:[NSMutableArray class]] ? array : [array mutableCopy];
        [[_childrenStorage copy] enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
            id monitored = [self monitoredVersionOfObject:object];
            if ( monitored != object ) {
                [_childrenStorage replaceObjectAtIndex:idx withObject:monitored];
            }
        }];
    }
    return self;
}

- (instancetype)initWithArray:(NSArray *)array
{
    return [self initWithArray:array representingObject:[NSNull null]];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p - %@>", self.class, self, self.childrenStorage];
}

- (id)copyWithZone:(NSZone *)zone;
{
    RZAssemblage *copy = [[self class] allocWithZone:zone];

    NSMutableArray *children = [NSMutableArray arrayWithArray:self.childrenStorage];
    NSUInteger index = 0;
    for ( id object in self.childrenStorage ) {
        if ( [object conformsToProtocol:@protocol(RZAssemblage)] ) {
            id assemblageCopy = [object copy];
            [children replaceObjectAtIndex:index withObject:assemblageCopy];
        }
        index++;
    }
    copy->_childrenStorage = [children copy];
    return copy;
}

#pragma mark - <RZAssemblage>

- (NSMutableArray *)proxyArrayForIndexPath:(NSIndexPath *)indexPath;
{
    NSUInteger length = [indexPath length];

    NSMutableArray *proxy = nil;

    if ( length == 0 ) {
        proxy = [self mutableArrayValueForKey:@"children"];
    }
    else {
        id<RZAssemblage> assemblage = [self assemblageInChildrenAtIndex:[indexPath indexAtPosition:0]];
        proxy = [assemblage proxyArrayForIndexPath:[indexPath rz_indexPathByRemovingFirstIndex]];
    }
    return proxy;
}


- (NSUInteger)childCountAtIndexPath:(NSIndexPath *)indexPath;
{
    NSUInteger count = NSNotFound;
    NSUInteger length = [indexPath length];

    if ( length == 0 ) {
        count = self.countOfChildren;
    }
    else {
        id<RZAssemblage> assemblage = [self assemblageInChildrenAtIndex:[indexPath indexAtPosition:0]];
        NSAssert([assemblage conformsToProtocol:@protocol(RZAssemblage)], @"Invalid Index Path: %@", indexPath);
        count = [assemblage childCountAtIndexPath:[indexPath rz_indexPathByRemovingFirstIndex]];
    }
    return count;
}

- (id)childAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger length = [indexPath length];
    id object = nil;
    if ( length == 1 ) {
        object = [self objectInChildrenAtIndex:[indexPath indexAtPosition:0]];
    }
    else if ( length > 1 ) {
        id<RZAssemblage> assemblage = [self assemblageInChildrenAtIndex:[indexPath indexAtPosition:0]];
        RZRaize([assemblage conformsToProtocol:@protocol(RZAssemblage)], @"Invalid Index Path: %@", indexPath);
        object = [assemblage childAtIndexPath:[indexPath rz_indexPathByRemovingFirstIndex]];
    }
    else {
        object = [self representedObject];
    }
    return object;
}

#pragma mark - Batching

- (void)openBatchUpdate
{
    if ( self.updateCount == 0 ) {
        self.changeSet = [[RZAssemblageChangeSet alloc] init];
        self.changeSet.startingAssemblage = [self copy];
        if ( [self.delegate respondsToSelector:@selector(willBeginUpdatesForAssemblage:)] ) {
            [self.delegate willBeginUpdatesForAssemblage:self.changeSet.startingAssemblage];
        }
    }
    self.updateCount += 1;
}

- (void)closeBatchUpdate
{
    self.updateCount -= 1;
    if ( self.updateCount == 0 ) {
        RZAssemblageLog(@"Change:%@ -> %p:\n%@", self, self.delegate, self.changeSet);
        [self.delegate assemblage:self didEndUpdatesWithChangeSet:self.changeSet];
        self.changeSet = nil;
    }
}

#pragma mark - RZAssemblageDelegate

- (void)willBeginUpdatesForAssemblage:(id<RZAssemblage>)assemblage
{
    [self openBatchUpdate];
}

- (void)notifyObjectUpdate:(id)anObject
{
    NSParameterAssert(anObject);
    NSUInteger index = [self childrenIndexOfObject:anObject];
    RZAssemblageLog(@"%p:Update %@ at %zd", self, anObject, index);
    NSAssert(index != NSNotFound, @"Object is not part of assemblage");
    [self openBatchUpdate];
    [self.changeSet updateAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self closeBatchUpdate];
}

- (void)assemblage:(id<RZAssemblage>)assemblage didEndUpdatesWithChangeSet:(RZAssemblageChangeSet *)changeSet
{
    RZRaize(self.changeSet != nil, @"Must begin an update on the parent assemblage before mutating a child assemblage");
    NSUInteger assemblageIndex = [self childrenIndexOfObject:assemblage];
    [self.changeSet mergeChangeSet:changeSet withIndexPathTransform:^NSIndexPath *(NSIndexPath *indexPath) {
        return [indexPath rz_indexPathByPrependingIndex:assemblageIndex];
    }];
    [self closeBatchUpdate];
}

#pragma mark - Index Path Helpers

- (void)insertObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *proxy = [self proxyArrayForIndexPath:[indexPath indexPathByRemovingLastIndex]];
    [proxy insertObject:object atIndex:[indexPath rz_lastIndex]];
}

- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *proxy = [self proxyArrayForIndexPath:[indexPath indexPathByRemovingLastIndex]];
    [proxy removeObjectAtIndex:[indexPath rz_lastIndex]];
}

- (void)moveObjectAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSMutableArray *fproxy = [self proxyArrayForIndexPath:[fromIndexPath indexPathByRemovingLastIndex]];
    NSMutableArray *tproxy = [self proxyArrayForIndexPath:[toIndexPath indexPathByRemovingLastIndex]];

    NSObject *object = [fproxy objectAtIndex:[fromIndexPath rz_lastIndex]];
    [fproxy removeObjectAtIndex:[fromIndexPath rz_lastIndex]];
    [tproxy insertObject:object atIndex:[toIndexPath rz_lastIndex]];
}

@end

@implementation RZAssemblage (Protected)

- (NSUInteger)countOfChildren
{
    return self.childrenStorage.count;
}

- (id)objectInChildrenAtIndex:(NSUInteger)index
{
    id object = [self.childrenStorage objectAtIndex:index];
    if ( [object conformsToProtocol:@protocol(RZAssemblage)] ) {
        object = [object representedObject];
    }
    return object;
}

- (void)removeObjectFromChildrenAtIndex:(NSUInteger)index
{
    RZAssemblageLog(@"%p:Remove %@ at %zd", self, [self objectInChildrenAtIndex:index],  index);
    [self openBatchUpdate];
    [self.childrenStorage removeObjectAtIndex:index];
    [self.changeSet removeAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self closeBatchUpdate];
}

- (void)insertObject:(NSObject *)object inChildrenAtIndex:(NSUInteger)index
{
    RZAssemblageLog(@"%p:Insert %@ at %zd", self, object, index);
    NSParameterAssert(object);
    object = [self monitoredVersionOfObject:object];
    [self openBatchUpdate];
    [self.childrenStorage insertObject:object atIndex:index];
    [self.changeSet insertAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self closeBatchUpdate];
}

- (NSUInteger)childrenIndexOfObject:(id)object
{
    return [self.childrenStorage indexOfObject:object];
}

- (id)assemblageInChildrenAtIndex:(NSUInteger)index;
{
    return [self.childrenStorage objectAtIndex:index];
}

- (id)monitoredVersionOfObject:(id)anObject
{
    id monitored = anObject;
    if ( [anObject conformsToProtocol:@protocol(RZAssemblage)] ) {
        [(id<RZAssemblage>)anObject setDelegate:self];
    }
    return monitored;
}

@end

@implementation RZAssemblage (Legacy)

- (void)addObject:(id)object
{
    NSMutableArray *proxy = [self proxyArrayForIndexPath:nil];
    [proxy addObject:object];
}

- (void)insertObject:(id)object atIndex:(NSUInteger)index
{
    NSMutableArray *proxy = [self proxyArrayForIndexPath:nil];
    [proxy insertObject:object atIndex:index];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    NSMutableArray *proxy = [self proxyArrayForIndexPath:nil];
    [proxy removeObjectAtIndex:index];
}

- (void)removeLastObject
{
    NSMutableArray *proxy = [self proxyArrayForIndexPath:nil];
    [proxy removeLastObject];
}

- (id)objectAtIndex:(NSUInteger)index
{
    return [self childAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
}

@end
