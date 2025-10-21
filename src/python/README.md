# Python Nuked-OPM Library

公式Nuked-OPM (https://github.com/nukeykt/Nuked-OPM) をWindows向けにビルドし、Pythonからctypes経由で利用可能な動的ライブラリを生成します。

## 重要: このライブラリについて

このライブラリは**公式Nuked-OPMのビルド成果物**であり、カスタムラッパーではありません。
すべての関数は公式opm.hで定義されているものと同じシグネチャで提供されます。

## ビルド方法

```bash
# リポジトリのルートから実行
bash scripts/build_python.sh
```

このスクリプトは以下を実行します：
1. Nuked-OPMをvendor/nuked-opmにクローン（未取得の場合）
2. Makefileを使用してnukedopm.dllをビルド（静的リンク）

## 成果物

- `nukedopm.dll` - 動的ライブラリ（mingw DLL依存なし）

**後方互換性のため**: ビルドスクリプトは `ym2151.dll` という名前でもコピーを作成します。
ただし、新しいプロジェクトでは `nukedopm.dll` を使用することを推奨します。

## 前提条件

- mingw-w64 (`x86_64-w64-mingw32-gcc`)
- make

## 利用方法（公式API）

Pythonからctypes経由で公式Nuked-OPM APIを使用：

```python
import ctypes

# DLLのロード
lib = ctypes.CDLL('./nukedopm.dll')

# 公式Nuked-OPM APIシグネチャ（opm.hより）
class opm_t(ctypes.Structure):
    # 構造体は大きいため、不透明型として扱う
    _fields_ = [("_data", ctypes.c_byte * 4096)]

# 関数シグネチャの定義（公式API）
lib.OPM_Reset.argtypes = [ctypes.POINTER(opm_t)]
lib.OPM_Reset.restype = None

lib.OPM_Write.argtypes = [ctypes.POINTER(opm_t), ctypes.c_uint32, ctypes.c_uint8]
lib.OPM_Write.restype = None

lib.OPM_Clock.argtypes = [
    ctypes.POINTER(opm_t),
    ctypes.POINTER(ctypes.c_int32),  # int32_t *output (stereo: 2 elements)
    ctypes.POINTER(ctypes.c_uint8),  # uint8_t *sh1
    ctypes.POINTER(ctypes.c_uint8),  # uint8_t *sh2
    ctypes.POINTER(ctypes.c_uint8)   # uint8_t *so
]
lib.OPM_Clock.restype = None

lib.OPM_Read.argtypes = [ctypes.POINTER(opm_t), ctypes.c_uint32]
lib.OPM_Read.restype = ctypes.c_uint8

# 使用例
chip = opm_t()
lib.OPM_Reset(ctypes.byref(chip))

# レジスタへの書き込み
lib.OPM_Write(ctypes.byref(chip), 0, 0x20)  # address
lib.OPM_Write(ctypes.byref(chip), 1, 0xC0)  # data

# サンプル生成
output = (ctypes.c_int32 * 2)()
sh1 = ctypes.c_uint8()
sh2 = ctypes.c_uint8()
so = ctypes.c_uint8()
lib.OPM_Clock(ctypes.byref(chip), output, ctypes.byref(sh1), ctypes.byref(sh2), ctypes.byref(so))
```

詳細なAPIドキュメントは公式リポジトリを参照：
https://github.com/nukeykt/Nuked-OPM/blob/master/opm.h
