//
//  VRTHDRImageAsyncLoader.mm
//  React
//
//  Copyright © 2018 Viro Media. All rights reserved.
//

#import <React/RCTImageSource.h>
#import "VRTHDRImageAsyncLoader.h"
#import "VRTUtils.h"

@implementation VRTHDRImageAsyncLoader {
    NSURLSessionDataTask *_currentDownloadTask;
}

- (instancetype)initWithDelegate:(id<VRTHDRImageAsyncLoaderEventDelegate>)delegate {
    self = [super init];
    if(self) {
        _currentDownloadTask = nil;
        self.delegate = delegate;
    }
    return self;
}

- (void)cancel{
    if (_currentDownloadTask){
        [_currentDownloadTask cancel];
        _currentDownloadTask = nil;
    }
}

-(BOOL)isHdrSource:(RCTImageSource *)imageSource{
    NSURL *URL = imageSource.request.URL;
    NSString *fileExt = URL.pathExtension;
    return (fileExt && [fileExt isEqualToString:@"hdr"]);
}

-(void)loadHdrImage:(RCTImageSource *)imageSource {
    // Cancel the currently downloading task before initating a new one.
    [self cancel];

    if (self.delegate) {
        [self.delegate hdrImageLoaderDidStart:self];
    }

    // Determine if we are downloading a hdr file
    if (! [self isHdrSource:imageSource]){
        [self.delegate hdrImageLoaderDidEnd:self hdrTexture:nullptr];
        return;
    }

    // Start the HDR Download file.
    NSURL *URL = imageSource.request.URL;
    NSString *scheme = URL.scheme.lowercaseString;
    NSString *fileExt = URL.pathExtension;

    if([scheme isEqualToString:@"file"] || [scheme isEqualToString:@"http"] || [scheme isEqualToString:@"data"] ||  [scheme isEqualToString:@"https"]) {
        _currentDownloadTask = downloadDataWithURL(URL, ^(NSData *data, NSError *error) {
            if (error.code == NSURLErrorCancelled){
                // If we have cancelled this request, do nothing.
                // This is because multiple requests would be have been
                // fired as a result of the setting of props, but the
                // callback only needs to be triggered once
                // with the single final result.
                return;
            }

            // Persist the in-memory UIImage data onto a temporary file to be processed by renderer.
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"HH_mm_ss_sss"];
            NSString *dateString = [formatter stringFromDate:[NSDate date]];
            NSString *fileName = [NSString stringWithFormat:@"temp_%@_image.hdr", dateString];
            NSString *filePath = [self saveImageTempFile:data withName:fileName];

            // Process and generate a hdr texture from the downloaded image file.
            std::string filePathStr = std::string([filePath UTF8String]);
            std::shared_ptr<VROTexture> hdrTexture = VROHDRLoader::loadRadianceHDRTexture(filePathStr);

            // Clean up the temp file.
            [[NSFileManager defaultManager] removeItemAtPath:filePath error: nil];

            // Trigger callbacks.
            [self.delegate hdrImageLoaderDidEnd:self hdrTexture:hdrTexture];
            _currentDownloadTask = nil;
        });
    }
    else {
        NSLog(@"ERROR: Attempted to load image with unknown scheme path!");
        [self.delegate hdrImageLoaderDidEnd:self hdrTexture:nullptr];
    }
}

// Saves the image data in memory to a temporary file with the given file name
- (NSString *)saveImageTempFile:(NSData *)hdrData withName:(NSString *)name {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:name];
    [hdrData writeToFile:filePath atomically:YES];
    return filePath;
}

@end
