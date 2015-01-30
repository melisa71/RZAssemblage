//
//  RZMutableAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZMutableAssemblage.h"
#import "RZAssemblage+Private.h"

@interface RZMutableAssemblage()

@property (copy, nonatomic) NSMutableArray *store;

@end

@implementation RZMutableAssemblage

- (instancetype)initWithArray:(NSArray *)array
{
    NSParameterAssert(array);
    self = [super initWithArray:@[]];
    if ( self ) {
        _store = [array mutableCopy];
        for ( id object in _store ) {
            [self assignDelegateIfObjectIsAssemblage:object];
        }
    }
    return self;
}

#pragma mark - Batch Updating

- (void)beginUpdateAndEndUpdateNextRunloop
{
    [self willBeginUpdatesForAssemblage:self];
    [self performSelector:@selector(didEndUpdatesForEnsemble:) withObject:self afterDelay:0.0];
}

- (void)beginUpdates
{
    [self willBeginUpdatesForAssemblage:self];
}

- (void)endUpdates
{
    [self didEndUpdatesForEnsemble:self];
}

#pragma mark - Basic Mutation

- (void)addObject:(id)anObject
{
    NSParameterAssert(anObject);
    [self assignDelegateIfObjectIsAssemblage:anObject];
    [self willBeginUpdatesForAssemblage:self];
    [self.store addObject:anObject];
    NSUInteger index = self.store.count - 1;
    [self.delegate assemblage:self didInsertObject:anObject atIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self didEndUpdatesForEnsemble:self];
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    NSParameterAssert(anObject);
    [self assignDelegateIfObjectIsAssemblage:anObject];
    [self willBeginUpdatesForAssemblage:self];
    [self.store insertObject:anObject atIndex:index];
    [self.delegate assemblage:self didInsertObject:anObject atIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self didEndUpdatesForEnsemble:self];
}

- (void)removeLastObject
{
    [self willBeginUpdatesForAssemblage:self];
    NSUInteger index = self.store.count - 1;
    id object = [self.store objectAtIndex:index];
    [self.store removeObjectAtIndex:index];
    [self.delegate assemblage:self didRemoveObject:object atIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self didEndUpdatesForEnsemble:self];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    [self willBeginUpdatesForAssemblage:self];
    id object = [self.store objectAtIndex:index];
    [self.store removeObjectAtIndex:index];
    [self.delegate assemblage:self didRemoveObject:object atIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self didEndUpdatesForEnsemble:self];
}

- (void)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2
{
    [self willBeginUpdatesForAssemblage:self];
    id object = [self.store objectAtIndex:idx1];
    [self.store exchangeObjectAtIndex:idx1 withObjectAtIndex:idx2];
    [self.delegate assemblage:self didMoveObject:object
                fromIndexPath:[NSIndexPath indexPathWithIndex:idx1]
                  toIndexPath:[NSIndexPath indexPathWithIndex:idx2]];
    [self didEndUpdatesForEnsemble:self];
}

- (void)notifyObjectUpdate:(id)anObject
{
    NSParameterAssert(anObject);
    NSUInteger index = [self.store indexOfObject:anObject];
    NSAssert(index != NSNotFound, @"Object is not part of assemblage");
    [self willBeginUpdatesForAssemblage:self];
    [self.delegate assemblage:self didUpdateObject:anObject atIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self didEndUpdatesForEnsemble:self];
}

#pragma mark - Index Path Mutation

- (RZMutableAssemblage *)mutableAssemblageHoldingIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *containerIndexPath = [indexPath indexPathByRemovingLastIndex];
    id object = [self objectAtIndexPath:containerIndexPath];
    if ( [object isKindOfClass:[RZMutableAssemblage class]] == NO ) {
        [NSException raise:NSInvalidArgumentException format:@"Index Path %@ did not lead to a %@, but %@", indexPath, [RZMutableAssemblage class], object];
    }
    return object;
}

- (void)insertObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath
{
    RZMutableAssemblage *container = [self mutableAssemblageHoldingIndexPath:indexPath];
    [container insertObject:anObject atIndex:[indexPath rz_lastIndex]];
}

- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath
{
    RZMutableAssemblage *container = [self mutableAssemblageHoldingIndexPath:indexPath];
    [container removeObjectAtIndex:[indexPath rz_lastIndex]];
}

- (void)moveObjectAtIndexPath:(NSIndexPath *)indexPath1 toIndexPath:(NSIndexPath *)indexPath2
{
    [self beginUpdates];
    id object = [self objectAtIndexPath:indexPath1];
    [self removeObjectAtIndexPath:indexPath1];
    [self insertObject:object atIndexPath:indexPath2];
    [self endUpdates];

}

@end
