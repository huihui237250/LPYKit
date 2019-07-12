//
//  BaseJsonViewManager.h
//  PYKit
//
//  Created by 李鹏跃 on 2018/9/11.
//  Copyright © 2018年 13lipengyue. All rights reserved.
//


#import "BaseJsonViewTableView.h"
#import "BaseJsonViewTableViewCell.h"
#import "BaseObjectHeaders.h"
#import "BaseJsonViewSearchView.h"
#import "BaseObjectHeaders.h"
#import "BaseViewHeaders.h"
#import "BaseSize.h"

static NSString *const kBaseJsonViewTableViewCellId = @"kBaseJsonViewTableViewCellId";

@interface BaseJsonViewTableView()
<
UITableViewDelegate,
UITableViewDataSource
>

@property (nonatomic,strong) NSMutableArray <BaseJsonViewStepModel*>* modelArray;
@property (nonatomic,strong) BaseJsonViewStepModel *currentSearchModel;
@property (nonatomic,strong) NSMutableArray <BaseJsonViewStepModel*>* searchResultModelArray;
/// 剪切板
@property (nonatomic,strong) UIPasteboard *pasteboard;
@end

@implementation BaseJsonViewTableView
- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    if (self = [super initWithFrame:frame style:style]) {
        self.isAutoClose = true;
        [self setupViews];
    }
    return self;
}

- (void) setupViews {
    self.delegate = self;
    self.dataSource = self;
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self registerClass:BaseJsonViewTableViewCell.class forCellReuseIdentifier:kBaseJsonViewTableViewCellId];
}

- (NSMutableArray<BaseJsonViewStepModel *> *)modelArray {
    if (!_modelArray) {
        _modelArray = [[NSMutableArray alloc]init];
    }
    return _modelArray;
}

- (void) scrollToModel: (BaseJsonViewStepModel *)model {
    NSInteger row = [self.modelArray indexOfObject:model];
    if (row > self.modelArray.count) {
        return;
    }
    if (row < 0) {
        return;
    }
    self.currentSearchModel = model;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    [self reloadData];
    [self scrollToRowAtIndexPath:indexPath  atScrollPosition:UITableViewScrollPositionTop animated:true];
   
}

// MARK: - get && set
- (void)setModel:(BaseJsonViewStepModel *)model {
    _model = model;
    self.modelArray = [model faltSelfDataIfOpen].mutableCopy;
    [self reloadData];
}

- (NSMutableArray <BaseJsonViewStepModel *>*) searchAndOpenAllWithKey: (NSString *)key {
    
    [self.model openAll];
    self.model = self.model;
    NSMutableArray <BaseJsonViewStepModel *>*arrayM = [NSMutableArray new];
    if (key.length > 0) {
        [self.modelArray enumerateObjectsUsingBlock:^(BaseJsonViewStepModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            BOOL isTrue = self.isAccurateSearch ? [obj.key isEqualToString:key]: [obj.key containsString:key];
            if (isTrue) {
                [arrayM addObject:obj];
            }else{
                if ([obj.data isKindOfClass:NSString.class]) {
                    NSString *data = obj.data;
                    BOOL isTrue = self.isAccurateSearch ? [data isEqualToString:key]: [data containsString:key];
                    if (isTrue) {
                        [arrayM addObject:obj];
                    }
                }
            }
        }];
    }
    self.searchResultModelArray = arrayM;
    [self.model closeAll];
    
    [arrayM enumerateObjectsUsingBlock:^(BaseJsonViewStepModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BaseJsonViewStepModel *model = obj;
        obj.isOpen = true;
        while (model.superPoint) {
            model.isOpen = true;
            model = model.superPoint;
        }
    }];
    self.model = self.model;
    return arrayM;
}

