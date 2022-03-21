#import <Foundation/Foundation.h>
#import <CoreWLAN/CoreWLANConstants.h>
#import <CoreWLAN/CoreWLANTypes.h>
#import <CoreWLAN/CoreWLAN.h>
#import <CoreLocation/CoreLocation.h>

#import "../wifi.hpp"

long get_channel_band( CWChannel *channel ) {

  auto channelBand = channel != nil ?
    [channel channelBand] : kCWChannelBandUnknown;

  switch( channelBand ) {
    case kCWChannelBandUnknown: return 0;
    case kCWChannelBand2GHz: return 2;
    case kCWChannelBand5GHz: return 5;
    default: return -1;
  }

}

long get_channel_width( CWChannel *channel ) {

  auto channelWidth = channel != nil ?
    [channel channelWidth] : kCWChannelWidthUnknown;

  switch( channelWidth ) {
    case kCWChannelWidthUnknown: return 0;
    case kCWChannelWidth20MHz: return 20;
    case kCWChannelWidth40MHz: return 40;
    case kCWChannelWidth80MHz: return 80;
    case kCWChannelWidth160MHz: return 160;
    default: return -1;
  }

}

std::vector<WifiNetwork> wifi_scan_networks() {

 CLLocationManager *mgr = [[CLLocationManager alloc] init];
 if (@available(macOS 10.15, *)) {
      [mgr requestAlwaysAuthorization];
      [mgr startUpdatingLocation];
      CWInterface* wifiInterface = [[CWWiFiClient sharedWiFiClient] interface];
      NSArray *wifiList = [[wifiInterface scanForNetworksWithName:nil error:nil] allObjects];
      std::vector<WifiNetwork> wifi_networks;
      CWChannel *channel;
          NSLog(@"Wi-Fi Info from sarp: %@", wifiInterface.bssid);

      for (CWNetwork *currentWifi in wifiList) {
          //NSString *wifiInfo = [NSString stringWithFormat:@"SSID:",
          //                      currentWifi];
          WifiNetwork wifi_network = WifiNetwork();
          channel = [currentWifi wlanChannel];

          wifi_network.ssid = [[currentWifi ssid] UTF8String] != nil ?
            [[currentWifi ssid] UTF8String] : "";

          wifi_network.bssid = [[currentWifi bssid] UTF8String] != nil ?
            [[currentWifi bssid] UTF8String] : "";
          wifi_network.connectedMAC = [[wifiInterface bssid] UTF8String] != nil ?
              [[wifiInterface bssid] UTF8String] : "";
          wifi_network.rssi = [currentWifi rssiValue];
          wifi_network.channel_number = channel != nil ? [channel channelNumber] : -1;
          wifi_network.channel_width = [channel channelWidth];
          wifi_networks.push_back( wifi_network );
      }
      return wifi_networks;
  } else {    
  CWChannel *channel;
  NSError *error;

  CWWiFiClient *client = [CWWiFiClient sharedWiFiClient];
  CWInterface *interface = [client interface];

  NSSet<CWNetwork *> *networks = [interface scanForNetworksWithSSID:nil includeHidden:true error:&error];
  std::vector<WifiNetwork> wifi_networks;

  if( error == nil ) {
    for( CWNetwork *network in networks ) {

      WifiNetwork wifi_network = WifiNetwork();
      channel = [network wlanChannel];

      wifi_network.ssid = [[network ssid] UTF8String] != nil ?
        [[network ssid] UTF8String] : "";

      wifi_network.bssid = [[network bssid] UTF8String] != nil ?
        [[network bssid] UTF8String] : "";
      wifi_network.beacon_interval = [network beaconInterval];
      wifi_network.noise = [network noiseMeasurement];
      wifi_network.rssi = [network rssiValue];
      wifi_network.channel_number = channel != nil ? [channel channelNumber] : -1;
      wifi_network.channel_band = get_channel_band( channel );
      wifi_network.channel_width = get_channel_width( channel );

      wifi_networks.push_back( wifi_network );

    }
  }
  return wifi_networks;
  }
}
