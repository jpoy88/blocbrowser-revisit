//
//  BLCWebBrowserViewController.m
//  BlocBrowser revisit
//
//  Created by John Patrick Adapon on 10/16/14.
//  Copyright (c) 2014 John Adapon. All rights reserved.
//

#import "BLCWebBrowserViewController.h"
#import "BLCAwesomeFloatingToolbar.h"

#define kBLCWebBrowsingBackString NSLocalizedString(@"Back", @"Back command")
#define kBLCWebBrowsingForwardString NSLocalizedString(@"Forward", @"Forward command")
#define kBLCWebBrowsingStopString NSLocalizedString(@"Stop", @"Stop command")
#define kBLCWebBrowsingRefreshString NSLocalizedString(@"Refresh", @"Reload command")

@interface BLCWebBrowserViewController () <UIWebViewDelegate, UITextFieldDelegate, BLCAwesomeFloatingToolbarDelegate>

@property (nonatomic, strong) UIWebView *webview;
@property (nonatomic, strong) UITextField *textField;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, assign) NSUInteger frameCount;

@property (nonatomic, strong) BLCAwesomeFloatingToolbar *awesomeToolbar;

@end

@implementation BLCWebBrowserViewController




#pragma mark - UIViewController

-(void)loadView {
    UIView *mainView = [UIView new];
    self.view = mainView;
    
    
    self.webview = [[UIWebView alloc] init];
    self.webview.delegate = self;
    
    
    self.textField = [[UITextField alloc] init];
    self.textField.keyboardType = UIKeyboardTypeURL;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.placeholder = NSLocalizedString(@"Website URL / Google Search", @"Placeholder text for web browser URL field");
    self.textField.backgroundColor = [UIColor colorWithWhite:220.0 / 255.0 alpha:1];
    self.textField.delegate = self;
    
    
    self.awesomeToolbar = [[BLCAwesomeFloatingToolbar alloc] initWithFourTitles:@[kBLCWebBrowsingBackString, kBLCWebBrowsingForwardString, kBLCWebBrowsingStopString, kBLCWebBrowsingRefreshString]];
    
    //[self.awesomeToolbar setEnabled:NO forButtonWithTitle:nil];
    self.awesomeToolbar.delegate = self;
    
    
    for (UIView *viewToAdd in @[self.webview, self.textField, self.awesomeToolbar]) {
        [mainView addSubview:viewToAdd];
    }
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    
    [self welcomeAlert];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    //self.webview.frame = self.view.frame;
    
    static const CGFloat itemHeight = 50;
    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat browserHeight = CGRectGetHeight(self.view.bounds) - itemHeight;
    
    
    self.textField.frame = CGRectMake(0, 0, width, itemHeight);
    self.webview.frame = CGRectMake(0, CGRectGetMaxY(self.textField.frame), width, browserHeight);
    
    self.awesomeToolbar.frame = CGRectMake(20, 100, 280, 60);

    
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    
    NSString *URLString = textField.text;
    
    NSURL *URL = [NSURL URLWithString:URLString];
    
    NSRange whiteSpace = [URLString rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
    
    
    if (whiteSpace.location != NSNotFound) {
        
        NSArray *deleteWhiteSpace = [URLString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *joinedForSearch = [deleteWhiteSpace componentsJoinedByString:@"+"];
        URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://google.com/search?q=%@", joinedForSearch]];
    }

    else if (!URL.scheme) {
        URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", URLString]];
    }
    
    
    if (URL) {
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        [self.webview loadRequest:request];
    }
    
    return NO;
}

#pragma mark - UIWebViewDelegate


- (void)webViewDidStartLoad:(UIWebView *)webView{
    self.frameCount ++;
    [self updateButtonsAndTitle];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    self.frameCount --;
    [self updateButtonsAndTitle];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    if (error.code != -999) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"error") message:[error localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles: nil];
        
        [alert show];
    }
    
    [self updateButtonsAndTitle];
    self.frameCount --;
}



#pragma mark - Miscellaneous

- (void) updateButtonsAndTitle {
 
    NSString *webpageTitle = [self.webview stringByEvaluatingJavaScriptFromString:@"document.title"];
    
    if (webpageTitle) {
        self.title = webpageTitle;
    } else {
        self.title = self.webview.request.URL.absoluteString;
    }
    
    if (self.frameCount > 0) {
        [self.activityIndicator startAnimating];
    }else {
        [self.activityIndicator stopAnimating];
    }
    
    
    [self.awesomeToolbar setEnabled:[self.webview canGoBack] forButtonWithTitle:kBLCWebBrowsingBackString];
    [self.awesomeToolbar setEnabled:[self.webview canGoForward] forButtonWithTitle:kBLCWebBrowsingForwardString];
    [self.awesomeToolbar setEnabled:self.frameCount > 0 forButtonWithTitle:kBLCWebBrowsingStopString];
    [self.awesomeToolbar setEnabled:self.webview.request.URL && self.frameCount == 0 forButtonWithTitle:kBLCWebBrowsingRefreshString];
    

}

- (void)resetWebView {
    [self.webview removeFromSuperview];
    
    UIWebView *newWebView = [[UIWebView alloc] init];
    newWebView.delegate = self;
    [self.view addSubview:newWebView];
    
    self.webview = newWebView;
    
    
    self.textField.text = nil;
    [self updateButtonsAndTitle];
    
    [self welcomeAlert];
}


-(void) welcomeAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Halo!", @"welcome message") message:NSLocalizedString(@"You are using a privately secured browser!", @"awesome message") delegate:nil cancelButtonTitle:NSLocalizedString(@"Let me use it!", @"excited customer confirmation") otherButtonTitles:nil];
    
    [alert show];
}

#pragma mark - BLCAwesomeFloatingToolbarDelegate


-(void) floatingToolbar:(BLCAwesomeFloatingToolbar *)toolbar didSelectButtonWithTitle:(NSString *)title{
    
    if([title isEqual:kBLCWebBrowsingBackString]){
        [self.webview goBack];
    }
    else if ([title isEqual:kBLCWebBrowsingForwardString]){
        [self.webview goForward];
    }
    else if ([title isEqual:kBLCWebBrowsingStopString]){
        [self.webview stopLoading];
    }
    else if ([title isEqual:kBLCWebBrowsingRefreshString]){
        [self.webview reload];
    }

    
}













@end
