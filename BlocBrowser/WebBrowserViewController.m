//
//  WebBrowserViewController.m
//  BlocBrowser
//
//  Created by Andrew Carvajal on 12/13/14.
//  Copyright (c) 2014 graffme, Inc. All rights reserved.
//

#import "WebBrowserViewController.h"
#import "AwesomeFloatingToolbar.h"

#define WebBrowserBackString NSLocalizedString(@"Back", @"Back command")
#define WebBrowserForwardString NSLocalizedString(@"Forward", @"Forward command")
#define WebBrowserStopString NSLocalizedString(@"Stop", @"Stop command")
#define WebBrowserRefreshString NSLocalizedString(@"Refresh", @"Refresh command")

@interface WebBrowserViewController () <UIWebViewDelegate, UITextFieldDelegate, AwesomeFloatingToolbarDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UITextField *addressBar;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) AwesomeFloatingToolbar *awesomeToolbar;

@property (nonatomic, assign) NSUInteger frameCount;

@end

@implementation WebBrowserViewController

#pragma mark - UIViewController

- (void)loadView {

    // create view called mainView
    UIView *mainView = [UIView new];
    
    // instantiate and delegate webView
    self.webView = [[UIWebView alloc] init];
    self.webView.delegate = self;
    
    // create, instantiate, delegate and configure addressBar text field
    self.addressBar = [[UITextField alloc] init];
    self.addressBar.keyboardType = UIKeyboardTypeURL;
    self.addressBar.returnKeyType = UIReturnKeyDone;
    self.addressBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.addressBar.autocorrectionType = UITextAutocorrectionTypeNo;
    self.addressBar.placeholder = NSLocalizedString(@"Type a URL or search Google", @"Placeholder text for web browser URL field");
    self.addressBar.backgroundColor = [UIColor colorWithWhite:220/255.0f alpha:1];
    self.addressBar.delegate = self;
    
    self.awesomeToolbar = [[AwesomeFloatingToolbar alloc] initWithFourTitles:@[WebBrowserBackString, WebBrowserForwardString, WebBrowserStopString, WebBrowserRefreshString]];
    self.awesomeToolbar.delegate = self;
    
    // add all subviews to mainView
    for (UIView *viewToAdd in @[self.webView, self.addressBar, self.awesomeToolbar]) {
        [mainView addSubview:viewToAdd];
    }
    
    // set current view to mainView
    self.view = mainView;
    
//    self.awesomeToolbar.frame = CGRectMake(blanket, CGRectGetHeight(self.view.bounds) - blanket - itemHeight, CGRectGetWidth(self.view.bounds) - (blanket * 2), itemHeight);
    self.awesomeToolbar.frame = CGRectMake(20, 100, 200, 60);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // dont allow view to go under navigation bar
    self.edgesForExtendedLayout = UIRectEdgeNone;

    // add and configure activityIndicator
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    
    // display welcome alert
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Welcome!", @"Welcome title") message:NSLocalizedString(@"This is best browser", @"Welcome message") delegate:nil cancelButtonTitle:NSLocalizedString(@"Alright", @"Affirmation of welcome") otherButtonTitles:nil, nil];
    [alert show];
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    // First, calculate some dimensions.
    static const CGFloat itemHeight = 50;
    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat browserHeight = CGRectGetHeight(self.view.bounds) - itemHeight;
    
    // Now, assign the frames.
    self.addressBar.frame = CGRectMake(0, 0, width, itemHeight);
    self.webView.frame = CGRectMake(0, CGRectGetMaxY(self.addressBar.frame), width, browserHeight);
}

#pragma mark - AwesomeFloatingToolbarDelegate

