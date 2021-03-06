//
//  V2EXTopicsListInSingleNodeViewController.m
//  V2EX
//
//  Created by WildCat on 2/16/14.
//  Copyright (c) 2014 WildCat. All rights reserved.
//

#import "TFHpple+V2EXMethod.h"
#import "V2EXTopicsListInSingleNodeViewController.h"
#import "V2EXTopicsListCell.h"
#import "V2EXNormalModel.h"
#import "V2EXMBProgressHUDUtil.h"
#import "V2EXStringUtil.h"
#import "V2EXNewTopicViewController.h"

@interface V2EXTopicsListInSingleNodeViewController ()

@end

@implementation V2EXTopicsListInSingleNodeViewController

//+ (V2EXTopicsListInSingleNodeViewController *)sharedController
//{
//    static V2EXTopicsListInSingleNodeViewController *_sharedTopicsListInSingleNodeViewControllerInstance = nil;
//    static dispatch_once_t predicate;
//    dispatch_once(&predicate, ^{
//        _sharedTopicsListInSingleNodeViewControllerInstance = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"topicListInSingleNodeController"];
//    });
//    
//    return _sharedTopicsListInSingleNodeViewControllerInstance;
//}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.rowHeight = 70; // TODO: Why don't storyboard with identifiertopicListInSingleNodeController support rowHeight?
    _loadingStatus = 1;
    
//    self.singleTopicViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"singleTopicController"];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void)viewWillAppear:(BOOL)animated {
//}


- (void)loadNewNodeWithData:(NSData *)data {
    // Reload data
    _loadingStatus = 1;
    [self requestDataSuccess:data];
    
    // Scroll to the top
//    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

- (void)loadData {
    if ([self canStartNewLoading]) {
        _loadingStatus = 1;
        [self.model getTopicsList:self.uri];
    }
}

- (void)loadTopic:(NSUInteger)ID {
    if ([self canStartNewLoading]) {
        _loadingStatus = 2;
        [self showProgressView];
        
        [self.model getTopicWithID:ID];
    }
}

- (void)requestDataSuccess:(id)dataObject {
    if (_loadingStatus == 1) {
        [self handleListData:dataObject];
    } else {
        [self pushToSingleTopicViewController:dataObject];
    }
    [super requestDataSuccess:dataObject];

}


- (void)requestDataFailure:(NSString *)errorMessage {
    [super requestDataFailure:errorMessage];
}

- (void) handleListData:(id)dataObject {
    self.data = [[NSMutableArray alloc] init];
    
    TFHpple *doc = [[TFHpple alloc]initWithHTMLData:dataObject];
    
    //Check login
    _isLogin = [doc checkLogin];
    
    //Topic list data
    NSString *allHtml = [[doc searchFirstElementWithXPathQuery:@"//div[@class='header']"] raw];
    NSString *delDiv = [[doc searchFirstElementWithXPathQuery:@"//div[@class='header']/div"] raw];
    NSString *delA = [[doc searchFirstElementWithXPathQuery:@"//div[@class='header']/a"] raw];
    NSString *delSpan = [[doc searchFirstElementWithXPathQuery:@"//div[@class='header']/span"] raw];
    NSString *delDiv2 = [[doc searchFirstElementWithXPathQuery:@"//div[@class='header']/div[@class='sep5']"] raw];
    NSString *delDiv3 = [[doc searchFirstElementWithXPathQuery:@"//div[@class='header']/div[@align='right']"] raw];
    NSString *title = [[[[[[[allHtml stringByReplacingOccurrencesOfString:delDiv withString:@""]
                          stringByReplacingOccurrencesOfString:delA withString:@""]
                         stringByReplacingOccurrencesOfString:delSpan withString:@""]
                        stringByReplacingOccurrencesOfString:@"\n    \n    </div>" withString:@""]
                       stringByReplacingOccurrencesOfString:@"<div class=\"header\">  " withString:@""]
                       stringByReplacingOccurrencesOfString:delDiv2 withString:@""]
                       stringByReplacingOccurrencesOfString:delDiv3 withString:@""];
    self.navigationItem.title = title;

    // Data Rows
    NSArray *elements = [doc searchWithXPathQuery:@"//body/div[2]/div/div/div[@class='cell']/table[1]"];
    
    for (TFHppleElement *element in elements) {
        TFHppleElement *avatarElement = [element searchFirstElementWithXPathQuery:@"//td[1]/a/img"];
        TFHppleElement *titleElement = [element searchFirstElementWithXPathQuery:@"//td[3]/span[@class='item_title']/a"];
        TFHppleElement *userNameElement = [element searchFirstElementWithXPathQuery:@"//td[3]/span[@class='small fade']/strong"];
        NSArray *replyElements = [element searchWithXPathQuery:@"//td[4]/a"];
        
        // Handle reply count
        NSString *replyCount;
        if ([replyElements count] > 0)
        {
            TFHppleElement *replyElement = [replyElements objectAtIndex:0];
            replyCount = [replyElement text];
        } else {
            replyCount = @"0";
        }
        
        NSString *link = [[element searchFirstElementWithXPathQuery:@"//td[3]/span[@class='item_title']/a"] objectForKey:@"href"];
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [V2EXStringUtil hanldeAvatarURL:[avatarElement objectForKey:@"src"]], @"avatar",
                              [titleElement text], @"title",
                              [userNameElement text], @"username",
                              replyCount, @"replies",
                              link, @"link", nil
                              ];
        [self.data addObject:dict];
    }
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger index = [indexPath row];
    static NSString *CellIdentifier = @"topicsListCell";
    
    UINib *nib = [UINib nibWithNibName:@"V2EXTopicsListCell" bundle:nil];
    [tableView registerNib:nib forCellReuseIdentifier:CellIdentifier];
    
    V2EXTopicsListCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    id rowData = [self.data objectAtIndex:index];
    
    cell.title.text = [rowData valueForKey:@"title"];
    cell.nodeTitle.text = @"";
    cell.replies.text = [rowData valueForKey:@"replies"];
    cell.username.text = [rowData valueForKey:@"username"];
    [cell.userAvatar setImageWithURL:[NSURL URLWithString:[rowData valueForKey:@"avatar"]] placeholderImage:[UIImage imageNamed:@"avatar_large"]];
    
    return cell;
}

