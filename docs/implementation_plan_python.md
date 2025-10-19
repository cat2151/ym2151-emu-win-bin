# Python実装計画書

## 概要

Pythonで、Nuked-OPMライブラリを使用したYM2151エミュレータCLIを作成します。
音声出力には`sounddevice`ライブラリを使用し、Windows向けにPyInstallerでスタンドアロン実行ファイルを生成します。

## アーキテクチャ

```
src/python/
├── requirements.txt    # 依存関係
├── setup.py           # パッケージ設定
├── main.py            # エントリポイント
├── ym2151/
│   ├── __init__.py
│   ├── wrapper.py     # Nuked-OPM ctypesラッパー
│   └── lib/
│       └── nuked_opm.dll  # ビルド済みDLL（静的リンク版）
└── audio/
    ├── __init__.py
    └── player.py      # 音声出力ハンドラ
```

## 依存関係

### requirements.txt

```txt
numpy>=1.24.0
sounddevice>=0.4.6
click>=8.1.0
```

### 開発用依存関係

```txt
pyinstaller>=6.0.0
```

## 実装ステップ

### 1. プロジェクト初期化

```bash
cd src/python
python3 -m venv venv
source venv/bin/activate  # WSL2の場合
pip install -r requirements.txt
```

### 2. Nuked-OPMのDLLビルド

WSL2でWindows用DLLをビルド（静的リンク）:

```bash
# MinGWでNuked-OPMをDLLとしてビルド
x86_64-w64-mingw32-gcc -shared -o nuked_opm.dll \
    -static -static-libgcc \
    -O3 \
    vendor/nuked-opm/opm.c
```

### 3. ctypesラッパーの実装

**ym2151/wrapper.py**:
```python
import ctypes
import os
from typing import Optional
import numpy as np

class OpmChip(ctypes.Structure):
    """Nuked-OPM chipの構造体（opaque）"""
    pass

class YM2151:
    """YM2151エミュレータのPythonラッパー"""
    
    def __init__(self, dll_path: Optional[str] = None):
        if dll_path is None:
            # デフォルトのDLLパス
            dll_path = os.path.join(
                os.path.dirname(__file__),
                'lib',
                'nuked_opm.dll'
            )
        
        # DLLのロード
        self.lib = ctypes.CDLL(dll_path)
        
        # 関数シグネチャの定義
        self.lib.OPM_Reset.argtypes = [ctypes.POINTER(OpmChip)]
        self.lib.OPM_Reset.restype = None
        
        self.lib.OPM_Write.argtypes = [
            ctypes.POINTER(OpmChip),
            ctypes.c_uint,
            ctypes.c_uint
        ]
        self.lib.OPM_Write.restype = None
        
        self.lib.OPM_Clock.argtypes = [
            ctypes.POINTER(OpmChip),
            ctypes.POINTER(ctypes.c_int16),
            ctypes.c_uint
        ]
        self.lib.OPM_Clock.restype = None
        
        # チップの初期化
        self.chip = ctypes.pointer(OpmChip())
        
    def reset(self):
        """チップをリセット"""
        self.lib.OPM_Reset(self.chip)
    
    def write(self, address: int, data: int):
        """レジスタに書き込み"""
        self.lib.OPM_Write(self.chip, address, data)
    
    def generate_samples(self, num_frames: int) -> np.ndarray:
        """
        オーディオサンプルを生成
        
        Args:
            num_frames: フレーム数（stereoなので実際のサンプル数は2倍）
        
        Returns:
            shape=(num_frames, 2) のint16配列
        """
        buffer_size = num_frames * 2  # stereo
        buffer = (ctypes.c_int16 * buffer_size)()
        
        self.lib.OPM_Clock(self.chip, buffer, num_frames)
        
        # numpy配列に変換してreshape
        samples = np.frombuffer(buffer, dtype=np.int16)
        return samples.reshape(-1, 2)
```

### 4. 音声出力の実装

**audio/player.py**:
```python
import sounddevice as sd
import numpy as np
from typing import Optional

class AudioPlayer:
    """音声出力プレイヤー"""
    
    def __init__(self, sample_rate: int = 44100):
        self.sample_rate = sample_rate
        self.stream: Optional[sd.OutputStream] = None
    
    def play(self, samples: np.ndarray, duration: Optional[float] = None):
        """
        音声を再生
        
        Args:
            samples: shape=(frames, channels) のint16またはfloat32配列
            duration: 再生時間（秒）。Noneの場合はサンプル全体を再生
        """
        # int16をfloat32に正規化
        if samples.dtype == np.int16:
            samples_float = samples.astype(np.float32) / 32768.0
        else:
            samples_float = samples
        
        # 再生
        sd.play(samples_float, self.sample_rate)
        
        if duration:
            sd.wait(int(duration * 1000))  # ミリ秒に変換
        else:
            sd.wait()
    
    def stop(self):
        """再生を停止"""
        sd.stop()
    
    def close(self):
        """リソースをクリーンアップ"""
        self.stop()
```

### 5. メイン実装

