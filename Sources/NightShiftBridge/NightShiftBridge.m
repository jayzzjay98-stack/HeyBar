#import <Foundation/Foundation.h>
#import "NightShiftBridge.h"

typedef struct {
    int hour;
    int minute;
} HSBTime;

typedef struct {
    HSBTime fromTime;
    HSBTime toTime;
} HSBSchedule;

typedef struct {
    BOOL active;
    BOOL enabled;
    BOOL sunSchedulePermitted;
    int mode;
    HSBSchedule schedule;
    unsigned long long disableFlags;
    BOOL available;
} HSBStatus;

@interface CBBlueLightClient : NSObject
+ (BOOL)supportsBlueLightReduction;
- (BOOL)setStrength:(float)strength commit:(BOOL)commit;
- (BOOL)setEnabled:(BOOL)enabled;
- (BOOL)getStrength:(float *)strength;
- (BOOL)getBlueLightStatus:(HSBStatus *)status;
@end

static Class HSBNightShiftClientClass(void) {
    static Class clientClass = Nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/CoreBrightness.framework"];
        [bundle load];
        clientClass = NSClassFromString(@"CBBlueLightClient");
    });
    return clientClass;
}

static CBBlueLightClient *HSBNightShiftClient(void) {
    static CBBlueLightClient *client = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class clientClass = HSBNightShiftClientClass();
        if (clientClass != Nil) {
            client = [[clientClass alloc] init];
        }
    });
    return client;
}

@interface KeyboardBrightnessClient : NSObject
- (BOOL)isAutoBrightnessEnabledForKeyboard:(unsigned long long)keyboardID;
- (BOOL)enableAutoBrightness:(BOOL)enabled forKeyboard:(unsigned long long)keyboardID;
- (BOOL)setBrightness:(float)brightness forKeyboard:(unsigned long long)keyboardID;
- (float)brightnessForKeyboard:(unsigned long long)keyboardID;
@end

static Class HSBKeyboardBrightnessClientClass(void) {
    static Class clientClass = Nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/CoreBrightness.framework"];
        [bundle load];
        clientClass = NSClassFromString(@"KeyboardBrightnessClient");
    });
    return clientClass;
}

static KeyboardBrightnessClient *HSBKeyboardBrightnessClient(void) {
    static KeyboardBrightnessClient *client = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class clientClass = HSBKeyboardBrightnessClientClass();
        if (clientClass != Nil) {
            client = [[clientClass alloc] init];
        }
    });
    return client;
}

bool HSBNightShiftIsSupported(void) {
    Class clientClass = HSBNightShiftClientClass();
    if (clientClass == Nil) {
        return false;
    }
    return [(id)clientClass supportsBlueLightReduction];
}

bool HSBNightShiftIsEnabled(void) {
    CBBlueLightClient *client = HSBNightShiftClient();
    if (client == nil) {
        return false;
    }

    HSBStatus status = {0};
    if (![client getBlueLightStatus:&status]) {
        return false;
    }
    return status.enabled;
}

bool HSBNightShiftSetEnabled(bool enabled) {
    CBBlueLightClient *client = HSBNightShiftClient();
    if (client == nil) {
        return false;
    }
    return [client setEnabled:enabled];
}

float HSBNightShiftGetStrength(void) {
    CBBlueLightClient *client = HSBNightShiftClient();
    if (client == nil) {
        return 0.5f;
    }

    float strength = 0.5f;
    if (![client getStrength:&strength]) {
        return 0.5f;
    }
    return strength;
}

bool HSBNightShiftSetStrength(float strength) {
    CBBlueLightClient *client = HSBNightShiftClient();
    if (client == nil) {
        return false;
    }

    float clamped = strength;
    if (clamped < 0.1f) {
        clamped = 0.1f;
    } else if (clamped > 1.0f) {
        clamped = 1.0f;
    }
    return [client setStrength:clamped commit:YES];
}

bool HSBKeyLightIsSupported(void) {
    return HSBKeyboardBrightnessClientClass() != Nil;
}

float HSBKeyLightGetBrightness(void) {
    KeyboardBrightnessClient *client = HSBKeyboardBrightnessClient();
    if (client == nil) {
        return 0.0f;
    }
    float brightness = [client brightnessForKeyboard:1];
    return brightness < 0.0f ? 0.0f : brightness;
}

bool HSBKeyLightSetBrightness(float brightness) {
    KeyboardBrightnessClient *client = HSBKeyboardBrightnessClient();
    if (client == nil) {
        return false;
    }

    float clamped = brightness;
    if (clamped < 0.0f) {
        clamped = 0.0f;
    } else if (clamped > 1.0f) {
        clamped = 1.0f;
    }
    return [client setBrightness:clamped forKeyboard:1];
}

bool HSBKeyLightIsAutoBrightnessEnabled(void) {
    KeyboardBrightnessClient *client = HSBKeyboardBrightnessClient();
    if (client == nil) {
        return false;
    }
    return [client isAutoBrightnessEnabledForKeyboard:1];
}

bool HSBKeyLightSetAutoBrightnessEnabled(bool enabled) {
    KeyboardBrightnessClient *client = HSBKeyboardBrightnessClient();
    if (client == nil) {
        return false;
    }
    return [client enableAutoBrightness:enabled forKeyboard:1];
}
