# Examples

This directory contains example scripts for using the built node-speaker library.

## test-speaker.js

A simple test script that:
- Loads the built node-speaker library
- Generates a 440Hz sine wave (A4 musical note)
- Plays it through the default audio device for 2 seconds

### Usage

```bash
node examples/test-speaker.js
```

### Requirements

- The library must be built first (run `build-node-speaker.sh`)
- Node.js version should match the version used for building

### Expected Output

```
node-speaker loaded successfully!
Testing audio output...

Speaker configuration:
  Channels: 2
  Bit Depth: 16
  Sample Rate: 44100
  Duration: 2s
  Frequency: 440Hz

Generating sine wave...
Playing audio...
Speaker opened
Speaker flushed
Speaker closed

Test completed successfully!
```

### Troubleshooting

If you get an error:
- Ensure `output/binding.node` exists
- Check that Node.js version matches the build version
- Verify audio device is available and not in use

## Creating Your Own Examples

You can use this as a template for your own audio applications:

```javascript
const Speaker = require('../output');

const speaker = new Speaker({
  channels: 2,
  bitDepth: 16,
  sampleRate: 44100
});

// Your audio processing code here
// Write audio data as 16-bit PCM
speaker.write(yourAudioBuffer);
speaker.end();
```

## Integration with YM2151 Emulator

For YM2151 emulation, you would:

1. Initialize the YM2151 emulator
2. Generate audio samples from the emulator
3. Convert samples to 16-bit PCM format
4. Feed to node-speaker

Example structure:

```javascript
const Speaker = require('../output');
const YM2151 = require('your-ym2151-emulator');

const sampleRate = 44100;
const speaker = new Speaker({
  channels: 2,
  bitDepth: 16,
  sampleRate: sampleRate
});

const ym2151 = new YM2151(sampleRate);

// Generate audio in a loop
function generateAudio() {
  const bufferSize = 1024;
  const buffer = Buffer.alloc(bufferSize * 4); // stereo, 16-bit
  
  for (let i = 0; i < bufferSize; i++) {
    const [left, right] = ym2151.generateSample();
    
    buffer.writeInt16LE(left, i * 4);
    buffer.writeInt16LE(right, i * 4 + 2);
  }
  
  speaker.write(buffer);
}

// Start audio generation
setInterval(generateAudio, (bufferSize / sampleRate) * 1000);
```
