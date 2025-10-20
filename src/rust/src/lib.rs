use std::os::raw::c_uint;

#[repr(C)]
pub struct OpmChip {
    _private: [u8; 0],
}

extern "C" {
    pub fn OPM_Reset(chip: *mut OpmChip);
    pub fn OPM_Write(chip: *mut OpmChip, port: c_uint, data: c_uint);
    pub fn OPM_Clock(chip: *mut OpmChip, buffer: *mut i16, frames: c_uint);
}

// このライブラリは他の言語から利用されることを想定
// Rustから使う場合のラッパーは別途実装可能
