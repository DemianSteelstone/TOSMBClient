//
//  TOFilesViewControllerTableViewController.m
//  TOSMBClientExample
//
//  Created by Tim Oliver on 8/5/15.
//  Copyright (c) 2015 TimOliver. All rights reserved.
//

#import "TOFilesTableViewController.h"
#import "TOSMBClient.h"
#import "TORootViewController.h"

@interface TOFilesTableViewController ()

@property (nonatomic, copy) NSString *directoryTitle;
@property (nonatomic, strong) TOSMBSession *session;
@property (nonatomic, strong) TOSMBSessionUploadTask *uploadTask;

@end

@implementation TOFilesTableViewController
{
    TOSMBSessionCreateFolderTask *_createFolderTask;
    TOSMBSessionRemoveTask *_removeTask;
}

- (instancetype)initWithSession:(TOSMBSession *)session title:(NSString *)title
{
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        _directoryTitle = title;
        _session = session;
    }
    
    return self;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:YES];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Loading...";
    
    if (self.path.length) {
        UIBarButtonItem *uploadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(upload:)];
        UIBarButtonItem *createFolder = [[UIBarButtonItem alloc] initWithTitle:@"Create folder"
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(createFolder:)];
        self.toolbarItems = @[uploadButton,createFolder];
    }
}

- (void)upload:(id)sender {
    
    NSString *path = [[self.path stringByAppendingPathComponent:[NSUUID UUID].UUIDString] stringByAppendingPathExtension:@"txt"];
    NSData *data = [path dataUsingEncoding:NSUTF8StringEncoding];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"testfile.txt"];
    [data writeToFile:dataPath atomically:YES];
    
    __weak typeof(self) weakSelf = self;
    self.uploadTask = [self.session uploadTaskForSurceFilePath:dataPath destinationPath:path progressHandler:nil completionHandler:^(TOSMBSessionFile *file){
        [weakSelf reloadData];
        weakSelf.navigationItem.rightBarButtonItems.lastObject.enabled = YES;
    } failHandler:^(NSError *error) {
        weakSelf.navigationItem.rightBarButtonItems.lastObject.enabled = YES;
    }];
    
    [self.uploadTask start];
}

- (void)createFolder:(id)sender {
    
    NSString *path = [self.path stringByAppendingPathComponent:[NSUUID UUID].UUIDString];
    
    __weak typeof(self) weakSelf = self;
    
    _createFolderTask = [self.session createFolderAtPath:path
                                       completionHandler:^(TOSMBSessionFile *folder) {
                                           [weakSelf reloadData];
                                       } failHandler:^(NSError *error) {
                                           
                                       }];
    [_createFolderTask start];
}

- (void)reloadData {
    __weak typeof(self) weakSelf = self;
    [self.session requestContentsOfDirectoryAtFilePath:self.path success:^(NSArray *files) {
        weakSelf.files = files;
        [weakSelf.tableView reloadData];
    } error:^(NSError *error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"SMB Client Error" message:error.localizedDescription delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
    }];
    
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    TOSMBSessionFile *file = self.files[indexPath.row];
    cell.textLabel.text = file.name;
    cell.detailTextLabel.text = file.directory ? @"Directory" : [NSString stringWithFormat:@"File | Size: %ld", (long)file.fileSize];
    cell.accessoryType = file.directory ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    TOSMBSessionFile *file = self.files[indexPath.row];
    if (file.directory == NO) {
        [self.rootController downloadFileFromSession:self.session atFilePath:file.filePath];
        return;
    }
    
    TOFilesTableViewController *controller = [[TOFilesTableViewController alloc] initWithSession:self.session title:file.name];
    controller.rootController = self.rootController;
    controller.path = file.filePath;
    controller.navigationItem.rightBarButtonItems = self.navigationItem.rightBarButtonItems;
    [self.navigationController pushViewController:controller animated:YES];
    
    [self.session requestContentsOfDirectoryAtFilePath:file.filePath success:^(NSArray *files) {
        controller.files = files;
    } error:^(NSError *error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"SMB Client Error" message:error.localizedDescription delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
    }];
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    TOSMBSessionFile *file = self.files[indexPath.row];
    __weak typeof(self) weakSelf = self;
    _removeTask = [self.session removeTaskForItem:file.filePath
                                completionHandler:^{
                                    [weakSelf reloadData];
                                } failHandler:^(NSError *error) {
                                    NSLog(@"Failed to delete %@",file.filePath);
                                }];
    [_removeTask start];
}

- (void)setFiles:(NSArray <TOSMBSessionFile *> *)files
{
    _files = files;
    self.navigationItem.title = self.directoryTitle;
    
    [self.tableView reloadData];
}
         
@end
