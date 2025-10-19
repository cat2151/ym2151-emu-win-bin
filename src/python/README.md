# Python YM2151 Library

Nuked-OPMライブラリをWindows向けにビルドし、Pythonからctypes経由で利用可能な動的ライブラリを生成します。

## ビルド方法

```bash
# リポジトリのルートから実行
bash scripts/build_python.sh
```

このスクリプトは以下を実行します：
1. Nuked-OPMをvendor/nuked-opmにクローン（未取得の場合）
2. Makefileを使用してym2151.dllをビルド（静的リンク）

## 成果物

- `ym2151.dll` - 動的ライブラリ（mingw DLL依存なし）

## 前提条件

- mingw-w64 (`x86_64-w64-mingw32-gcc`)
- make

## 利用方法

Pythonからctypes経由で利用：

```python
import ctypes

# DLLのロード
lib = ctypes.CDLL('./ym2151.dll')

# 関数シグネチャの定義
lib.OPM_Reset.argtypes = [ctypes.c_void_p]
lib.OPM_Write.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_uint]
lib.OPM_Clock.argtypes = [ctypes.c_void_p, ctypes.POINTER(ctypes.c_int16), ctypes.c_uint]

# 使用
# ...
```
