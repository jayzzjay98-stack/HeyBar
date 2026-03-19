#ifndef NIGHT_SHIFT_BRIDGE_H
#define NIGHT_SHIFT_BRIDGE_H

#include <stdbool.h>

bool HSBNightShiftIsSupported(void);
bool HSBNightShiftIsEnabled(void);
bool HSBNightShiftSetEnabled(bool enabled);
float HSBNightShiftGetStrength(void);
bool HSBNightShiftSetStrength(float strength);

bool HSBKeyLightIsSupported(void);
float HSBKeyLightGetBrightness(void);
bool HSBKeyLightSetBrightness(float brightness);
bool HSBKeyLightIsAutoBrightnessEnabled(void);
bool HSBKeyLightSetAutoBrightnessEnabled(bool enabled);

#endif
