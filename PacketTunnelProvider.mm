#import <NetworkExtension/NetworkExtension.h>

@interface PacketTunnelProvider : NEPacketTunnelProvider
@end

@implementation PacketTunnelProvider

- (void)startTunnelWithOptions:(NSDictionary *)options
             completionHandler:(void (^)(NSError *error))completionHandler {

    NSLog(@"[VPN] Tunnel started");
    completionHandler(nil);
}

- (void)handleAppMessage:(NSData *)messageData
        completionHandler:(void (^)(NSData *responseData))completionHandler {

    NSDictionary *msg =
    [NSJSONSerialization JSONObjectWithData:messageData options:0 error:nil];

    NSInteger rate = [msg[@"rate"] integerValue];
    NSString *mode = msg[@"mode"];

    NSLog(@"[VPN] Received rate: %ld mode: %@", (long)rate, mode);

    // TODO: xử lý throttle tại đây

    completionHandler(nil);
}

@end