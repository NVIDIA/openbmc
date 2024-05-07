#include <fstream>

#include "transporthandler.hpp"

using phosphor::logging::level;
using phosphor::logging::log;

namespace ipmi {
namespace transport {

constexpr auto transportLinkSpeedParameter = 206;
constexpr auto transportLinkSpeedPath = "/sys/class/net/eth0/speed";
constexpr auto transportLinkDuplexPath = "/sys/class/net/eth0/duplex";
constexpr auto transportLinkindexPath = "/sys/class/net/eth0/ifindex";

RspType<> setLanOem([[maybe_unused]] uint8_t channel, [[maybe_unused]] uint8_t parameter, message::Payload& req)
{
    req.trailingOk = true;
    return response(ccParamNotSupported);
}

template <class T>
static bool catFile(std::string path, T &ret) {
    std::ifstream st(path);
    if (!st.is_open()) {
        return false;
    }
    st >> ret;
    return true;
}

RspType<message::Payload> getLanOem([[maybe_unused]] uint8_t channel, uint8_t parameter,
                                    [[maybe_unused]] uint8_t set, [[maybe_unused]] uint8_t block)
{
    message::Payload ret;
    switch (parameter) {
        case transportLinkSpeedParameter: {
            uint16_t speed;
            std::string duplexStr;
            uint8_t duplex = 0;
            int idx = 0;
            if (!catFile<uint16_t>(transportLinkSpeedPath, speed)) {
                log<level::ERR>("Failed to open eth0 speed file node");
                return response(ccResponseError);
            }
            if (!catFile<std::string>(transportLinkDuplexPath, duplexStr)) {
                log<level::ERR>("Failed to open eth0 duplex file node");
                return response(ccResponseError);
            }
            if (duplexStr == "full") {
                duplex = 1;
            }
            if (!catFile<int>(transportLinkindexPath, idx)) {
                log<level::ERR>("Failed to open eth0 index file node");
                return response(ccResponseError);
            }
            ret.pack(static_cast<uint8_t>(0x00)); /* not spec'd */
            ret.pack(static_cast<uint8_t>(0x01)); /* auto speed neg */
            ret.pack(static_cast<uint16_t>(speed)); /* speed */
            ret.pack(static_cast<uint8_t>(duplex)); /* duplex */
            ret.pack(static_cast<uint8_t>(idx)); /* index */
            ret.pack(static_cast<uint8_t>(0x00)); /* capablities */
            return responseSuccess(std::move(ret));
        }
    }
    return response(transport::ccParamNotSupported);
}

}
}

