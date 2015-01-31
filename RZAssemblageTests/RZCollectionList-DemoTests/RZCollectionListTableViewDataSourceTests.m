//
//  RZCollectionListTableViewDataSourceTests.m
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 3/19/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "RZCollectionListTableViewDataSourceTests.h"
#import "RZMutableAssemblage.h"
#import "RZAssemblageTableViewDataSource.h"

@interface RZCollectionListTableViewDataSourceTests () <RZAssemblageTableViewDataSourceProxy>

@property (nonatomic, strong) RZMutableAssemblage *section;
@property (nonatomic, strong) RZMutableAssemblage *arrayList;
@property (nonatomic, strong) RZAssemblageTableViewDataSource *dataSource;

@property (nonatomic, assign) BOOL shouldContinue;

@end

@implementation RZCollectionListTableViewDataSourceTests

- (void)setUp{
    [super setUp];
    [self setupTableView];
}

- (void)tearDown{
    [self waitFor:1.5];
    [super tearDown];
}

#pragma mark - Tests

- (void)test1ArrayListNonBatch
{
    NSArray *startArray = @[@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9"];

    self.arrayList = [[RZMutableAssemblage alloc] initWithArray:@[[[RZMutableAssemblage alloc] initWithArray:startArray]]];

    
    self.dataSource = [[RZAssemblageTableViewDataSource alloc] initWithAssemblage:self.arrayList
                                                                     forTableView:self.tableView
                                                                   withDataSource:self];
    
    [self waitFor:0.1];
    
    for (int i=0; i<10; i++){
        XCTAssertNoThrow([self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], @"Table view exception");
    }
}

- (void)test2ArrayListBatchAddRemove
{
    NSArray *startArray = @[@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9"];
    
    self.arrayList = [[RZMutableAssemblage alloc] initWithArray:@[[[RZMutableAssemblage alloc] initWithArray:startArray]]];


    self.dataSource = [[RZAssemblageTableViewDataSource alloc] initWithAssemblage:self.arrayList
                                                                     forTableView:self.tableView
                                                                   withDataSource:self];

    [self waitFor:0.1];
    
    [self.arrayList beginUpdates];
    
    // remove a few objects at the beginning
    for (int i=0; i<5; i++){
        [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    }
    
    // insert a few objects at the end
    for (int i=0; i<5; i++){
        NSString *idx = [NSString stringWithFormat:@"%d",i];
        [self.arrayList insertObject:idx atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    }
    
    XCTAssertNoThrow([self.arrayList endUpdates], @"Table View exception");
    
}

- (void)test3ArrayListBatchAddRemoveRandomAccess
{
    NSArray *startArray = @[@"0",@"1",[NSMutableString stringWithString:@"2"],@"3",@"4",@"5",@"6",@"7",@"8",@"9"];

    self.section = [[RZMutableAssemblage alloc] initWithArray:startArray];
    self.arrayList = [[RZMutableAssemblage alloc] initWithArray:@[self.section]];


    self.dataSource = [[RZAssemblageTableViewDataSource alloc] initWithAssemblage:self.arrayList
                                                                     forTableView:self.tableView
                                                                   withDataSource:self];
    [[[[UIApplication sharedApplication] delegate] window] makeKeyAndVisible];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];

    [self.arrayList beginUpdates];

    // remove first object
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    // insert object at second index
    [self.arrayList insertObject:@"first" atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];

    // remove first object
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    // update title of second cell
    NSMutableString *twoString = [startArray objectAtIndex:2];
    [twoString deleteCharactersInRange:NSMakeRange(0, twoString.length)];
    [twoString appendString:@"third"];

    [self.section notifyUpdateOfObject:twoString];

    // add object at first index
    [self.arrayList insertObject:@"second" atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    // move to second index
    [self.arrayList moveObjectAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] toIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    // add objects at the end
    [self.arrayList insertObject:@"last" atIndexPath:[NSIndexPath indexPathForRow:10 inSection:0]];
    [self.arrayList insertObject:@"penultimate" atIndexPath:[NSIndexPath indexPathForRow:10 inSection:0]];
    
    // delete a few interediate objects
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    
    XCTAssertNoThrow([self.arrayList endUpdates], @"Table View exception");
    XCTAssertTrue([self.tableView numberOfRowsInSection:0] == 10);
    NSArray *text = [[self.tableView visibleCells] valueForKeyPath:@"text"];
    // final order should be:
    NSArray *expected = @[
                          @"first",
                          @"second",
                          @"third",
                          @"5",
                          @"6",
                          @"7",
                          @"8",
                          @"9",
                          @"penultimate",
                          @"last"];
    XCTAssertEqualObjects(text, expected);
}

- (void)test4ArrayListBatchWithSectionUpdates
{
    NSArray *startArray = @[@"0",@"1",[@"2" mutableCopy],@"3",@"4",@"5",@"6",@"7",@"8",@"9"];
    self.section = [[RZMutableAssemblage alloc] initWithArray:startArray];
    self.arrayList = [[RZMutableAssemblage alloc] initWithArray:@[self.section]];


    self.dataSource = [[RZAssemblageTableViewDataSource alloc] initWithAssemblage:self.arrayList
                                                                     forTableView:self.tableView
                                                                   withDataSource:self];

    // Insert section before and after numbers
    RZMutableAssemblage *newSection = [[RZMutableAssemblage alloc] initWithArray:@[]];
    [self.arrayList insertObject:newSection atIndex:0];
    
    NSArray *firstSectionStrings = @[@"A",@"B",@"C"];
    [firstSectionStrings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.arrayList insertObject:obj atIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
    }];
    newSection = [[RZMutableAssemblage alloc] initWithArray:@[]];
    [self.arrayList insertObject:newSection atIndex:2];

    NSArray *lastSectionStrings = @[@"This",@"is",@"the",@"final",@"section"];
    [lastSectionStrings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.arrayList insertObject:obj atIndexPath:[NSIndexPath indexPathForRow:idx inSection:2]];
    }];
    

    // batch modify sections and objects
        
    [self.arrayList beginUpdates];
    
    [self.arrayList removeObjectAtIndex:0];
    
    // remove first object
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    // insert object at second index
    [self.arrayList insertObject:@"first" atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    
    // remove first object
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    // update title of second cell
    NSMutableString *twoString = [self.section objectAtIndex:1];
    [twoString deleteCharactersInRange:NSMakeRange(0, twoString.length)];
    [twoString appendString:@"third"];
    [self.section notifyUpdateOfObject:twoString];
    
    // add object at first index
    [self.arrayList insertObject:@"second" atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    // move to second index
    [self.arrayList moveObjectAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] toIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    // add objects at the end
    NSInteger last = [self.arrayList numberOfChildrenAtIndexPath:[NSIndexPath indexPathWithIndex:0]];
    [self.arrayList insertObject:@"last" atIndexPath:[NSIndexPath indexPathForRow:last inSection:0]];
    [self.arrayList insertObject:@"penultimate" atIndexPath:[NSIndexPath indexPathForRow:last inSection:0]];
    
    // delete a few interediate objects
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:0]];
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:0]];

    XCTAssertNoThrow([self.arrayList endUpdates], @"Table View exception");

}

