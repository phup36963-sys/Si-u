#import <JavaScriptCore/JavaScriptCore.h>

@protocol h5ggJSExport <JSExport>
- (void)searchNumber:(NSString *)arg1 param2:(NSString *)arg2 param3:(NSString *)arg3 param4:(NSString *)arg4;
- (void)setFloatTolerance:(NSString *)arg1;
- (int)editAll:(NSString *)arg1 param3:(NSString *)arg2;
- (void)clearResults;
- (_Bool)require:(double)arg1;
- (_Bool)unlockMemoryEngine:(NSString *)key; // Hàm bảo mật chống văng
@end
