# Python用ライブラリビルド計画書

## 概要

Nuked-OPMライブラリをWindows向けにビルドし、PythonからctypesまたはCFFI経由で利用可能な動的ライブラリ (.dll) を生成します。

## ビルド成果物

- **ファイル名**: `ym2151.dll`
- **形式**: 動的ライブラリ (DLL)
- **用途**: Pythonの `ctypes.CDLL()` でロード可能

## アーキテクチャ

```
src/python/
├── Makefile            # ビルド用Makefile
├── ym2151.dll          # 生成されるDLL（ビルド後）
└── vendor/
    └── nuked-opm/      # Nuked-OPMソースコード
        ├── opm.h
        └── opm.c
```

## 実装ステップ

### 1. プロジェクト初期化

```bash
cd src/python
mkdir -p vendor
git clone https://github.com/nukeykt/Nuked-OPM.git vendor/nuked-opm
```

### 2. Makefileの作成

**Makefile**:
```makefile
CC = x86_64-w64-mingw32-gcc
CFLAGS = -O3 -Wall -shared -static-libgcc -static-libstdc++
TARGET = ym2151.dll
SOURCES = vendor/nuked-opm/opm.c
OBJECTS = $(SOURCES:.c=.o)

all: $(TARGET)

$(TARGET): $(SOURCES)
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f $(TARGET)

.PHONY: all clean
```

## ビルド方法

### WSL2でのクロスコンパイル

```bash
# MinGWのインストール
sudo apt-get update
sudo apt-get install -y mingw-w64

# ビルド
cd src/python
make

# 成果物の確認
ls -lh ym2151.dll
```

### DLL依存の確認

```bash
# mingw DLLに依存していないことを確認
x86_64-w64-mingw32-objdump -p ym2151.dll | grep -i "dll"
# 出力に libgcc や libstdc++ のDLLが含まれていないことを確認
```

## テスト方法

### Pythonからの利用例

```python
import ctypes
import os

# DLLのロード
dll_path = os.path.join(os.path.dirname(__file__), 'ym2151.dll')
lib = ctypes.CDLL(dll_path)

# 関数シグネチャの定義
lib.OPM_Reset.argtypes = [ctypes.c_void_p]
lib.OPM_Reset.restype = None

lib.OPM_Write.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_uint]
lib.OPM_Write.restype = None

lib.OPM_Clock.argtypes = [ctypes.c_void_p, ctypes.POINTER(ctypes.c_int16), ctypes.c_uint]
lib.OPM_Clock.restype = None

print("YM2151 library loaded successfully")
```

## 利用例

### Pythonラッパークラス

```python
import ctypes
import numpy as np

class YM2151:
    def __init__(self, dll_path='ym2151.dll'):
        self.lib = ctypes.CDLL(dll_path)
        
        # 関数シグネチャの設定
        self.lib.OPM_Reset.argtypes = [ctypes.c_void_p]
        self.lib.OPM_Write.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_uint]
        self.lib.OPM_Clock.argtypes = [
            ctypes.c_void_p,
            ctypes.POINTER(ctypes.c_int16),
            ctypes.c_uint
        ]
        
        # チップの初期化（実際の初期化コードが必要）
        self.chip = ctypes.c_void_p()
    
    def reset(self):
        self.lib.OPM_Reset(self.chip)
    
    def write(self, address: int, data: int):
        self.lib.OPM_Write(self.chip, address, data)
    
    def generate_samples(self, num_frames: int) -> np.ndarray:
        buffer_size = num_frames * 2  # stereo
        buffer = (ctypes.c_int16 * buffer_size)()
        self.lib.OPM_Clock(self.chip, buffer, num_frames)
        return np.frombuffer(buffer, dtype=np.int16).reshape(-1, 2)

# 使用例
ym2151 = YM2151('./ym2151.dll')
ym2151.reset()
samples = ym2151.generate_samples(1024)
```

## 実装優先度

1. **高**: 基本的なMakefileとビルドシステム
2. **高**: Nuked-OPMのDLLとしてのコンパイル
3. **高**: 静的リンクの確認（mingw DLL依存なし）
4. **中**: Pythonラッパーの例示
5. **低**: エラーハンドリングの追加

## 技術的課題と対策

### 課題1: mingw DLL依存
- **対策**: `-static-libgcc -static-libstdc++` フラグで静的リンク

### 課題2: DLLエクスポート
- **対策**: デフォルトでエクスポートされる。必要に応じて `__declspec(dllexport)` を使用

### 課題3: ctypesでの型マッピング
- **対策**: C型とPython型の対応表を作成し、正確に定義

## 参考資料

- Nuked-OPM: https://github.com/nukeykt/Nuked-OPM
- Python ctypes: https://docs.python.org/3/library/ctypes.html
- MinGW-w64: https://www.mingw-w64.org/