#pragma mark - dataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
       return self.modelArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id cellAny = [tableView dequeueReusableCellWithIdentifier:kBaseJsonViewTableViewCellId forIndexPath:indexPath];
    if ([cellAny isKindOfClass:BaseJsonViewTableViewCell.class]) {
        BaseJsonViewTableViewCell *cell = cellAny;
        cell.model = self.modelArray[indexPath.row];
        cell.indexPath = indexPath;
        BOOL isSearchReulst = [self.searchResultModelArray containsObject:self.modelArray[indexPath.row]];
        BOOL isCurrentSearchResult = [cell.model isEqual:self.currentSearchModel];
        [cell setUpBackgroundColorWithIsSearchResultColor:isSearchReulst andIsCurrentSearchResult: isCurrentSearchResult];
        
        [self registerCellEventsWithCell: cell];
        
    }
    return cellAny;
}

- (void) registerCellEventsWithCell: (BaseJsonViewTableViewCell *) cell {
    __weak typeof(self)weakSelf = self;
    [cell setSingleTapBlock:^(BaseJsonViewTableViewCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath) {
        [weakSelf handleSingleTapActionWithMessage: cell];
    }];
    [cell setLongAction:^(BaseJsonViewTableViewCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath) {
        [weakSelf handleLongActionWithCell: cell andIndexPath: indexPath];
    }];
    [cell setDoubleAction:^(BaseJsonViewTableViewCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath) {
        [weakSelf handleDoubleActionWithCell:cell andIndexPath: indexPath];
    }];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath{
    BaseJsonViewStepModel *model = self.modelArray[indexPath.row];
    UITableViewRowAction *copyAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"复制json" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [self.pasteboard setString:[model conversionToJson]];
    }];
    UITableViewRowAction *copyStrAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"复制value" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        if ([model.data isKindOfClass:NSString.class]) {
            [self.pasteboard setString: (NSString *)model.data];
        }
    }];
    
    UITableViewRowAction *editAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"编辑" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
    }];
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"删除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
    }];
    editAction.backgroundColor = [UIColor colorWithRed:0.8 green:0.9 blue:0.8 alpha:1];
    copyAction.backgroundColor = [UIColor colorWithRed:0.6 green:0.7 blue:0.6 alpha:1];
    copyStrAction.backgroundColor = [UIColor colorWithRed:0.4 green:0.5 blue:0.4 alpha:1];
    deleteAction.backgroundColor = [UIColor colorWithRed:0.9 green:0.8 blue:0.8 alpha:1];
    if (self.modelArray[indexPath.row].type == BaseJsonViewStepModelType_Number ||
        self.modelArray[indexPath.row].type == BaseJsonViewStepModelType_String) {
        return @[copyStrAction,copyAction,editAction,deleteAction];
    }
    return @[copyAction, editAction,deleteAction];
}


// 单击功能
- (void) handleSingleTapActionWithMessage: (id)message {
    /// 展开 或 收起
    if ([message isKindOfClass:BaseJsonViewTableViewCell.class]) {
        BaseJsonViewTableViewCell *cell = message;
        [self closeWithModel:cell.model andIsOpen:!cell.model.isOpen];
    }
}

- (void) closeWithModel: (BaseJsonViewStepModel *)model andIsOpen:(BOOL)isOpen {
    model.isOpen = isOpen;
    NSArray *array = [model faltSelfDataIfOpen];
    NSInteger index = [self.modelArray indexOfObject:model];
    if (isOpen) {
        NSRange range = NSMakeRange(index + 1, [array count]);
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
        [self.modelArray insertObjects:array atIndexes:indexSet];
    }else{
        [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (self.isAutoClose) {
                [obj closeAll];
            }
            [self.modelArray removeObject:obj];
        }];
        if (self.isAutoClose) {
            [model closeAll];
        }
    }
    [self reloadData];
}

- (void) handleLongActionWithCell:(BaseJsonViewTableViewCell *)cell andIndexPath: (NSIndexPath *)indexPath {
}

- (void) handleDoubleActionWithCell:(BaseJsonViewTableViewCell *)cell andIndexPath: (NSIndexPath *)indexPath {
    if (self.doubleClickCellBlock) {
        self.doubleClickCellBlock(cell.model);
    }
}

- (UIPasteboard *)pasteboard {
    if (!_pasteboard) {
        _pasteboard = [UIPasteboard generalPasteboard];
    }
    return _pasteboard;
}
#pragma mark - delegate

@end