//
//  MHGalleryOverViewController.m
//  MHVideoPhotoGallery
//
//  Created by Mario Hahn on 27.12.13.
//  Copyright (c) 2013 Mario Hahn. All rights reserved.
//

#import "MHOverviewController.h"
#import "MHGalleryController.h"
#import "MHGallerySharedManagerPrivate.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "SDWebImageManager.h"

@implementation MHIndexPinchGestureRecognizer
@end

@interface MHOverviewController ()

@property (nonatomic, strong) UILabel                *galleryTitleLabel;
@property (nonatomic, strong) UILabel                *navTitleLabel;
@property (nonatomic, strong) MHTransitionShowDetail *interactivePushTransition;
@property (nonatomic        ) CGPoint                lastPoint;
@property (nonatomic        ) CGFloat                startScale;
@end


@implementation MHOverviewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    if ([self.galleryViewController.dataSource respondsToSelector:@selector(titleOfGalleryController:)]) {
        
        UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 16)];
        label.text = [self galleryTitle];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:16];
        [titleView addSubview:label];
        self.galleryTitleLabel = label;
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 18, 200, 14)];
        titleLabel.font = [UIFont systemFontOfSize:12];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [titleView addSubview:titleLabel];
        
        self.navTitleLabel = titleLabel;
        self.navigationItem.titleView = titleView;
    } else if ([self.galleryViewController.dataSource respondsToSelector:@selector(staticTitleOfGalleryController:)]) {
        self.title = [self.galleryViewController.dataSource staticTitleOfGalleryController:self.galleryViewController];
    } else {
        self.title =  MHGalleryLocalizedString(@"overview.title.current");
    }
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(donePressed)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playPressed)];
    
    CGRect frame = self.view.bounds;
    CGSize size = frame.size;
    size.height -= 44;
    
    self.collectionView = [UICollectionView.alloc initWithFrame:frame
                                           collectionViewLayout:[self layoutForOrientation:UIApplication.sharedApplication.statusBarOrientation]];
    
    self.collectionView.backgroundColor = [self.galleryViewController.UICustomization MHGalleryBackgroundColorForViewMode:MHGalleryViewModeOverView];
    self.collectionView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    
    [self.collectionView registerClass:MHMediaPreviewCollectionViewCell.class
            forCellWithReuseIdentifier:NSStringFromClass(MHMediaPreviewCollectionViewCell.class)];
    
    self.collectionView.dataSource = self;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.delegate = self;
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:self.collectionView];
    [self.collectionView reloadData];
    
    frame = self.view.bounds;
    frame.origin = CGPointMake(0, frame.size.height - 44);
    frame.size = CGSizeMake(frame.size.width, 44);
    
    
    UIBarButtonItem *flexItem1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *flexItem2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *cameraItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(cameraPressed)];
    
    self.toolBar = [[UIToolbar alloc] initWithFrame:frame];
    self.toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    self.toolBar.items = @[flexItem1, cameraItem, flexItem2];
    [self.view addSubview:self.toolBar];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    
    UIMenuItem *saveItem = [UIMenuItem.alloc initWithTitle:MHGalleryLocalizedString(@"overview.menue.item.save")
                                                    action:@selector(saveImage:)];
#pragma clang diagnostic pop
    
    UIMenuController.sharedMenuController.menuItems = @[saveItem];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    [UIApplication.sharedApplication setStatusBarStyle:self.galleryViewController.preferredStatusBarStyleMH
                                              animated:YES];
    
    
    
    [self reloadData];
    
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return self.galleryViewController.preferredStatusBarStyleMH;
}

-(UICollectionViewFlowLayout*)layoutForOrientation:(UIInterfaceOrientation)orientation{
    if (orientation == UIInterfaceOrientationPortrait ) {
        return self.galleryViewController.UICustomization.overViewCollectionViewLayoutPortrait;
    }
    return self.galleryViewController.UICustomization.overViewCollectionViewLayoutLandscape;
}

-(MHGalleryController*)galleryViewController{
    if ([self.navigationController isKindOfClass:MHGalleryController.class]) {
        return (MHGalleryController*)self.navigationController;
    }
    return nil;
}

-(MHGalleryItem*)itemForIndex:(NSInteger)index{
    return [self.galleryViewController.dataSource itemForIndex:index];
}

-(NSString *)galleryTitle {
    return [self.galleryViewController.dataSource titleOfGalleryController:self.galleryViewController];
}