- (NSUInteger)link2TopicID:(NSString *) urlString{
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"/t/[0-9]+#reply"
                                                                           options:0
                                                                            error:&error];
    if (regex != nil) {
        NSArray *array = [regex matchesInString: urlString
                                        options: 0
                                          range: NSMakeRange( 0, [urlString length])];
        if ([array count] > 0) {
            NSTextCheckingResult *match = [array objectAtIndex:0];
            NSRange firstHalfRange = [match rangeAtIndex:0];
            NSString *result = [[[urlString substringWithRange:firstHalfRange] stringByReplacingOccurrencesOfString:@"/t/" withString:@""] stringByReplacingOccurrencesOfString:@"#reply" withString:@""];
            return (NSUInteger)[result integerValue];
        } else {
            return 0;
        }
    } else {
        return 0;
    }
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger topicID = [self link2TopicID:[[self.data objectAtIndex:[indexPath row]] objectForKey:@"link"]];
    _topicIDWillBePushedTo = topicID;
    [self loadTopic:topicID];
}

#pragma mark - Segue
- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"toNewTopicController"]) {
        if (_isLogin) {
            return YES;
        }
    }
    [self showMessage:@"无法回复，可能因为您尚未登录"];
    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"toNewTopicController"]) {
        V2EXNewTopicViewController *newTopicController = [segue destinationViewController];
        newTopicController.uri = self.uri;
        newTopicController.lastController = self;
    }
}

#pragma mark - After Post New Topic
- (void)afterCreateTopic:(NSData *)data {
    TFHpple *doc = [[TFHpple alloc] initWithHTMLData:data];
    NSUInteger topicID = (NSUInteger)[[[[doc searchFirstElementWithXPathQuery:@"//form"] objectForKey:@"action"] stringByReplacingOccurrencesOfString:@"/t/" withString:@""] integerValue];
    if (topicID > 0) {
        [self showMessage:@"新主题已创建"];
        [self pushToSingleTopicViewController:data];
    } else {
        [self showMessage:@"主题发布失败"];
    }
}

@end
