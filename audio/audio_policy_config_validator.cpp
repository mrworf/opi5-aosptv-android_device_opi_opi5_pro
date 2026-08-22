#include <iostream>
#include <string>

#include <system/audio.h>

#include "core-impl/AudioPolicyConfigXmlConverter.h"

using aidl::android::hardware::audio::core::internal::AudioPolicyConfigXmlConverter;

int main(int argc, char** argv) {
    if (argc != 2) {
        std::cerr << "usage: opi_audio_policy_validator CONFIG_XML\n";
        return 2;
    }

    AudioPolicyConfigXmlConverter converter(argv[1]);
    if (converter.getStatus() != ::android::OK) {
        std::cerr << "XML parse failed: " << converter.getError() << "\n";
        return 1;
    }

    auto modules = converter.releaseModuleConfigs();
    if (modules == nullptr || modules->empty()) {
        std::cerr << "configuration contains no audio modules\n";
        return 1;
    }

    std::cout << "validated " << modules->size() << " audio modules\n";
    return 0;
}
