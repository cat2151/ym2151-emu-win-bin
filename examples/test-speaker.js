/**
 * Test script for the built node-speaker library
 * 
 * This script tests the statically-linked node-speaker library
 * by generating a simple sine wave tone.
 */

const fs = require('fs');
const path = require('path');

// Adjust this path to point to your built output
const speakerPath = path.join(__dirname, '../output');

// Check if the built library exists
const bindingPath = path.join(speakerPath, 'binding.node');
if (!fs.existsSync(bindingPath)) {
    console.error('Error: binding.node not found at', bindingPath);
    console.error('Please build the library first using build-node-speaker.sh');
    process.exit(1);
}

// Load the speaker module
let Speaker;
try {
    Speaker = require(speakerPath);
} catch (error) {
    console.error('Error loading speaker module:', error.message);
    console.error('Make sure Node.js version matches the build version');
    process.exit(1);
}

console.log('node-speaker loaded successfully!');
console.log('Testing audio output...\n');

// Audio parameters
const channels = 2;
const bitDepth = 16;
const sampleRate = 44100;
const duration = 2; // seconds
const frequency = 440; // A4 note (Hz)

// Create speaker instance
const speaker = new Speaker({
    channels: channels,
    bitDepth: bitDepth,
    sampleRate: sampleRate
});

console.log('Speaker configuration:');
console.log(`  Channels: ${channels}`);
console.log(`  Bit Depth: ${bitDepth}`);
console.log(`  Sample Rate: ${sampleRate}`);
console.log(`  Duration: ${duration}s`);
console.log(`  Frequency: ${frequency}Hz\n`);

// Generate sine wave
const numSamples = duration * sampleRate;
const buffer = Buffer.alloc(numSamples * channels * (bitDepth / 8));

console.log('Generating sine wave...');

for (let i = 0; i < numSamples; i++) {
    // Calculate sine wave sample
    const sample = Math.sin(2 * Math.PI * frequency * i / sampleRate);
    const value = Math.floor(sample * 32767 * 0.5); // 50% volume
    
    // Write to both channels (stereo)
    buffer.writeInt16LE(value, i * 4);
    buffer.writeInt16LE(value, i * 4 + 2);
}

console.log('Playing audio...');

// Handle speaker events
speaker.on('open', () => {
    console.log('Speaker opened');
});

speaker.on('flush', () => {
    console.log('Speaker flushed');
});

speaker.on('close', () => {
    console.log('Speaker closed');
    console.log('\nTest completed successfully!');
});

speaker.on('error', (err) => {
    console.error('Speaker error:', err);
    process.exit(1);
});

// Write audio data and close
speaker.write(buffer);
speaker.end();