**main.py**:
```python
#!/usr/bin/env python3
import click
import numpy as np
from ym2151.wrapper import YM2151
from audio.player import AudioPlayer

@click.command()
@click.option('--sample-rate', '-s', default=44100, help='Sample rate in Hz')
@click.option('--duration', '-d', default=5, help='Duration in seconds')
def main(sample_rate: int, duration: int):
    """YM2151 Emulator CLI"""
    
    click.echo(f"YM2151 Emulator starting...")
    click.echo(f"Sample rate: {sample_rate} Hz")
    click.echo(f"Duration: {duration} seconds")
    
    # YM2151の初期化
    ym2151 = YM2151()
    ym2151.reset()
    
    # デモ音声の設定（例: 440Hz正弦波）
    init_demo_sound(ym2151)
    
    # サンプルの生成
    num_frames = sample_rate * duration
    click.echo(f"Generating {num_frames} frames...")
    samples = ym2151.generate_samples(num_frames)
    
    # 音声の再生
    player = AudioPlayer(sample_rate)
    click.echo("Playing audio...")
    player.play(samples, duration)
    
    click.echo("Playback finished.")

def init_demo_sound(ym2151: YM2151):
    """デモ音声の初期化"""
    # YM2151レジスタ設定でデモ音を設定
    # 例: 440Hz正弦波の設定
    # 実際のレジスタ値はYM2151のデータシートを参照
    ym2151.write(0x01, 0x02)  # LFO設定など
    ym2151.write(0x08, 0x00)  # Key on/off
    # ... 他のレジスタ設定

if __name__ == '__main__':
    main()
```

### 6. setup.py

```python
from setuptools import setup, find_packages

setup(
    name='ym2151-emu',
    version='0.1.0',
    packages=find_packages(),
    install_requires=[
        'numpy>=1.24.0',
        'sounddevice>=0.4.6',
        'click>=8.1.0',
    ],
    entry_points={
        'console_scripts': [
            'ym2151-emu=main:main',
        ],
    },
    package_data={
        'ym2151': ['lib/*.dll'],
    },
    include_package_data=True,
)
```

## ビルド方法

### PyInstallerでスタンドアロン実行ファイルを作成

```bash
# PyInstallerのインストール
pip install pyinstaller

# 実行ファイルの作成
pyinstaller --onefile \
    --add-data "ym2151/lib/nuked_opm.dll:ym2151/lib" \
    --name ym2151-emu \
    main.py

# 生成物は dist/ym2151-emu.exe
```

### クロスビルド用のスクリプト

WSL2からWindows実行ファイルを作成するには、Windows上でビルドするか、
Wineを使用する必要があります。

**build_windows.sh** (Wine使用):
```bash
#!/bin/bash
set -e

echo "Building YM2151 Emulator for Windows using Wine..."

# Wineのインストール確認
if ! command -v wine &> /dev/null; then
    echo "Installing Wine..."
    sudo dpkg --add-architecture i386
    sudo apt-get update
    sudo apt-get install -y wine wine32 wine64
fi

# Python for Windowsのインストール（Wineで）
if [ ! -d "$HOME/.wine/drive_c/Python311" ]; then
    echo "Installing Python for Windows in Wine..."
    wget https://www.python.org/ftp/python/3.11.0/python-3.11.0-amd64.exe
    wine python-3.11.0-amd64.exe /quiet InstallAllUsers=1 PrependPath=1
fi

# PyInstallerのインストール
wine python -m pip install pyinstaller numpy sounddevice click

# ビルド
wine pyinstaller --onefile \
    --add-data "ym2151/lib/nuked_opm.dll;ym2151/lib" \
    --name ym2151-emu \
    main.py

echo "Build completed: dist/ym2151-emu.exe"
```

## テスト方法

### 開発環境でのテスト

```bash
# 仮想環境の有効化
source venv/bin/activate

# 直接実行
python main.py --duration 3
```

### ユニットテスト

**tests/test_ym2151.py**:
```python
import unittest
import numpy as np
from ym2151.wrapper import YM2151

class TestYM2151(unittest.TestCase):
    
    def setUp(self):
        self.ym2151 = YM2151()
    
    def test_reset(self):
        """resetが正常に動作するか"""
        self.ym2151.reset()  # パニックしないことを確認
    
    def test_write(self):
        """writeが正常に動作するか"""
        self.ym2151.reset()
        self.ym2151.write(0x01, 0x02)  # パニックしないことを確認
    
    def test_generate_samples(self):
        """サンプル生成が正常に動作するか"""
        self.ym2151.reset()
        samples = self.ym2151.generate_samples(1024)
        
        self.assertEqual(samples.shape, (1024, 2))
        self.assertEqual(samples.dtype, np.int16)

if __name__ == '__main__':
    unittest.main()
```

実行:
```bash
python -m pytest tests/
```

## 実装優先度

1. **高**: 基本的なプロジェクト構造とビルドシステム
2. **高**: Nuked-OPMのctypesラッパー
3. **高**: 音声出力の基本実装
4. **中**: PyInstallerでのパッケージング
5. **中**: デモ音声の実装（440Hz正弦波など）
6. **中**: コマンドライン引数の処理
7. **低**: エラーハンドリングの改善
8. **低**: ユニットテストの追加

## 技術的課題と対策

### 課題1: ctypesでのDLLロード
- **対策**: DLLパスを相対パスで指定し、PyInstallerでバンドル

### 課題2: PyInstallerでのクロスビルド
- **対策**: Wineを使用するか、GitHub ActionsでWindows環境を使用

### 課題3: sounddeviceの依存関係
- **対策**: sounddeviceはPortAudioに依存。PyInstallerで自動的にバンドルされる

## 参考資料

- Nuked-OPM: https://github.com/nukeykt/Nuked-OPM
- sounddevice: https://python-sounddevice.readthedocs.io/
- ctypes: https://docs.python.org/3/library/ctypes.html
- PyInstaller: https://pyinstaller.org/