//- (void)test5ModifySectionsAndRows
//{
//    NSArray *startArray = @[@"0",@"1",[NSMutableString stringWithString:@"2"],@"3",@"4",@"5",@"6",@"7",@"8",@"9"];
//    
//    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:startArray sectionNameKeyPath:nil];
//
//    
//    // Insert section before and after numbers
//    RZArrayCollectionListSectionInfo *newSection = [[RZArrayCollectionListSectionInfo alloc] initWithName:nil sectionIndexTitle:nil numberOfObjects:0];
//    [self.arrayList insertSection:newSection atIndex:0];
//    
//    NSArray *firstSectionStrings = @[@"A",@"B",@"C"];
//    [firstSectionStrings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//        [self.arrayList insertObject:obj atIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
//    }];
//    
//    newSection = [[RZArrayCollectionListSectionInfo alloc] initWithName:nil sectionIndexTitle:nil numberOfObjects:0];
//    [self.arrayList insertSection:newSection atIndex:2];
//    
//    NSArray *lastSectionStrings = @[@"This",@"is",@"the",@"last",@"section"];
//    [lastSectionStrings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//        [self.arrayList insertObject:obj atIndexPath:[NSIndexPath indexPathForRow:idx inSection:2]];
//    }];
//    
//    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
//                                                                      collectionList:self.arrayList
//                                                                            delegate:self];
//    
//    [self waitFor:0.1];
//    
//    [self.arrayList beginUpdates];
//    
//    // remove "0"
//    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]];
//    
//    // replace with "first"
//    [self.arrayList insertObject:@"first" atIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]];
//    
//    // remove section 0
//    [self.arrayList removeSectionAtIndex:0];
//    
//    // remove "1"
//    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
//    
//    // remove section 2
//    [self.arrayList removeSectionAtIndex:1];
//    
//    XCTAssertNoThrow([self.arrayList endUpdates], @"Table View exception");
//
//}
//
//- (void)test6BatchMove
//{
//    NSArray *startArray = @[@"0",@"1",[NSMutableString stringWithString:@"2"],@"3",@"4"];
//    
//    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:startArray sectionNameKeyPath:nil];
//    
//    // Insert section before and after numbers
//    RZArrayCollectionListSectionInfo *newSection = [[RZArrayCollectionListSectionInfo alloc] initWithName:nil sectionIndexTitle:nil numberOfObjects:0];
//    [self.arrayList insertSection:newSection atIndex:0];
//    
//    NSArray *firstSectionStrings = @[@"A",@"B",@"C"];
//    [firstSectionStrings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//        [self.arrayList insertObject:obj atIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
//    }];
//    
//    newSection = [[RZArrayCollectionListSectionInfo alloc] initWithName:nil sectionIndexTitle:nil numberOfObjects:0];
//    [self.arrayList insertSection:newSection atIndex:0];
//    
//    firstSectionStrings = @[@"Delete",@"Me"];
//    [firstSectionStrings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//        [self.arrayList insertObject:obj atIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
//    }];
//    
//    
//    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
//                                                                      collectionList:self.arrayList
//                                                                            delegate:self];
//    
//    [self waitFor:0.1];
//    
//    [self.arrayList beginUpdates];
//    
//    // Delete first section
//    [self.arrayList removeSectionAtIndex:0];
//    
//    // swap 0 and 1
//    [self.arrayList moveObjectAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:1] toIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]];
//    
//    // swap 0 and 2
//    [self.arrayList moveObjectAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:1] toIndexPath:[NSIndexPath indexPathForItem:1 inSection:1]];
//    
//    // remove 0
//    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:1]];
//
//    // insert after 3
//    [self.arrayList insertObject:@"BLAH" atIndexPath:[NSIndexPath indexPathForItem:3 inSection:1]];
//
//    // move 3 to end
//    NSInteger last = [[self.arrayList.sections objectAtIndex:1] numberOfObjects] - 1;
//    [self.arrayList moveObjectAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:1] toIndexPath:[NSIndexPath indexPathForItem:last inSection:1]];
//
//    // remove first section again
//    [self.arrayList removeSectionAtIndex:0];
//    
//    XCTAssertNoThrow([self.arrayList endUpdates], @"Table View exception");
//    XCTAssertEqualObjects([self.arrayList.listObjects objectAtIndex:2], @"BLAH", @"Something went wrong here");
//    
//    [self waitFor:1.5];
//    
//    // start over - test moving row to another section
//
//    self.dataSource = nil;
//    
//    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:startArray sectionNameKeyPath:nil];
//    
//    newSection = [[RZArrayCollectionListSectionInfo alloc] initWithName:nil sectionIndexTitle:nil numberOfObjects:0];
//    [self.arrayList insertSection:newSection atIndex:0];
//
//    firstSectionStrings = @[@"Zero",@"Should",@"Precede",@"Me"];
//    [firstSectionStrings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//        [self.arrayList insertObject:obj atIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
//    }];
//    
//    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
//                                                                      collectionList:self.arrayList
//                                                                            delegate:self];
//    
//    [self waitFor:0.1];
//    
//    [self.arrayList beginUpdates];
//    
//    // insert at first row
//    [self.arrayList insertObject:@"TEST" atIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]];
//    
//    // move 1,1 to 0,0
//    [self.arrayList moveObjectAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1] toIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
//    
//    XCTAssertNoThrow([self.arrayList endUpdates], @"Table View exception");
//    XCTAssertEqualObjects([self.arrayList.listObjects objectAtIndex:0], @"0", @"Zero string was not moved correctly");
//
//}
//
//- (void)test7UpdateAndAddSection
//{
//    NSArray *startArray = @[[NSMutableString stringWithString:@"0"], [NSMutableString stringWithString:@"1"]];
//    
//    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:startArray sectionNameKeyPath:nil];    
//    self.arrayList.objectUpdateNotifications = @[@"updateMyObject"];
//
//    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
//                                                                      collectionList:self.arrayList
//                                                                            delegate:self];
//    
//    [self waitFor:0.1];
//    
//    [self.arrayList beginUpdates];
//    
//    NSMutableString *zeroString = [startArray objectAtIndex:0];
//    [zeroString deleteCharactersInRange:NSMakeRange(0, zeroString.length)];
//    [zeroString appendString:@"zero"];
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateMyObject" object:zeroString];
//    
//    NSMutableString *oneString = [startArray objectAtIndex:1];
//    [oneString deleteCharactersInRange:NSMakeRange(0, oneString.length)];
//    [oneString appendString:@"one"];
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateMyObject" object:oneString];
//    
//    RZArrayCollectionListSectionInfo *sectionZero = [[RZArrayCollectionListSectionInfo alloc] initWithName:@"zero" sectionIndexTitle:@"zero" numberOfObjects:0];
//    [self.arrayList insertSection:sectionZero atIndex:0];
//    
//    [self.arrayList addObject:@"Pre-Numbers" toSection:0];
//    
//    XCTAssertNoThrow([self.arrayList endUpdates], @"Table View exception");
//    
//    // Not sure how else to assert the update succeeded. Need to wait until after animation finishes.
//    [self waitFor:1.5];
//    
//    XCTAssertEqualObjects([self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]].textLabel.text, @"zero", @"Cell at index 1 should have title \"zero\"");
//    XCTAssertEqualObjects([self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]].textLabel.text, @"one", @"Cell at index 2 should have title \"one\"");
//}
//
//- (void)test8SeveralMoves
//{
//    NSArray *startArray = @[@"1",@"2",@"3",@"4",@"5"];
//    
//    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:startArray sectionNameKeyPath:nil];
//    
//    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
//                                                                      collectionList:self.arrayList
//                                                                            delegate:self];
//    
//    [self.arrayList beginUpdates];
//    
//    [self.arrayList moveObjectAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0] toIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
//    
//    [self.arrayList moveObjectAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0] toIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
//
//    [self.arrayList moveObjectAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0] toIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];
//
//    XCTAssertNoThrow([self.arrayList endUpdates], @"Table View exception");
//    
//    // Final order should be 3, 4, 1, 5, 2
//    NSArray *finalArray = @[@"3",@"4",@"1",@"5",@"2"];
//    XCTAssertEqualObjects(self.arrayList.listObjects, finalArray, @"Final array order is incorrect");
//}

#pragma mark - Table View Data Source

- (UITableViewCell*)tableView:(UITableView *)tableView cellForObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    if ([object isKindOfClass:[NSString class]]){
        cell.textLabel.text = object;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView updateCell:(UITableViewCell *)cell forObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    if ([object isKindOfClass:[NSString class]]){
        cell.textLabel.text = object;
    }
}

@end
