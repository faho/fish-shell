// Fish version receiver.
//
// This file has a specific purpose of shortening compilation times when
// the only change is different `git describe` version.
#include "fish_version.h"

#define FISH_BUILD_VERSION "7"

/// Return fish shell version.
const char *get_fish_version() { return FISH_BUILD_VERSION; }
