#include <napi.h>
extern "C" {
    #include "opm.h"
}

// YM2151をNode.jsから利用可能にするラッパー
class YM2151Wrapper : public Napi::ObjectWrap<YM2151Wrapper> {
public:
    static Napi::Object Init(Napi::Env env, Napi::Object exports) {
        Napi::Function func = DefineClass(env, "YM2151", {
            InstanceMethod("reset", &YM2151Wrapper::Reset),
            InstanceMethod("write", &YM2151Wrapper::Write),
            InstanceMethod("clock", &YM2151Wrapper::Clock),
        });

        Napi::FunctionReference* constructor = new Napi::FunctionReference();
        *constructor = Napi::Persistent(func);
        env.SetInstanceData(constructor);

        exports.Set("YM2151", func);
        return exports;
    }

    YM2151Wrapper(const Napi::CallbackInfo& info) 
        : Napi::ObjectWrap<YM2151Wrapper>(info) {
        // チップの初期化
        OPM_Reset(&chip_);
    }

private:
    opm_t chip_;

    Napi::Value Reset(const Napi::CallbackInfo& info) {
        OPM_Reset(&chip_);
        return info.Env().Undefined();
    }

    Napi::Value Write(const Napi::CallbackInfo& info) {
        Napi::Env env = info.Env();
        uint32_t address = info[0].As<Napi::Number>().Uint32Value();
        uint32_t data = info[1].As<Napi::Number>().Uint32Value();
        OPM_Write(&chip_, address, data);
        return env.Undefined();
    }

    Napi::Value Clock(const Napi::CallbackInfo& info) {
        Napi::Env env = info.Env();
        uint32_t frames = info[0].As<Napi::Number>().Uint32Value();
        Napi::Buffer<int16_t> buffer = Napi::Buffer<int16_t>::New(env, frames * 2);
        OPM_Clock(&chip_, buffer.Data(), frames);
        return buffer;
    }
};

Napi::Object Init(Napi::Env env, Napi::Object exports) {
    return YM2151Wrapper::Init(env, exports);
}

NODE_API_MODULE(ym2151, Init)
