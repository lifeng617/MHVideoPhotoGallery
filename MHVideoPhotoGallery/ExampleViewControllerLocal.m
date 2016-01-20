//
//  ExampleViewControllerLocal.m
//  MHVideoPhotoGallery
//
//  Created by Mario Hahn on 28.01.14.
//  Copyright (c) 2014 Mario Hahn. All rights reserved.
//

#import "ExampleViewControllerLocal.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "MHGallery.h"
#import "ExampleViewControllerTableView.h"


@implementation MHGallerySectionItem


- (id)initWithSectionName:(NSString*)sectionName
                    items:(NSArray*)galleryItems{
    self = [super init];
    if (!self)
        return nil;
    self.sectionName = sectionName;
    self.galleryItems = galleryItems;
    return self;
}
@end


@interface ExampleViewControllerLocal ()<MHGalleryDataSource, MHGalleryDelegate>
@property (nonatomic,strong)NSMutableArray *allData;
@property(nonatomic,strong) UIImageView *imageViewForPresentingMHGallery;
@property(nonatomic,strong) MHTransitionDismissMHGallery *interactive;

@property (nonatomic, strong) NSMutableArray *currentItems;
@end

@implementation ExampleViewControllerLocal

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.allData = [NSMutableArray new];
    
    PHFetchOptions *options = [PHFetchOptions new];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSMutableArray *items = [NSMutableArray new];
        
        PHFetchResult *result = [PHAsset fetchAssetsWithOptions:options];
        [result enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [items addObject:[MHGalleryItem itemWithPHAseet:obj]];
        }];
        
        [self.allData addObject:[[MHGallerySectionItem alloc] initWithSectionName:@"All" items:items]];
        [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    });
    
//    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//    
//    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
//        [group setAssetsFilter:[ALAssetsFilter allAssets]];
//        NSMutableArray *items = [NSMutableArray new];
//        [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *alAsset, NSUInteger index, BOOL *innerStop) {
//            if (alAsset) {
//                MHGalleryItem *item = [[MHGalleryItem alloc]initWithURL:[alAsset.defaultRepresentation.url absoluteString]
//                                                            galleryType:MHGalleryTypeImage];
//                [items addObject:item];
//            }
//        }];
//        if(group){
//            MHGallerySectionItem *section = [[MHGallerySectionItem alloc]initWithSectionName:[group valueForProperty:ALAssetsGroupPropertyName]
//                                                                                       items:items];
//            [self.allData addObject:section];
//        }
//        if (!group) {
//            [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
//        }
//        
//    } failureBlock: ^(NSError *error) {
//        
//    }];

}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = nil;
    cellIdentifier = @"ImageTableViewCell";
    
    ImageTableViewCell *cell = (ImageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell){
        cell = [[ImageTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    MHGallerySectionItem *section = self.allData[indexPath.row];
    
    MHGalleryItem *item = [section.galleryItems firstObject];
    
    [[MHGallerySharedManager sharedManager] startDownloadingThumbnailForItem:item successBlock:^(UIImage *image, NSUInteger videoDuration, NSError *error) {
        cell.iv.image = image;
    }];
    
    cell.labelText.text = section.sectionName;
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.allData.count;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    dispatch_async(dispatch_get_main_queue(), ^{
        MHGallerySectionItem *section = self.allData[indexPath.row];
        NSArray *galleryData = section.galleryItems;
        if (galleryData.count >0) {
            
            self.currentItems = [galleryData mutableCopy];
            
            MHGalleryController *gallery = [[MHGalleryController alloc]initWithPresentationStyle:MHGalleryViewModeImageViewerNavigationBarShown];
            gallery.galleryDelegate = self;
            gallery.dataSource = self;
            gallery.presentationIndex = [galleryData count] - 1;
            gallery.UICustomization.hideShare = YES;
            gallery.UICustomization.hideArrows = YES;
            
            __weak MHGalleryController *blockGallery = gallery;
            
            gallery.finishedCallback = ^(NSInteger currentIndex,UIImage *image,MHTransitionDismissMHGallery *interactiveTransition,MHGalleryViewMode viewMode){
                [blockGallery dismissViewControllerAnimated:YES dismissImageView:nil completion:nil];
            };
            
            [self presentMHGalleryController:gallery animated:YES completion:nil];

        }else{
            UIAlertView *alterView = [[UIAlertView alloc]initWithTitle:@"Hint"
                                                               message:@"You don't have images on your Simulator"
                                                              delegate:nil
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil, nil];
            [alterView show];
        }
    });
}

- (NSInteger)numberOfItemsInGallery:(MHGalleryController *)galleryController {
    return [self.currentItems count];
}
- (MHGalleryItem*)itemForIndex:(NSInteger)index {
    return self.currentItems[index];
}
- (NSArray *)itemArray {
    return self.currentItems;
}

- (BOOL)galleryController:(MHGalleryController *)galleryController shouldRemoveItemAtIndex:(NSInteger)index
{
    [self.currentItems removeObjectAtIndex:index];
    return true;
}


@end
