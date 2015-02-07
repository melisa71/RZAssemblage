//
//  RZChangeSet.m
//  RZAssemblage
//
//  Created by Brian King on 2/7/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblageChangeSet.h"
#import "RZMutableIndexPathSet.h"
#import "NSIndexPath+RZAssemblage.h"

@interface RZAssemblageChangeSet ()

@property (strong, nonatomic) id<RZAssemblage> startingAssemblage;

@property (strong, nonatomic) RZMutableIndexPathSet *inserts;
@property (strong, nonatomic) RZMutableIndexPathSet *updates;
@property (strong, nonatomic) RZMutableIndexPathSet *removes;
@property (strong, nonatomic) RZMutableIndexPathSet *moves;

@end

@implementation RZAssemblageChangeSet

- (void)beginUpdateWithAssemblage:(id<RZAssemblage>)assemblage
{
    if ( self.updateCount == 0 ) {
#warning Add Copy
        self.startingAssemblage = assemblage;
    }
    _updateCount++;
}

- (void)mergeChangeSet:(RZAssemblageChangeSet *)changeSet fromIndex:(NSUInteger)index
{
    [changeSet.inserts enumerateSortedIndexPathsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
        indexPath = [indexPath rz_indexPathByPrependingIndex:index];
        [self insertAtIndexPath:indexPath];
    }];
}

- (void)endUpdateWithAssemblage:(id<RZAssemblage>)assemblage
{
    _updateCount--;
}

- (void)insertAtIndexPath:(NSIndexPath *)indexPath
{
    [self.updates shiftIndexesStartingAtIndexPath:indexPath by:1];
    [self.inserts shiftIndexesStartingAtIndexPath:indexPath by:1];
    [self.moves shiftIndexesStartingAtIndexPath:indexPath by:1];

    [self.inserts addIndexPath:indexPath];
}

- (void)updateAtIndexPath:(NSIndexPath *)indexPath
{
    [self.updates addIndexPath:indexPath];
}

- (void)removeAtIndexPath:(NSIndexPath *)indexPath
{
    [self.updates shiftIndexesStartingAfterIndexPath:indexPath by:-1];
    [self.inserts shiftIndexesStartingAfterIndexPath:indexPath by:-1];
    [self.moves shiftIndexesStartingAfterIndexPath:indexPath by:-1];

    // If the index has already been removed, shift it down
    NSIndexPath *indexPathToRemove = indexPath;
    while ( [self.removes containsIndexPath:indexPathToRemove] ) {
        indexPathToRemove = [indexPathToRemove rz_indexPathWithLastIndexShiftedBy:1];
    }
    [self.removes addIndexPath:indexPathToRemove];
}

- (void)moveAtIndexPath:(NSIndexPath *)index1 toIndexPath:(NSIndexPath *)index2
{
    if ( [self.updates containsIndexPath:index1] ) {
        [self.updates removeIndexPath:index1];
        [self.updates addIndexPath:index2];
    }
    [self.moves addIndexPath:index2];
}

@end