-(void)updateTitle {
    if (self.navTitleLabel && [self.galleryViewController.dataSource respondsToSelector:@selector(numberOfItemsInGallery:forType:)]) {
        NSInteger photos = [self.galleryViewController.dataSource numberOfItemsInGallery:self.galleryViewController forType:MHGalleryTypeImage];
        NSInteger videos = [self.galleryViewController.dataSource numberOfItemsInGallery:self.galleryViewController forType:MHGalleryTypeVideo];
        
        NSString *title = nil;
        
        if (photos > 1) {
            title = [NSString stringWithFormat:@"%d Photos, ", (int)photos];
        } else if (photos == 1) {
            title = @"1 Photo, ";
        }
        
        if (videos > 1) {
            title = [title stringByAppendingFormat:@"%d Videos", (int)videos];
        } else if (videos == 1) {
            title = [title stringByAppendingString:@"1 Video"];
        }
        
        
        if (title == nil) {
            title = @"No Photos";
        } else if ([title hasSuffix:@", "]) {
            title = [title substringToIndex:[title length] - 2];
        }
        
        
        self.navTitleLabel.text = title;
    }
    if (self.galleryTitleLabel) {
        self.galleryTitleLabel.text = [self galleryTitle];
    }
}

-(void)reloadData {
    [self updateTitle];
    [self.collectionView reloadData];
}

-(void)cameraPressed {
    if ([self.galleryViewController.galleryDelegate respondsToSelector:@selector(galleryControllerCameraTapped:)]) {
        [self.galleryViewController.galleryDelegate galleryControllerCameraTapped:self.galleryViewController];
    }
}

-(void)playPressed {
    if ([self.galleryViewController.galleryDelegate respondsToSelector:@selector(galleryControllerPlayTapped:fromIndex:)]) {
        [self.galleryViewController.galleryDelegate galleryControllerPlayTapped:self.galleryViewController fromIndex:0];
    }
}

-(void)donePressed{
    self.navigationController.transitioningDelegate = nil;

    MHGalleryController *galleryViewController = [self galleryViewController];
    if (galleryViewController.finishedCallback) {
        galleryViewController.finishedCallback(0,nil,nil,MHGalleryViewModeOverView);
    }
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [self.galleryViewController.dataSource numberOfItemsInGallery:self.galleryViewController];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = (MHMediaPreviewCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(MHMediaPreviewCollectionViewCell.class) forIndexPath:indexPath];
    [self makeMHGalleryOverViewCell:(MHMediaPreviewCollectionViewCell*)cell
                        atIndexPath:indexPath];
    
    return cell;
}



-(void)makeMHGalleryOverViewCell:(MHMediaPreviewCollectionViewCell*)cell atIndexPath:(NSIndexPath*)indexPath{
    
    __weak typeof(self) weakSelf = self;
    
    MHGalleryItem *item =  [self itemForIndex:indexPath.row];
    cell.thumbnail.image = nil;
    
    
    cell.videoGradient.hidden = YES;
    cell.videoIcon.hidden     = YES;
    
    
    cell.saveImage = ^(BOOL shouldSave){
        [weakSelf getImageForItem:item
                   finishCallback:^(UIImage *image) {
                       UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
                   }];
    };
    
    cell.videoDurationLength.text = @"";
    cell.thumbnail.backgroundColor = [UIColor lightGrayColor];
    cell.galleryItem = item;
    
    cell.thumbnail.userInteractionEnabled =YES;
    
    MHIndexPinchGestureRecognizer *pinch = [MHIndexPinchGestureRecognizer.alloc initWithTarget:self
                                                                                        action:@selector(userDidPinch:)];
    pinch.indexPath = indexPath;
    [cell.thumbnail addGestureRecognizer:pinch];
    
    UIRotationGestureRecognizer *rotate = [UIRotationGestureRecognizer.alloc initWithTarget:self
                                                                                     action:@selector(userDidRoate:)];
    rotate.delegate = self;
    [cell.thumbnail addGestureRecognizer:rotate];
    
    
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}


-(void)userDidRoate:(UIRotationGestureRecognizer*)recognizer{
    if (self.interactivePushTransition) {
        CGFloat angle = recognizer.rotation;
        self.interactivePushTransition.angle = angle;
    }
}
-(void)userDidPinch:(MHIndexPinchGestureRecognizer*)recognizer{
    
    CGFloat scale = recognizer.scale/5;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        if (recognizer.scale>1) {
            self.interactivePushTransition = MHTransitionShowDetail.new;
            self.interactivePushTransition.indexPath = recognizer.indexPath;
            self.lastPoint = [recognizer locationInView:self.view];
            
            MHGalleryImageViewerViewController *detail = MHGalleryImageViewerViewController.new;
            detail.pageIndex = recognizer.indexPath.row;
            self.startScale = recognizer.scale/8;
            [self.navigationController pushViewController:detail
                                                 animated:YES];
        }else{
            recognizer.cancelsTouchesInView = YES;
        }
    }else if (recognizer.state == UIGestureRecognizerStateChanged) {
        
        if (recognizer.numberOfTouches <2) {
            recognizer.enabled = NO;
            recognizer.enabled = YES;
        }
        
        CGPoint point = [recognizer locationInView:self.view];
        self.interactivePushTransition.scale = recognizer.scale/8-self.startScale;
        self.interactivePushTransition.changedPoint = CGPointMake(self.lastPoint.x - point.x, self.lastPoint.y - point.y) ;
        [self.interactivePushTransition updateInteractiveTransition:scale];
        self.lastPoint = point;
    }else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        if (scale > 0.5) {
            [self.interactivePushTransition finishInteractiveTransition];
        }else {
            [self.interactivePushTransition cancelInteractiveTransition];
        }
        self.interactivePushTransition = nil;
    }
    
}


- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                         interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {
    if ([animationController isKindOfClass:MHTransitionShowDetail.class]) {
        return self.interactivePushTransition;
    }else {
        return nil;
    }
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController *)fromVC
                                                 toViewController:(UIViewController *)toVC {
    
    if (fromVC == self && [toVC isKindOfClass:MHGalleryImageViewerViewController.class]) {
        return MHTransitionShowDetail.new;
    }else {
        return nil;
    }
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationController.delegate = self;
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.navigationController.delegate == self) {
        self.navigationController.delegate = nil;
    }
}
-(void)pushToImageViewerForIndexPath:(NSIndexPath*)indexPath{
    
    MHGalleryImageViewerViewController *detail = MHGalleryImageViewerViewController.new;
    detail.pageIndex = indexPath.row;
    if ([self.navigationController isKindOfClass:MHGalleryController.class]) {
        [self.navigationController pushViewController:detail animated:YES];
        self.galleryViewController.imageViewerViewController = detail;
    }
}
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    __weak typeof(self) weakSelf = self;
    
    MHMediaPreviewCollectionViewCell *cell = (MHMediaPreviewCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    MHGalleryItem *item =  [self itemForIndex:indexPath.row];
    
    UIImage *thumbImage = [SDImageCache.sharedImageCache imageFromDiskCacheForKey:item.URLString];
    if (thumbImage) {
        cell.thumbnail.image = thumbImage;
    }
    if ([item.URLString rangeOfString:MHAssetLibrary].location != NSNotFound && item.URLString) {
        
        [MHGallerySharedManager.sharedManager getImageFromAssetLibrary:item.URLString
                                                             assetType:MHAssetImageTypeFull
                                                          successBlock:^(UIImage *image, NSError *error) {
                                                              cell.thumbnail.image = image;
                                                              [weakSelf pushToImageViewerForIndexPath:indexPath];
                                                          }];
    }else{
        [self pushToImageViewerForIndexPath:indexPath];
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    MHGalleryItem *item =  [self itemForIndex:indexPath.row];
    if (item.galleryType == MHGalleryTypeImage) {
        if ([NSStringFromSelector(action) isEqualToString:@"copy:"] || [NSStringFromSelector(action) isEqualToString:@"saveImage:"]){
            return YES;
        }
    }
    return NO;
}

-(void)getImageForItem:(MHGalleryItem*)item
        finishCallback:(void(^)(UIImage *image))FinishBlock{
    
    if (item.asset) {
        PHImageRequestOptions *options = [PHImageRequestOptions new];
        options.resizeMode = PHImageRequestOptionsResizeModeFast;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        [[PHImageManager defaultManager]  requestImageForAsset:item.asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            FinishBlock(result);
        }];
    } else {
        [SDWebImageManager.sharedManager downloadImageWithURL:[NSURL URLWithString:item.URLString]
                                                      options:SDWebImageContinueInBackground
                                                     progress:nil
                                                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                                        FinishBlock(image);
                                                    }];
    }
}
-(void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    
    
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender{
    if ([NSStringFromSelector(action) isEqualToString:@"copy:"]) {
        UIPasteboard *pasteBoard = [UIPasteboard pasteboardWithName:UIPasteboardNameGeneral create:NO];
        pasteBoard.persistent = YES;
        MHGalleryItem *item =  [self itemForIndex:indexPath.row];
        [self getImageForItem:item finishCallback:^(UIImage *image) {
            if (image) {
                UIPasteboard *pasteboard = UIPasteboard.generalPasteboard;
                if (image.images) {
                    NSData *data = [NSData dataWithContentsOfFile:[SDImageCache.sharedImageCache defaultCachePathForKey:item.URLString]];
                    [pasteboard setData:data forPasteboardType:(__bridge NSString *)kUTTypeGIF];
                }else{
                    NSData *data = UIImagePNGRepresentation(image);
                    [pasteboard setData:data forPasteboardType:(__bridge NSString *)kUTTypeImage];
                    
                }
            }
        }];
    }
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    self.collectionView.collectionViewLayout = [self layoutForOrientation:toInterfaceOrientation];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

@end