-(void)floatingToolbar:(AwesomeFloatingToolbar *)toolbar didSelectButtonWithTitle:(NSString *)title {
    if ([title isEqual:WebBrowserBackString]) {
        [self.webView goBack];
    } else if ([title isEqual:WebBrowserForwardString]) {
        [self.webView goForward];
    } else if ([title isEqual:WebBrowserStopString]) {
        [self.webView stopLoading];
    } else if ([title isEqual:WebBrowserRefreshString]) {
        [self.webView reload];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"IT DOES NOT WORK" message:@"ERROR" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (void)floatingToolbar:(AwesomeFloatingToolbar *)toolbar didTryToPanWithOffset:(CGPoint *)offset {
    CGPoint startingPoint = toolbar.frame.origin;
    CGPoint newPoint = CGPointMake(startingPoint.x + offset->x, startingPoint.y + offset->y);
    
    CGRect potentialNewFrame = CGRectMake(newPoint.x, newPoint.y, CGRectGetWidth(toolbar.frame), CGRectGetHeight(toolbar.frame));
    
    if (CGRectContainsRect(self.view.bounds, potentialNewFrame)) {
        toolbar.frame = potentialNewFrame;
    }
}

- (void)floatingToolbar:(AwesomeFloatingToolbar *)toolbar didTryToPinchWithScale:(CGFloat)scale andVelocity:(CGFloat)velocity {
    CGRect potentialNewFrame = CGRectMake(toolbar.frame.origin.x, toolbar.frame.origin.y,
                                          toolbar.frame.size.width * scale, toolbar.frame.size.height * scale);
    
    if (CGRectContainsRect(self.view.bounds, potentialNewFrame)) {
        toolbar.frame = potentialNewFrame;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    // make a string from the text field
    NSString *URLString = textField.text;
    
    // make a URL from the string
    NSURL *URL = [NSURL URLWithString:URLString];
    
    // if the URL isn't in normal URL form...
    if (!URL.scheme) {
        
        // if there is a space typed
        if ([URLString containsString:@" "]) {
            
            // make a range for space
            NSRange spaceRange = [textField.text rangeOfString:@" "];
            
            // make a string by replacing spaces with pluses
            NSString *GoogleQuery = [textField.text stringByReplacingCharactersInRange:spaceRange withString:@"+"];
            
            // make a string combining the beginning of a Google search and the string with pluses
            NSString *GoogleString = [NSString stringWithFormat:@"http://www.google.com/search?q=%@", GoogleQuery];
            
            // the URL is now a proper Google search
            URL = [NSURL URLWithString:GoogleString];
            
        // if there is no dot typed
        } else if (![URLString containsString:@"."]) {
            
            // make a string that is in proper form to search Google
            NSString *GoogleString = [NSString stringWithFormat:@"http://www.google.com/search?q=%@", textField.text];
            
            // assign that string to URL
            URL = [NSURL URLWithString:GoogleString];
        } else {
            
            // fix format of URL
            URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", URLString]];
        }
    }
    
    // if URL exists
    if (URL) {
        
        // create a request with that URL
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        
        // load that request in webView
        [self.webView loadRequest:request];
    }
    return NO;
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
    // a frame was loaded so add 1 to frameCount
    self.frameCount++;
    
    // set the title, activity indicator, and buttons up
    [self updateButtonsAndTitle];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    // a frame finished loading so remove 1 from frameCount
    self.frameCount--;
    
    // set the title, activity indicator, and buttons up
    [self updateButtonsAndTitle];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
    // if the error code is not -999
    if (error.code != -999) {
        
        // create and set up an alert view for the error
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error") message:[error localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
        
        // show the error alert view
        [alert show];
    }
    
    // set the title, activity indicator, and buttons up
    [self updateButtonsAndTitle];
    
    // a frame finished loading so remove 1 from frameCount
    self.frameCount--;
}

#pragma mark - Miscellaneous

- (void)updateButtonsAndTitle {
    
    // make a string for the title by parsing the javascript
    NSString *webpageTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    
    // if webpageTitle exists
    if (webpageTitle) {
        
        // set the title to webpageTitle
        self.title = webpageTitle;
    } else {
        
        // set the title to the absoluteString of the URL request
        self.title = self.webView.request.URL.absoluteString;
    }
    
    // if frameCount is greater than 0
    if (self.frameCount > 0) {
        
        // start animating the activityIndicator
        [self.activityIndicator startAnimating];
    } else {
        
        // stop animating the activityIndicator
        [self.activityIndicator stopAnimating];
    }
    
    [self.awesomeToolbar setEnabled:[self.webView canGoBack] forButtonWithTitle:WebBrowserBackString];
    [self.awesomeToolbar setEnabled:[self.webView canGoForward] forButtonWithTitle:WebBrowserForwardString];
    [self.awesomeToolbar setEnabled:self.frameCount > 0 forButtonWithTitle:WebBrowserStopString];
    [self.awesomeToolbar setEnabled:self.webView.request.URL && self.frameCount == 0 forButtonWithTitle:WebBrowserRefreshString];
    
}

- (void)resetWebView {
    [self.webView removeFromSuperview];
    
    // create a new view, delegate it, and add it to the current view
    UIWebView *newWebView = [[UIWebView alloc] init];
    newWebView.delegate = self;
    [self.view addSubview:newWebView];
    
    // set webView to equal newWebView
    self.webView = newWebView;
    
    // reset the addressBar textField
    self.addressBar.text = nil;
    
    // set the title, activity indicator, and buttons up
    [self updateButtonsAndTitle];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
