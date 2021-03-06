//
//  RZArrayAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 3/21/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZArrayAssemblage.h"
#import "RZAssemblage+Private.h"

NSString *const RZAssemblageUpdateKey = @"RZAssemblageUpdateKey";
static char RZAssemblageUpdateContext;

@implementation RZArrayAssemblage

+ (BOOL)shouldObserveContents
{
    return YES;
}

- (instancetype)initWithArray:(NSArray *)array representingObject:(id)representingObject;
{
    self = [super init];
    if ( self ) {
        self.representedObject = representingObject;
        _childrenStorage = [array isKindOfClass:[NSMutableArray class]] ? array : [array mutableCopy];
        [[_childrenStorage copy] enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
            [self addMonitorsForObject:object];
        }];
    }
    return self;
}

- (instancetype)initWithArray:(NSArray *)array
{
    return [self initWithArray:array representingObject:nil];
}

- (void)dealloc
{
    for ( NSObject *object in _childrenStorage ) {
        [self removeMonitorsForObject:object];
    }
    if ( _representedObject ) {
        [self removeMonitorsForObject:_representedObject];
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p - %@>", self.class, self, self.childrenStorage];
}

- (void)setRepresentedObject:(id)representedObject
{
    if ( _representedObject ) {
        [self removeMonitorsForObject:_representedObject];
    }
    _representedObject = representedObject;
    if ( _representedObject ) {
        [self addMonitorsForObject:_representedObject];
    }
}

- (NSUInteger)countOfChildren
{
    return self.childrenStorage.count;
}

- (id)nodeInChildrenAtIndex:(NSUInteger)index;
{
    return [self.childrenStorage objectAtIndex:index];
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
    [self addMonitorsForObject:object];
    [self openBatchUpdate];
    [self.childrenStorage insertObject:object atIndex:index];
    [self.changeSet insertAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self closeBatchUpdate];
}

- (NSUInteger)childrenIndexOfObject:(id)object
{
    return [self.childrenStorage indexOfObject:object];
}

- (void)addMonitorsForObject:(NSObject *)anObject
{
    [super addMonitorsForObject:anObject];
    if ( self.class.shouldObserveContents &&
        [anObject.class keyPathsForValuesAffectingValueForKey:RZAssemblageUpdateKey].count ) {
        NSLog(@"%@ adding observer %@", self, anObject);
        [anObject addObserver:self
                   forKeyPath:RZAssemblageUpdateKey
                      options:NSKeyValueObservingOptionNew
                      context:&RZAssemblageUpdateContext];
    }
}

- (void)removeMonitorsForObject:(NSObject *)anObject;
{
    [super removeMonitorsForObject:anObject];
    if ( self.class.shouldObserveContents &&
        [anObject.class keyPathsForValuesAffectingValueForKey:RZAssemblageUpdateKey].count ) {
        NSLog(@"%@ removing observer %@", self, anObject);
        [anObject removeObserver:self
                      forKeyPath:RZAssemblageUpdateKey
                         context:&RZAssemblageUpdateContext];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( context == &RZAssemblageUpdateContext ) {
        [self openBatchUpdate];
        if ( object == _representedObject ) {
            [self.changeSet updateAtIndexPath:[NSIndexPath indexPathWithIndexes:NULL length:0]];
        }
        else {
            NSUInteger index = [self childrenIndexOfObject:object];
            [self.changeSet updateAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
        }
        [self closeBatchUpdate];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end

@implementation RZSnapshotAssemblage

+ (BOOL)shouldObserveContents
{
    return NO;
}

@end

@implementation NSObject (RZAssemblageUpdateKey)

- (id)RZAssemblageUpdateKey { return  nil; }
- (void)setRZAssemblageUpdateKey:(id)RZAssemblageUpdateKey {}

@end