
// Utility to convert raw PCM to AudioBuffer and play it
// Based on Google GenAI SDK examples

// Helper to strip data URI prefix if present
const stripDataUri = (base64: string) => base64.replace(/^data:audio\/\w+;base64,/, "");

export const playAudioFromBase64 = async (base64Audio: string, audioContext: AudioContext): Promise<void> => {
  try {
    // Ensure we have clean base64 data
    const cleanBase64 = stripDataUri(base64Audio);
    const binaryString = atob(cleanBase64);
    const len = binaryString.length;
    const bytes = new Uint8Array(len);
    for (let i = 0; i < len; i++) {
      bytes[i] = binaryString.charCodeAt(i);
    }
    
    // Gemini TTS usually returns 24000Hz mono PCM
    const pcmData = new Int16Array(bytes.buffer);
    const sampleRate = 24000; 
    const numChannels = 1;
    
    const buffer = audioContext.createBuffer(numChannels, pcmData.length, sampleRate);
    const channelData = buffer.getChannelData(0);
    
    for (let i = 0; i < pcmData.length; i++) {
      // Convert 16-bit PCM to float [-1, 1]
      channelData[i] = pcmData[i] / 32768.0;
    }
    
    const source = audioContext.createBufferSource();
    source.buffer = buffer;
    source.connect(audioContext.destination);
    source.start(0);
  } catch (e) {
    console.error("Error playing audio", e);
  }
};

/**
 * Converts raw PCM base64 string to a WAV Blob for download/playback in standard players.
 * Assumes 16-bit, 24kHz, Mono.
 */
export const base64PcmToWavBlob = (base64Audio: string, sampleRate: number = 24000): Blob => {
  const cleanBase64 = stripDataUri(base64Audio);
  const binaryString = atob(cleanBase64);
  const len = binaryString.length;
  const bytes = new Uint8Array(len);
  for (let i = 0; i < len; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  
  const wavHeader = new ArrayBuffer(44);
  const view = new DataView(wavHeader);
  
  const numChannels = 1;
  const bitsPerSample = 16;
  
  // RIFF chunk descriptor
  writeString(view, 0, 'RIFF');
  view.setUint32(4, 36 + bytes.length, true); // File size - 8
  writeString(view, 8, 'WAVE');
  
  // fmt sub-chunk
  writeString(view, 12, 'fmt ');
  view.setUint32(16, 16, true); // Subchunk1Size (16 for PCM)
  view.setUint16(20, 1, true); // AudioFormat (1 for PCM)
  view.setUint16(22, numChannels, true); // NumChannels
  view.setUint32(24, sampleRate, true); // SampleRate
  view.setUint32(28, sampleRate * numChannels * (bitsPerSample / 8), true); // ByteRate
  view.setUint16(32, numChannels * (bitsPerSample / 8), true); // BlockAlign
  view.setUint16(34, bitsPerSample, true); // BitsPerSample
  
  // data sub-chunk
  writeString(view, 36, 'data');
  view.setUint32(40, bytes.length, true); // Subchunk2Size
  
  // Combine header and data
  return new Blob([view, bytes], { type: 'audio/wav' });
};

function writeString(view: DataView, offset: number, string: string) {
  for (let i = 0; i < string.length; i++) {
    view.setUint8(offset + i, string.charCodeAt(i));
  }
}

/**
 * Synthesize a sound effect for page turning (paper swish)
 * Uses Web Audio API to create filtered white noise
 */
export const playPageTurnSound = () => {
  try {
    const AudioContext = window.AudioContext || (window as any).webkitAudioContext;
    if (!AudioContext) return;

    const ctx = new AudioContext();
    const t = ctx.currentTime;

    // Create a buffer for noise
    const bufferSize = ctx.sampleRate * 0.5; // 0.5 seconds
    const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
      // White noise
      data[i] = Math.random() * 2 - 1;
    }

    const noise = ctx.createBufferSource();
    noise.buffer = buffer;

    const filter = ctx.createBiquadFilter();
    filter.type = 'lowpass';
    
    const gainNode = ctx.createGain();

    noise.connect(filter);
    filter.connect(gainNode);
    gainNode.connect(ctx.destination);

    // Filter sweep to simulate "swish"
    filter.frequency.setValueAtTime(800, t);
    filter.frequency.exponentialRampToValueAtTime(100, t + 0.3);

    // Volume envelope
    gainNode.gain.setValueAtTime(0, t);
    gainNode.gain.linearRampToValueAtTime(0.3, t + 0.05);
    gainNode.gain.exponentialRampToValueAtTime(0.001, t + 0.3);

    noise.start(t);
    noise.stop(t + 0.4);
    
    // Try to resume if suspended (browser autoplay policy)
    if (ctx.state === 'suspended') {
      ctx.resume().catch(() => {});
    }
  } catch (e) {
    // Ignore audio errors
  }
};
