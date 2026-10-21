// sketchybar-privacy: is any microphone or camera in use right now?
// Prints one JSON line, e.g. {"mic": true, "camera": false}, for the privacy
// items in configs/sketchybar (the twin of the macOS orange/green dots, which
// live in the hidden native menu bar). Public APIs only, no permission needed:
// Core Audio and CoreMediaIO report "device is running somewhere".
// Virtual audio devices are skipped: drivers like Background Music report
// "running" whenever their own app is open.

#include <CoreAudio/CoreAudio.h>
#include <CoreMediaIO/CMIOHardware.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

static bool has_input(AudioObjectID dev) {
  AudioObjectPropertyAddress a = {kAudioDevicePropertyStreams, kAudioObjectPropertyScopeInput,
                                  kAudioObjectPropertyElementMain};
  UInt32 size = 0;
  return AudioObjectGetPropertyDataSize(dev, &a, 0, NULL, &size) == noErr && size > 0;
}

static bool is_virtual(AudioObjectID dev) {
  AudioObjectPropertyAddress a = {kAudioDevicePropertyTransportType, kAudioObjectPropertyScopeGlobal,
                                  kAudioObjectPropertyElementMain};
  UInt32 type = 0, size = sizeof type;
  if (AudioObjectGetPropertyData(dev, &a, 0, NULL, &size, &type) != noErr) return false;
  return type == kAudioDeviceTransportTypeVirtual || type == kAudioDeviceTransportTypeAggregate;
}

static bool mic_in_use(void) {
  AudioObjectPropertyAddress a = {kAudioHardwarePropertyDevices, kAudioObjectPropertyScopeGlobal,
                                  kAudioObjectPropertyElementMain};
  UInt32 size = 0;
  if (AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &a, 0, NULL, &size) != noErr) return false;
  UInt32 n = size / sizeof(AudioObjectID);
  AudioObjectID *ids = malloc(size);
  bool used = false;
  if (ids && AudioObjectGetPropertyData(kAudioObjectSystemObject, &a, 0, NULL, &size, ids) == noErr) {
    for (UInt32 i = 0; i < n && !used; i++) {
      if (!has_input(ids[i]) || is_virtual(ids[i])) continue;
      AudioObjectPropertyAddress r = {kAudioDevicePropertyDeviceIsRunningSomewhere,
                                      kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMain};
      UInt32 running = 0, rsize = sizeof running;
      if (AudioObjectGetPropertyData(ids[i], &r, 0, NULL, &rsize, &running) == noErr && running) used = true;
    }
  }
  free(ids);
  return used;
}

static bool camera_in_use(void) {
  CMIOObjectPropertyAddress a = {kCMIOHardwarePropertyDevices, kCMIOObjectPropertyScopeGlobal,
                                 kCMIOObjectPropertyElementMain};
  UInt32 size = 0, used_size = 0;
  if (CMIOObjectGetPropertyDataSize(kCMIOObjectSystemObject, &a, 0, NULL, &size) != kCMIOHardwareNoError)
    return false;
  UInt32 n = size / sizeof(CMIOObjectID);
  CMIOObjectID *ids = malloc(size);
  bool used = false;
  if (ids && CMIOObjectGetPropertyData(kCMIOObjectSystemObject, &a, 0, NULL, size, &used_size, ids) ==
                 kCMIOHardwareNoError) {
    for (UInt32 i = 0; i < n && !used; i++) {
      CMIOObjectPropertyAddress r = {kCMIODevicePropertyDeviceIsRunningSomewhere,
                                     kCMIOObjectPropertyScopeGlobal, kCMIOObjectPropertyElementMain};
      UInt32 running = 0, got = 0;
      if (CMIOObjectGetPropertyData(ids[i], &r, 0, NULL, sizeof running, &got, &running) ==
              kCMIOHardwareNoError && running)
        used = true;
    }
  }
  free(ids);
  return used;
}

int main(void) {
  printf("{\"mic\": %s, \"camera\": %s}\n", mic_in_use() ? "true" : "false",
         camera_in_use() ? "true" : "false");
  return 0;
}
