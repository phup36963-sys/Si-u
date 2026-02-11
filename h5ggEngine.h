#import <objc/NSObject.h>
#import "h5ggJSExport.h"

@interface h5ggEngine : NSObject <h5ggJSExport>
{
    _Bool _firstSearchDone;
    int _targetpid;
    unsigned int _targetport;
    void *_engine;
    NSString *_lastSearchType;
}

@property unsigned int targetport;
@property int targetpid;
@property _Bool firstSearchDone;
@property(retain) NSString *lastSearchType;
@property void *engine;

- (void)searchNumber:(id)arg1 param2:(id)arg2 param3:(id)arg3 param4:(id)arg4;
- (void)setFloatTolerance:(id)arg1;
- (void)clearResults;
- (int)editAll:(id)arg1 param3:(id)arg2;
- (_Bool)setTargetProc:(int)arg1;
- (id)getProcList:(id)arg1;
- (_Bool)require:(double)arg1;
- (id)init;
@end
