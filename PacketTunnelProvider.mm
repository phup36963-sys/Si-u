#import <NetworkExtension/NetworkExtension.h>

@interface PacketTunnelProvider : NEPacketTunnelProvider
@property (nonatomic, assign) NSInteger blockRate;
@property (nonatomic, strong) NSString *blockMode;
@end

@implementation PacketTunnelProvider

#pragma mark - Start VPN

- (void)startTunnelWithOptions:(NSDictionary *)options
             completionHandler:(void (^)(NSError *error))completionHandler {

    NSLog(@"[VPN] Tunnel starting...");

    // Đọc config từ AppGroup
    NSUserDefaults *defaults =
    [[NSUserDefaults alloc] initWithSuiteName:@"group.com.netping.shared"];

    self.blockRate = [defaults integerForKey:@"blockRate"];
    self.blockMode = [defaults stringForKey:@"blockMode"] ?: @"OFF";

    NSLog(@"[VPN] Config loaded rate=%ld mode=%@",
          (long)self.blockRate, self.blockMode);

    // Tạo network settings
    NEPacketTunnelNetworkSettings *settings =
    [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:@"8.8.8.8"];

    NEIPv4Settings *ipv4 =
    [[NEIPv4Settings alloc] initWithAddresses:@[@"10.0.0.2"]
                                  subnetMasks:@[@"255.255.255.0"]];

    ipv4.includedRoutes = @[[NEIPv4Route defaultRoute]];
    settings.IPv4Settings = ipv4;

    [self setTunnelNetworkSettings:settings completionHandler:^(NSError *error) {

        if (error) {
            NSLog(@"[VPN] Settings error: %@", error);
            completionHandler(error);
            return;
        }

        NSLog(@"[VPN] Tunnel ready");

        [self startPacketLoop];

        completionHandler(nil);
    }];
}

#pragma mark - Packet Loop

- (void)startPacketLoop {

    [self.packetFlow readPacketsWithCompletionHandler:
     ^(NSArray<NSData *> *packets, NSArray<NSNumber *> *protocols) {

        NSMutableArray *outPackets = [NSMutableArray array];
        NSMutableArray *outProtocols = [NSMutableArray array];

        for (int i = 0; i < packets.count; i++) {

            NSData *packet = packets[i];
            NSNumber *proto = protocols[i];

            BOOL drop = [self shouldDropPacketWithProtocol:proto];

            if (!drop) {
                [outPackets addObject:packet];
                [outProtocols addObject:proto];
            }
        }

        if (outPackets.count > 0) {
            [self.packetFlow writePackets:outPackets
                           withProtocols:outProtocols];
        }

        // Loop lại
        [self startPacketLoop];
    }];
}

#pragma mark - Drop Logic

- (BOOL)shouldDropPacketWithProtocol:(NSNumber *)proto {

    if (self.blockRate <= 0 || [self.blockMode isEqualToString:@"OFF"])
        return NO;

    int random = arc4random_uniform(100);

    if (random < self.blockRate) {

        if ([self.blockMode isEqualToString:@"ALL"])
            return YES;

        if ([self.blockMode isEqualToString:@"TCP"] &&
            proto.intValue == AF_INET) // đơn giản hóa
            return YES;
    }

    return NO;
}

#pragma mark - Stop

- (void)stopTunnelWithReason:(NEProviderStopReason)reason
           completionHandler:(void (^)(void))completionHandler {

    NSLog(@"[VPN] Tunnel stopped");
    completionHandler();
}

@end