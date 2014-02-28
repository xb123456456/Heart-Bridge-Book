//
//  FirstViewController.m
//  NoteBook
//
//  Created by xubing on 14-1-2.
//  Copyright (c) 2014年 xubing. All rights reserved.
//

#import "FirstViewController.h"
#import "ContactCell.h"
#import "Contact.h"
#import "AddViewController.h"
#import "ShowViewController.h"

#define ENTITY_NAME @"Contact"
#define SORT_DESCRIPTION_CREATE_DATE @"createDate"

@interface FirstViewController () {
    NSInteger recordTag;
}

@property (nonatomic, strong) NSMutableArray *dataArray;

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateCollectionViewData];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [self updateCollectionViewData];
    [self.collectionView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateCollectionViewData {
    AppDelegate *myDelegate = [[UIApplication sharedApplication] delegate];
    self.dataArray = [[myDelegate fetchObjectsWithEntity:@"Contact" predicate:nil sort:@"creatDate" ascending:NO] mutableCopy];
    NSLog(@"=== number of items is %lu", (unsigned long)self.dataArray.count);
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    ContactCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    Contact *contact = self.dataArray[indexPath.row];
    cell.name.text = contact.name;
    cell.tele.text = contact.telephoneNumber;
    cell.imageView.layer.cornerRadius = 15.0;
    cell.imageView.layer.masksToBounds = YES;
    cell.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:contact.defaultImagePath]]];
    
    UITapGestureRecognizer *nameTapRecognizer = [[UITapGestureRecognizer alloc]
                                                 initWithTarget:self action:@selector(nameTapped:)];
    nameTapRecognizer.numberOfTapsRequired = 1;
    [cell.name addGestureRecognizer:nameTapRecognizer];
    
    UITapGestureRecognizer *telephoneTapRecognizer = [[UITapGestureRecognizer alloc]
                                                      initWithTarget:self action:@selector(telephoneTapped:)];
    telephoneTapRecognizer.numberOfTapsRequired = 1;
    [cell.tele addGestureRecognizer:telephoneTapRecognizer];
    
    UITapGestureRecognizer *imageTapRecognizer = [[UITapGestureRecognizer alloc]
                                                  initWithTarget:self action:@selector(contactTapped:)];
    imageTapRecognizer.numberOfTapsRequired = 1;
    [cell.imageView addGestureRecognizer:imageTapRecognizer];
    
    cell.btnOption.tag = indexPath.row;
    cell.btnPhone.tag = indexPath.row;
    cell.imageView.tag = indexPath.row;
    cell.name.tag = indexPath.row;
    cell.tele.tag = indexPath.row;
    return cell;
}

#pragma  mark -optionIBAction
- (IBAction)option:(id)sender {
    UIButton *button = (UIButton*)sender;
    int tagNumber = button.tag;
    self.indexPath = [NSIndexPath indexPathForRow:tagNumber inSection:0];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"对该联系人操作" delegate:self
                                                    cancelButtonTitle:@"取          消"
                                               destructiveButtonTitle:@"删 除 信 息"
                                                    otherButtonTitles:@"编 辑 信 息",nil];
    
    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    [actionSheet showInView:self.view];
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        //可在此添加AlertView
        [self deleteItemAtIndexPath:self.indexPath];
    } else if (buttonIndex == 1) {
        [self switchToEditController:self.indexPath];
    }
}

- (void)deleteItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.collectionView performBatchUpdates:^{
        [self deleteItemsFromDataSourceAtIndexPath:indexPath];
        [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    } completion:nil];
    [self.collectionView reloadData];
}

- (void)deleteItemsFromDataSourceAtIndexPath:(NSIndexPath *)indexPath {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    Contact *contact = self.dataArray[indexPath.row];
    NSError *error;
    BOOL success = [fileManager removeItemAtURL:[NSURL URLWithString:contact.defaultImagePath] error:&error];
    [fileManager removeItemAtURL:[NSURL URLWithString:contact.nameAudioPath] error:&error];
    [fileManager removeItemAtURL:[NSURL URLWithString:contact.telephoneNumberAudioPath] error:&error];
    [fileManager removeItemAtURL:[NSURL URLWithString:contact.addressAudioPath] error:&error];
    if (success) {
    } else {
        NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
    }
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    [context deleteObject:self.dataArray[indexPath.row]];
    BOOL isSaveSuccess = [appDelegate.managedObjectContext save:&error];
    if (!isSaveSuccess) {
        NSLog(@"Error: %@,%@",error,[error userInfo]);
    } else {
        NSLog(@"Delete successful!");
    }
    
    [self.dataArray removeObjectAtIndex:indexPath.row];
}

- (IBAction)call:(id)sender {
    UIButton *button = (UIButton*)sender;
    int tagNumber = button.tag;
    self.indexPath = [NSIndexPath indexPathForRow:tagNumber inSection:0];
    [self callNumber:self.indexPath];
}

- (void)callNumber:(NSIndexPath *)indexPath {
    Contact *contact = self.dataArray[indexPath.row];
    UIWebView*callWebview =[[UIWebView alloc] init];
    NSURL *telURL =[NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", contact.telephoneNumber]];
    [callWebview loadRequest:[NSURLRequest requestWithURL:telURL]];
    //记得添加到view上
    [self.view addSubview:callWebview];
}

- (void)switchToEditController:(NSIndexPath *)index {
    BOOL edit = YES;
    Contact *contact = self.dataArray[index.row];
    
    AddViewController *editController = [[AddViewController alloc] init];
    //将contact对象传递给AddViewController
    editController.contact = contact;
    editController.editContact = edit;
    [self.navigationController pushViewController:editController animated:YES];
}

#pragma  mark - playAudio
- (NSURL *)chooseUrl:(int)tag {
    NSURL *url;
    Contact *contact = self.dataArray[tag];
    switch (recordTag) {
        case 1:{
            url = [NSURL URLWithString:contact.nameAudioPath];
            break;
        }
        case 2:{
            url = [NSURL URLWithString:contact.telephoneNumberAudioPath];
            break;
        }
        default:{
            url = [NSURL URLWithString:contact.addressAudioPath];
            break;
        }
    }
    return url;
}

#pragma mark - tapGesture
- (void)nameTapped:(UITapGestureRecognizer *)sender {
    int tag = [sender view].tag;
    recordTag = 1;
    [self playAudio:tag];
}

- (void)telephoneTapped:(UITapGestureRecognizer *)sender {
    int tag = [sender view].tag;
    recordTag = 2;
    [self playAudio:tag];
}

- (void)addressTapped:(UITapGestureRecognizer *)sender {
    int tag = [sender view].tag;
    recordTag = 3;
    [self playAudio:tag];
}

- (void)playAudio:(int)tag {
    if (self.avPlay.playing) {
        [self.avPlay stop];
        return;
    }
    AVAudioPlayer *player = [[AVAudioPlayer alloc]initWithContentsOfURL:[self chooseUrl:tag] error:nil];
    self.avPlay = player;
    [self.avPlay play];
}

- (void)contactTapped:(UITapGestureRecognizer *)sender {
    //获取tag
    int tag = [sender view].tag;
    //获取对应的contact对象
    Contact *contact = self.dataArray[tag];
    ShowViewController *showDetailController = [[ShowViewController alloc] init];
    //将contact对象传递给ShowViewController
    showDetailController.contact = contact;
    [self.navigationController pushViewController:showDetailController animated:YES];
}

@end
