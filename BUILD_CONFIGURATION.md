# Build Configuration for node-speaker with Static Linking

This document explains the build configuration and customization options.

## Static Linking Configuration

The build uses the following flags to ensure static linking:

```bash
export LDFLAGS="-static-libgcc -static-libstdc++"
export CFLAGS="-static"
export CXXFLAGS="-static"
```

### What is Statically Linked

- **mingw runtime**: libgcc, libstdc++
- **PortAudio**: The audio I/O library
- All dependencies are embedded in the `binding.node` file

### Benefits

- No external DLL dependencies (except system DLLs)
- Easier distribution
- Avoid DLL version conflicts

## Node.js Version Compatibility

The built `binding.node` is specific to:
- Node.js version used during build
- Node.js architecture (x64)
- Node.js ABI version

**Important**: The built library must be used with the same major version of Node.js.

## PortAudio Configuration

The build uses MSYS2's mingw-w64-x86_64-portaudio package which includes:
- DirectSound backend (default on Windows)
- WASAPI backend
- WDM-KS backend
- MME backend

## Build Customization

### Using a Different Node.js Version

Modify the GitHub Actions workflow:

```yaml
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '20'  # Change to desired version
```

### Adding Build Options

Edit `build-node-speaker.sh` and modify the node-gyp build command:

```bash
node-gyp configure build --release \
    --nodedir="$(node -e "console.log(process.execPath.replace(/bin\/node(\.exe)?$/, ''))")" \
    -- -Dportaudio_use_pkg_config=true \
    -Dadditional_option=value
```

### Debugging Build Issues

Add verbose output:

```bash
node-gyp configure build --release --verbose
```

View build logs:
```bash
cat build/Release/.../build.log
```

## Dependencies

### MSYS2 Packages Required

- `mingw-w64-x86_64-gcc` - C/C++ compiler
- `mingw-w64-x86_64-portaudio` - PortAudio library
- `mingw-w64-x86_64-pkg-config` - Package config tool
- `mingw-w64-x86_64-python` - Python (for node-gyp)
- `mingw-w64-x86_64-nodejs` - Node.js runtime
- `make` - Build tool
- `git` - Version control

### NPM Packages

- `node-gyp` - Native addon build tool (installed globally)
- `speaker` - The node-speaker module (cloned from GitHub)

## Testing the Built Library

Create a test script:

```javascript
// test-speaker.js
const Speaker = require('./output');

const speaker = new Speaker({
  channels: 2,
  bitDepth: 16,
  sampleRate: 44100
});

console.log('Speaker initialized successfully!');

// Generate a simple tone
const duration = 1; // seconds
const frequency = 440; // A4 note
const sampleRate = 44100;
const numSamples = duration * sampleRate;

const buffer = Buffer.alloc(numSamples * 4); // 2 channels * 2 bytes

for (let i = 0; i < numSamples; i++) {
  const sample = Math.sin(2 * Math.PI * frequency * i / sampleRate);
  const value = Math.floor(sample * 32767);
  
  // Write to both channels
  buffer.writeInt16LE(value, i * 4);
  buffer.writeInt16LE(value, i * 4 + 2);
}

speaker.write(buffer);
speaker.end();

console.log('Test completed!');
```

Run the test:
```bash
node test-speaker.js
```

## Troubleshooting

### Error: "Cannot find module 'binding.node'"

Ensure the file structure is correct:
```
output/
  binding.node
  package.json
  lib/
    speaker.js
```

### Error: "The specified module could not be found"

This usually means a missing DLL dependency. Check with:
```bash
ldd output/binding.node
```

All dependencies should be resolved except for system DLLs (kernel32.dll, etc).

### Error: "A dynamic link library (DLL) initialization routine failed"

This can occur if:
- Node.js version doesn't match the build version
- Architecture mismatch (x86 vs x64)

Solution: Rebuild with the correct Node.js version.

### Build fails with "PortAudio not found"

Ensure pkg-config can find PortAudio:
```bash
pkg-config --list-all | grep portaudio
pkg-config --cflags --libs portaudio-2.0
```

If not found, reinstall:
```bash
pacman -S mingw-w64-x86_64-portaudio
```

## Advanced Configuration

### Custom binding.gyp Modifications

If you need to modify the build configuration, you can patch the binding.gyp file in the build script:

```bash
# In build-node-speaker.sh, after cloning node-speaker:
cd node-speaker

# Backup original
cp binding.gyp binding.gyp.backup

# Apply modifications (example)
sed -i 's/"target_name": "binding"/"target_name": "binding", "cflags": ["-static"]/' binding.gyp
```

### Static Linking PortAudio from Source

For maximum control, you can build PortAudio from source:

```bash
# Download PortAudio source
wget http://files.portaudio.com/archives/pa_stable_v190700_20210406.tgz
tar xzf pa_stable_v190700_20210406.tgz
cd portaudio

# Configure and build
./configure --enable-static --disable-shared LDFLAGS="-static-libgcc -static-libstdc++"
make
make install
```

Then modify the build script to use this custom build.

## CI/CD Integration

The GitHub Actions workflow can be extended:

### Matrix Builds (Multiple Node.js Versions)

```yaml
strategy:
  matrix:
    node-version: [16, 18, 20]

steps:
  - name: Setup Node.js
    uses: actions/setup-node@v4
    with:
      node-version: ${{ matrix.node-version }}
```

### Scheduled Builds

```yaml
on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday
```

## Performance Considerations

### Buffer Size

The default buffer size can be adjusted in your application:

```javascript
const speaker = new Speaker({
  channels: 2,
  bitDepth: 16,
  sampleRate: 44100,
  device: null,  // Default device
  // Adjust buffer size for latency/performance trade-off
});
```

### CPU Usage

Static linking may result in slightly larger binary size but should not affect runtime performance.

## Security Considerations

- The built binary includes all dependencies, making it easier to audit
- Keep MSYS2 packages updated for security patches
- Regularly rebuild to incorporate security updates

## License Information

- node-speaker: MIT License
- PortAudio: MIT License
- This build configuration: MIT License

Ensure compliance with all licenses when distributing the built binary.
