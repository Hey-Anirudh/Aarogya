/* ==========================================================================
   🌸 MOMO & MIMI'S CUTE PASTEL PARADISE - INTERACTION CORE (UPGRADED)
   ========================================================================== */

document.addEventListener('DOMContentLoaded', () => {

  // ==========================================================================
  // 🎵 1. WEB AUDIO API SYNTHESIZER (UPGRADED RETRO SOUNDS & LOFI CHORDS)
  // ==========================================================================
  
  let audioCtx = null;
  let sfxMuted = false;
  let lofiIntervalId = null;
  let isLofiPlaying = false;
  let lofiTempo = 72;
  let currentTrackIdx = 0;
  
  const tracks = [
    { name: "Cozy Afternoon Rain 🌧️", chords: [["C4", "E4", "G4", "B4"], ["A3", "C4", "E4", "G4"], ["F3", "A3", "C4", "E4"], ["G3", "B3", "D4", "F4"]] },
    { name: "Boba Daydreaming 🧋", chords: [["F4", "A4", "C5", "E5"], ["G4", "B4", "D5", "F5"], ["E4", "G4", "B4", "D5"], ["A3", "C4", "E4", "G4"]] },
    { name: "Sakura Tea Party 🌸", chords: [["C4", "F4", "A4", "D5"], ["B3", "E4", "G#4", "C#5"], ["A3", "D4", "F4", "B4"], ["G3", "C4", "E4", "A4"]] }
  ];

  function initAudio() {
    if (!audioCtx) {
      audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    }
    if (audioCtx.state === 'suspended') {
      audioCtx.resume();
    }
  }

  // Synthesize Upgraded Sound Effects
  const playSFX = {
    // Squishy water droplet (Toppings, custom inputs)
    jelly: () => {
      if (sfxMuted) return;
      initAudio();
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      
      osc.type = 'sine';
      osc.frequency.setValueAtTime(250, audioCtx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(1400, audioCtx.currentTime + 0.06);
      
      gain.gain.setValueAtTime(0.18, audioCtx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.06);
      
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      osc.start();
      osc.stop(audioCtx.currentTime + 0.06);
    },

    // 8-Bit Bubble Pop (Tapioca pearls, button click)
    pop: () => {
      if (sfxMuted) return;
      initAudio();
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      
      osc.type = 'sine';
      osc.frequency.setValueAtTime(180, audioCtx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(900, audioCtx.currentTime + 0.07);
      
      gain.gain.setValueAtTime(0.15, audioCtx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.07);
      
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      osc.start();
      osc.stop(audioCtx.currentTime + 0.07);
    },

    // Bubbly Pouring sound (Matcha, Berry tea)
    pour: () => {
      if (sfxMuted) return;
      initAudio();
      let now = audioCtx.currentTime;
      for (let i = 0; i < 9; i++) {
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        
        osc.type = 'triangle';
        const delay = i * 0.035;
        const startFreq = 220 + Math.random() * 120;
        
        osc.frequency.setValueAtTime(startFreq, now + delay);
        osc.frequency.exponentialRampToValueAtTime(startFreq * 2.2, now + delay + 0.05);
        
        gain.gain.setValueAtTime(0.08, now + delay);
        gain.gain.exponentialRampToValueAtTime(0.01, now + delay + 0.05);
        
        osc.connect(gain);
        gain.connect(audioCtx.destination);
        osc.start(now + delay);
        osc.stop(now + delay + 0.05);
      }
    },

    // Starry sparkles (Glitter additive)
    sparkle: () => {
      if (sfxMuted) return;
      initAudio();
      const now = audioCtx.currentTime;
      const notes = [987.77, 1174.66, 1396.91, 1567.98, 1975.53]; // Pentatonic arpeggio
      notes.forEach((freq, idx) => {
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(freq, now + idx * 0.04);
        
        gain.gain.setValueAtTime(0.04, now + idx * 0.04);
        gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.04 + 0.12);
        
        osc.connect(gain);
        gain.connect(audioCtx.destination);
        osc.start(now + idx * 0.04);
        osc.stop(now + idx * 0.04 + 0.13);
      });
    },

    // Cute Anime Squeak ("kyu~")
    squeak: () => {
      if (sfxMuted) return;
      initAudio();
      const now = audioCtx.currentTime;
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      
      osc.type = 'sine';
      osc.frequency.setValueAtTime(650, now);
      osc.frequency.exponentialRampToValueAtTime(1300, now + 0.14);
      
      gain.gain.setValueAtTime(0.12, now);
      gain.gain.exponentialRampToValueAtTime(0.01, now + 0.14);
      
      const lfo = audioCtx.createOscillator();
      const lfoGain = audioCtx.createGain();
      lfo.frequency.value = 16;
      lfoGain.gain.value = 45;
      
      lfo.connect(lfoGain);
      lfoGain.connect(osc.frequency);
      
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      
      lfo.start(now);
      osc.start(now);
      lfo.stop(now + 0.14);
      osc.stop(now + 0.14);
    },

    // Procedural Kitty Meow Synthesizer ("Me-oww! 🐱")
    meow: () => {
      if (sfxMuted) return;
      initAudio();
      const now = audioCtx.currentTime;
      
      // Dual oscillator design to shape organic cat vocal chords
      const osc1 = audioCtx.createOscillator();
      const osc2 = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      const filter = audioCtx.createBiquadFilter();
      
      osc1.type = 'triangle';
      osc2.type = 'sawtooth';
      
      // Pitch envelope: Starts at 520Hz ("m"), sweeps up to 880Hz ("e"), then trails down to 480Hz ("oww")
      osc1.frequency.setValueAtTime(520, now);
      osc1.frequency.exponentialRampToValueAtTime(900, now + 0.08);
      osc1.frequency.linearRampToValueAtTime(450, now + 0.35);
      
      osc2.frequency.setValueAtTime(523, now);
      osc2.frequency.exponentialRampToValueAtTime(903, now + 0.08);
      osc2.frequency.linearRampToValueAtTime(453, now + 0.35);
      
      // Bandpass filter to create resonant "nasal" sound
      filter.type = 'bandpass';
      filter.Q.value = 2.5;
      filter.frequency.setValueAtTime(800, now);
      filter.frequency.exponentialRampToValueAtTime(1600, now + 0.08);
      filter.frequency.linearRampToValueAtTime(600, now + 0.35);
      
      // Volume envelope
      gain.gain.setValueAtTime(0.001, now);
      gain.gain.linearRampToValueAtTime(0.12, now + 0.06);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.35);
      
      osc1.connect(filter);
      osc2.connect(filter);
      filter.connect(gain);
      gain.connect(audioCtx.destination);
      
      osc1.start(now);
      osc2.start(now);
      osc1.stop(now + 0.36);
      osc2.stop(now + 0.36);
    },

    // Musical Chime (Envelope seal unboxing)
    chime: () => {
      if (sfxMuted) return;
      initAudio();
      const now = audioCtx.currentTime;
      const notes = [261.63, 329.63, 392.00, 523.25, 659.25, 783.99, 1046.50];
      notes.forEach((freq, idx) => {
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        
        osc.type = 'sine';
        osc.frequency.setValueAtTime(freq, now + idx * 0.05);
        
        gain.gain.setValueAtTime(0.08, now + idx * 0.05);
        gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.05 + 0.4);
        
        osc.connect(gain);
        gain.connect(audioCtx.destination);
        osc.start(now + idx * 0.05);
        osc.stop(now + idx * 0.05 + 0.45);
      });
    },

    // Success Jingle (Milestones / Boba complete)
    successJingle: () => {
      if (sfxMuted) return;
      initAudio();
      const now = audioCtx.currentTime;
      const melody = [523.25, 659.25, 783.99, 1046.50, 1318.51, 1568.00, 2093.00];
      melody.forEach((freq, idx) => {
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(freq, now + idx * 0.06);
        
        gain.gain.setValueAtTime(0.1, now + idx * 0.06);
        gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.06 + 0.3);
        
        osc.connect(gain);
        gain.connect(audioCtx.destination);
        osc.start(now + idx * 0.06);
        osc.stop(now + idx * 0.06 + 0.35);
      });
    },

    // Noise envelope swoosh (Mail flying)
    whoosh: () => {
      if (sfxMuted) return;
      initAudio();
      const bufferSize = audioCtx.sampleRate * 0.5;
      const buffer = audioCtx.createBuffer(1, bufferSize, audioCtx.sampleRate);
      const data = buffer.getChannelData(0);
      
      let b0, b1, b2, b3, b4, b5, b6;
      b0 = b1 = b2 = b3 = b4 = b5 = b6 = 0.0;
      for (let i = 0; i < bufferSize; i++) {
        const white = Math.random() * 2 - 1;
        b0 = 0.99886 * b0 + white * 0.0555179;
        b1 = 0.99332 * b1 + white * 0.0750759;
        b2 = 0.96900 * b2 + white * 0.1538520;
        b3 = 0.86650 * b3 + white * 0.3104856;
        b4 = 0.55000 * b4 + white * 0.5329522;
        b5 = -0.7616 * b5 - white * 0.0168980;
        data[i] = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362;
        data[i] *= 0.11;
        b6 = white * 0.115926;
      }
      
      const noiseSource = audioCtx.createBufferSource();
      noiseSource.buffer = buffer;
      
      const filter = audioCtx.createBiquadFilter();
      filter.type = 'lowpass';
      filter.frequency.setValueAtTime(300, audioCtx.currentTime);
      filter.frequency.exponentialRampToValueAtTime(1500, audioCtx.currentTime + 0.2);
      filter.frequency.exponentialRampToValueAtTime(200, audioCtx.currentTime + 0.5);
      
      const gain = audioCtx.createGain();
      gain.gain.setValueAtTime(0.001, audioCtx.currentTime);
      gain.gain.linearRampToValueAtTime(0.3, audioCtx.currentTime + 0.15);
      gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.5);
      
      noiseSource.connect(filter);
      filter.connect(gain);
      gain.connect(audioCtx.destination);
      
      noiseSource.start();
      noiseSource.stop(audioCtx.currentTime + 0.5);
    }
  };

  const noteFreqs = {
    "A3": 220.00, "B3": 246.94, "C4": 261.63, "C#4": 277.18, "D4": 293.66, "E4": 329.63,
    "F4": 349.23, "F#4": 369.99, "G4": 392.00, "G#4": 415.30, "A4": 440.00, "B4": 493.88,
    "C5": 523.25, "C#5": 554.37, "D5": 587.33, "E5": 659.25, "F5": 698.46, "G5": 783.99,
    "A5": 880.00
  };

  function playSynthChord(notesArray) {
    if (!audioCtx) initAudio();
    const now = audioCtx.currentTime;
    
    if (Math.random() > 0.4) {
      const crackleOsc = audioCtx.createOscillator();
      const crackleGain = audioCtx.createGain();
      crackleOsc.type = 'triangle';
      crackleOsc.frequency.setValueAtTime(Math.random() * 50 + 20, now);
      crackleGain.gain.setValueAtTime(0.01, now);
      crackleGain.gain.exponentialRampToValueAtTime(0.0001, now + 0.05);
      crackleOsc.connect(crackleGain);
      crackleGain.connect(audioCtx.destination);
      crackleOsc.start(now);
      crackleOsc.stop(now + 0.05);
    }

    notesArray.forEach((note) => {
      const freq = noteFreqs[note];
      if (!freq) return;

      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      const filter = audioCtx.createBiquadFilter();

      osc.type = 'triangle';
      osc.frequency.value = freq;
      
      filter.type = 'lowpass';
      filter.frequency.value = 650;

      gain.gain.setValueAtTime(0.001, now);
      gain.gain.linearRampToValueAtTime(0.06, now + 0.5);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 3.2);

      osc.connect(filter);
      filter.connect(gain);
      gain.connect(audioCtx.destination);

      osc.start(now);
      osc.stop(now + 3.3);
    });

    // Cozy hi-hat ticking sound
    const hitSource = audioCtx.createOscillator();
    const hitGain = audioCtx.createGain();
    const hitFilter = audioCtx.createBiquadFilter();
    hitSource.frequency.setValueAtTime(8000, now);
    hitFilter.type = 'highpass';
    hitFilter.frequency.value = 7000;
    hitGain.gain.setValueAtTime(0.005, now);
    hitGain.gain.exponentialRampToValueAtTime(0.0001, now + 0.06);
    hitSource.connect(hitFilter);
    hitFilter.connect(hitGain);
    hitGain.connect(audioCtx.destination);
    hitSource.start(now);
    hitSource.stop(now + 0.08);
  }

  function startLofiSynthEngine() {
    if (isLofiPlaying) return;
    initAudio();
    isLofiPlaying = true;
    
    let chordIdx = 0;
    const currentTrack = tracks[currentTrackIdx];
    
    playSynthChord(currentTrack.chords[chordIdx]);
    
    lofiIntervalId = setInterval(() => {
      const activeTrack = tracks[currentTrackIdx];
      chordIdx = (chordIdx + 1) % activeTrack.chords.length;
      playSynthChord(activeTrack.chords[chordIdx]);
    }, 3200);

    document.getElementById('music-visualizer').classList.add('playing');
    document.getElementById('vinyl-disc').classList.add('playing');
    document.getElementById('play-pause').innerHTML = '<i class="fa-solid fa-pause"></i>';
  }

  function stopLofiSynthEngine() {
    if (!isLofiPlaying) return;
    clearInterval(lofiIntervalId);
    isLofiPlaying = false;
    
    document.getElementById('music-visualizer').classList.remove('playing');
    document.getElementById('vinyl-disc').classList.remove('playing');
    document.getElementById('play-pause').innerHTML = '<i class="fa-solid fa-play"></i>';
  }


  // ==========================================================================
  // ✨ 2. CANVAS CUSTOM SPARKLING CURSOR TRAIL & PHYSICS
  // ==========================================================================
  
  const cursorCanvas = document.getElementById('cursor-canvas');
  const cursorCtx = cursorCanvas.getContext('2d');
  
  const bgCanvas = document.getElementById('bg-canvas');
  const bgCtx = bgCanvas.getContext('2d');
  
  let width = (cursorCanvas.width = bgCanvas.width = window.innerWidth);
  let height = (cursorCanvas.height = bgCanvas.height = window.innerHeight);

  window.addEventListener('resize', () => {
    width = (cursorCanvas.width = bgCanvas.width = window.innerWidth);
    height = (cursorCanvas.height = bgCanvas.height = window.innerHeight);
  });

  const mouse = { x: width / 2, y: height / 2, targetX: width / 2, targetY: height / 2 };
  const cursorParticles = [];
  const bgParticles = [];

  window.addEventListener('mousemove', (e) => {
    mouse.targetX = e.clientX;
    mouse.targetY = e.clientY;
    
    const cursor = document.getElementById('custom-cursor');
    cursor.style.left = `${e.clientX}px`;
    cursor.style.top = `${e.clientY}px`;

    if (Math.random() < 0.3) {
      cursorParticles.push(new CursorParticle(e.clientX, e.clientY));
    }
  });

  function updateMouseEasing() {
    mouse.x += (mouse.targetX - mouse.x) * 0.15;
    mouse.y += (mouse.targetY - mouse.y) * 0.15;
  }

  class CursorParticle {
    constructor(x, y) {
      this.x = x;
      this.y = y;
      const rand = Math.random();
      this.type = rand < 0.4 ? 'star' : (rand < 0.7 ? 'heart' : 'bubble');
      this.size = Math.random() * 8 + 4;
      this.alpha = 1.0;
      this.decay = Math.random() * 0.02 + 0.015;
      
      this.vx = (Math.random() - 0.5) * 1.8;
      this.vy = (Math.random() - 1.2) * 1.5;
      this.angle = Math.random() * Math.PI * 2;
      this.spin = (Math.random() - 0.5) * 0.06;
      
      const hues = [346, 16, 271, 45, 120, 190];
      const selectedHue = hues[Math.floor(Math.random() * hues.length)];
      this.color = `hsla(${selectedHue}, 100%, 82%, `;
    }

    update() {
      this.x += this.vx;
      this.y += this.vy;
      this.angle += this.spin;
      this.alpha -= this.decay;
    }

    draw(ctx) {
      ctx.save();
      ctx.translate(this.x, this.y);
      ctx.rotate(this.angle);
      ctx.globalAlpha = this.alpha;
      ctx.fillStyle = this.color + this.alpha + ')';
      
      if (this.type === 'star') {
        drawStarPath(ctx, 0, 0, 5, this.size, this.size / 2);
      } else if (this.type === 'heart') {
        drawHeartPath(ctx, 0, 0, this.size);
      } else {
        ctx.strokeStyle = this.color + this.alpha + ')';
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        ctx.arc(0, 0, this.size / 2, 0, Math.PI * 2);
        ctx.stroke();
      }
      ctx.restore();
    }
  }

  // Background Particles (Now featuring dynamic candies & fruits!)
  class BgParticle {
    constructor() {
      this.reset(true);
    }

    reset(initial = false) {
      this.x = Math.random() * width;
      this.y = initial ? Math.random() * height : height + 50;
      
      const rand = Math.random();
      if (rand < 0.2) {
        this.type = 'petal';
      } else if (rand < 0.45) {
        this.type = 'bubble';
      } else if (rand < 0.65) {
        this.type = 'cloud';
      } else {
        this.type = 'candy'; // Deluxe Super Cute Candies!
      }
      
      this.candyEmoji = ['🍬', '🍓', '🍪', '🍩', '🧸', '🍭'][Math.floor(Math.random() * 6)];
      this.size = this.type === 'cloud' ? Math.random() * 40 + 30 : (this.type === 'candy' ? 24 : Math.random() * 12 + 6);
      this.speed = Math.random() * 0.4 + 0.2;
      this.sway = Math.random() * 0.02;
      this.swayWidth = Math.random() * 1.5;
      this.angle = Math.random() * Math.PI * 2;
      this.spin = (Math.random() - 0.5) * 0.015;
      
      const hues = [346, 271, 16, 45, 195];
      this.color = `hsla(${hues[Math.floor(Math.random() * hues.length)]}, 100%, 88%, 0.4)`;
    }

    update() {
      this.y -= this.speed;
      this.angle += this.spin;
      this.x += Math.sin(this.angle) * this.swayWidth;
      
      const mouseShiftX = (mouse.x - width / 2) * (this.size * 0.0002);
      this.x -= mouseShiftX;

      if (this.y < -50 || this.x < -100 || this.x > width + 100) {
        this.reset(false);
      }
    }

    draw(ctx) {
      ctx.save();
      ctx.globalAlpha = 0.6;
      ctx.translate(this.x, this.y);
      ctx.rotate(this.angle);

      if (this.type === 'petal') {
        ctx.fillStyle = this.color;
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.bezierCurveTo(this.size / 2, -this.size / 2, this.size, -this.size / 4, this.size, 0);
        ctx.bezierCurveTo(this.size, this.size / 4, this.size / 2, this.size / 2, 0, 0);
        ctx.fill();
      } else if (this.type === 'cloud') {
        ctx.fillStyle = 'rgba(255, 255, 255, 0.48)';
        ctx.beginPath();
        ctx.arc(0, 0, this.size, 0, Math.PI * 2);
        ctx.arc(this.size * 0.6, -this.size * 0.2, this.size * 0.8, 0, Math.PI * 2);
        ctx.arc(-this.size * 0.6, -this.size * 0.2, this.size * 0.7, 0, Math.PI * 2);
        ctx.fill();
      } else if (this.type === 'candy') {
        ctx.font = `${this.size}px Fredoka`;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(this.candyEmoji, 0, 0);
      } else {
        ctx.strokeStyle = this.color;
        ctx.lineWidth = 1;
        ctx.beginPath();
        ctx.arc(0, 0, this.size / 2, 0, Math.PI * 2);
        ctx.stroke();
      }
      ctx.restore();
    }
  }

  function drawStarPath(ctx, cx, cy, spikes, outerRadius, innerRadius) {
    let rot = (Math.PI / 2) * 3;
    let x = cx;
    let y = cy;
    let step = Math.PI / spikes;

    ctx.beginPath();
    ctx.moveTo(cx, cy - outerRadius);
    for (let i = 0; i < spikes; i++) {
      x = cx + Math.cos(rot) * outerRadius;
      y = cy + Math.sin(rot) * outerRadius;
      ctx.lineTo(x, y);
      rot += step;

      x = cx + Math.cos(rot) * innerRadius;
      y = cy + Math.sin(rot) * innerRadius;
      ctx.lineTo(x, y);
      rot += step;
    }
    ctx.lineTo(cx, cy - outerRadius);
    ctx.closePath();
    ctx.fill();
  }

  function drawHeartPath(ctx, x, y, size) {
    ctx.beginPath();
    ctx.moveTo(x, y + size / 4);
    ctx.bezierCurveTo(x, y - size / 2, x - size, y - size / 2, x - size, y + size / 4);
    ctx.bezierCurveTo(x - size, y + size * 0.8, x, y + size * 1.1, x, y + size * 1.3);
    ctx.bezierCurveTo(x, y + size * 1.1, x + size, y + size * 0.8, x + size, y + size / 4);
    ctx.bezierCurveTo(x + size, y - size / 2, x, y - size / 2, x, y + size / 4);
    ctx.closePath();
    ctx.fill();
  }

  // Populate background particles
  for (let i = 0; i < 28; i++) {
    bgParticles.push(new BgParticle());
  }

  function tick() {
    updateMouseEasing();

    cursorCtx.clearRect(0, 0, width, height);
    for (let i = cursorParticles.length - 1; i >= 0; i--) {
      const p = cursorParticles[i];
      p.update();
      if (p.alpha <= 0.01) {
        cursorParticles.splice(i, 1);
      } else {
        p.draw(cursorCtx);
      }
    }

    bgCtx.clearRect(0, 0, width, height);
    bgParticles.forEach((p) => {
      p.update();
      p.draw(bgCtx);
    });

    requestAnimationFrame(tick);
  }
  tick();


  // ==========================================================================
  // 💌 3. SECRET ENVELOPE LANDING SCREEN INTERACTION
  // ==========================================================================
  
  const sealButton = document.getElementById('seal-button');
  const envelope = sealButton.closest('.envelope');
  const overlay = document.getElementById('envelope-overlay');
  const mainContent = document.getElementById('main-content');

  sealButton.addEventListener('click', () => {
    if (envelope.classList.contains('open')) return;
    
    playSFX.chime();
    envelope.classList.add('open');
    sealButton.style.transform = 'translateX(-50%) scale(0) rotate(180deg)';
    
    setTimeout(() => {
      overlay.classList.add('fade-out');
      mainContent.classList.remove('hidden');
      
      setTimeout(() => {
        mainContent.classList.add('fade-in');
        
        for (let k = 0; k < 60; k++) {
          const randX = Math.random() * width;
          const randY = Math.random() * height;
          cursorParticles.push(new CursorParticle(randX, randY));
        }
        
        playSFX.successJingle();
      }, 100);
    }, 1500);
  });


  // ==========================================================================
  // 👩‍🦰 4. INTERACTIVE MOMO ANIME CHARACTER & ACCESSORIES
  // ==========================================================================
  
  const momoSVG = document.getElementById('momo-character');
  const momoEyesNormal = momoSVG.querySelector('.momo-eyes-normal');
  const momoEyesHappy = momoSVG.querySelector('.momo-eyes-happy');
  const momoBlushes = momoSVG.querySelectorAll('.momo-blush');
  const momoMouthSmile = momoSVG.querySelector('.momo-mouth-smile');
  const momoMouthOpen = momoSVG.querySelector('.momo-mouth-open');
  
  // Interactive Chibi Bows / Accessories
  const hairBowL = document.getElementById('hair-bow-l');
  const hairBowR = document.getElementById('hair-bow-r');
  const starPin = document.getElementById('hairpin-star');

  function automateBlinking() {
    if (momoSVG.parentNode.matches(':hover')) return;

    setInterval(() => {
      momoEyesNormal.style.opacity = 0;
      setTimeout(() => {
        momoEyesNormal.style.opacity = 1;
      }, 150);
    }, 4000 + Math.random() * 3000);
  }
  automateBlinking();

  momoSVG.addEventListener('click', (e) => {
    // Check if clicking specific accessories first
    if (e.target.closest('#hair-bow-l') || e.target.closest('#hair-bow-r') || e.target.closest('#hairpin-star')) {
      return; // Handled by accessory listeners
    }

    playSFX.squeak();
    
    momoBlushes.forEach(b => {
      b.style.transition = 'none';
      b.style.opacity = 1;
      b.style.transform = 'scale(1.35)';
      setTimeout(() => {
        b.style.transition = 'opacity 0.6s ease';
        b.style.opacity = 0.4;
        b.style.transform = 'scale(1)';
      }, 800);
    });

    const rect = momoSVG.getBoundingClientRect();
    const headX = rect.left + rect.width / 2;
    const headY = rect.top + rect.height * 0.35;
    
    for (let i = 0; i < 15; i++) {
      const p = new CursorParticle(headX + (Math.random() - 0.5) * 40, headY + (Math.random() - 0.5) * 30);
      p.type = 'heart';
      p.vx = (Math.random() - 0.5) * 4;
      p.vy = -Math.random() * 3 - 2;
      p.decay = 0.015;
      cursorParticles.push(p);
    }
  });

  // Bow Left Click Event
  hairBowL.addEventListener('click', (e) => {
    e.stopPropagation();
    playSFX.sparkle();
    hairBowL.classList.add('wiggle');
    setTimeout(() => hairBowL.classList.remove('wiggle'), 600);
    
    // Spawn bow wiggling sparkles
    const rect = hairBowL.getBoundingClientRect();
    for (let i = 0; i < 6; i++) {
      cursorParticles.push(new CursorParticle(rect.left + rect.width / 2, rect.top + rect.height / 2));
    }
  });

  // Bow Right Click Event
  hairBowR.addEventListener('click', (e) => {
    e.stopPropagation();
    playSFX.sparkle();
    hairBowR.classList.add('wiggle');
    setTimeout(() => hairBowR.classList.remove('wiggle'), 600);
    
    const rect = hairBowR.getBoundingClientRect();
    for (let i = 0; i < 6; i++) {
      cursorParticles.push(new CursorParticle(rect.left + rect.width / 2, rect.top + rect.height / 2));
    }
  });

  // Star Hairpin Click Event
  starPin.addEventListener('click', (e) => {
    e.stopPropagation();
    playSFX.chime();
    starPin.classList.add('spin');
    setTimeout(() => starPin.classList.remove('spin'), 800);
    
    const rect = starPin.getBoundingClientRect();
    for (let i = 0; i < 10; i++) {
      const p = new CursorParticle(rect.left + rect.width / 2, rect.top + rect.height / 2);
      p.type = 'star';
      cursorParticles.push(p);
    }
  });


  // ==========================================================================
  // 🧋 5. INTERACTIVE BOBA LAB MINI-GAME (UPGRADED)
  // ==========================================================================
  
  const addPearlsBtn = document.getElementById('add-pearls');
  const addTeaBtn = document.getElementById('add-tea');
  const addStrawberryBtn = document.getElementById('add-strawberry');
  const addGlitterBtn = document.getElementById('add-sparkles');
  const addCookieBtn = document.getElementById('add-topping-cookie');
  const addCherryBtn = document.getElementById('add-topping-cherry');
  const resetBobaBtn = document.getElementById('reset-boba');
  
  const bobaCup = document.getElementById('boba-cup');
  const bobaLiquid = document.getElementById('boba-liquid');
  const bobaPearlsContainer = document.getElementById('boba-pearls');
  const bobaToppingsContainer = document.getElementById('boba-toppings');
  const bobaStraw = document.getElementById('boba-straw');
  const bobaSparks = document.getElementById('boba-sparkles');

  let bubbleTeaPoured = false;
  let sparklesCount = 0;

  addPearlsBtn.addEventListener('click', () => {
    playSFX.pop();
    const currentCount = bobaPearlsContainer.children.length;
    if (currentCount >= 25) return;
    
    for (let k = 0; k < 5; k++) {
      const pearl = document.createElement('div');
      pearl.classList.add('pearl');
      
      const leftOffset = Math.random() * 80 + 12; 
      const bottomStack = (Math.floor((currentCount + k) / 5) * 10) + Math.random() * 3;
      
      pearl.style.left = `${leftOffset}px`;
      pearl.style.bottom = `${bottomStack}px`;
      
      bobaPearlsContainer.appendChild(pearl);
    }
  });

  function pourTea(flavor) {
    playSFX.pour();
    bobaLiquid.className = 'boba-liquid';
    
    setTimeout(() => {
      bobaLiquid.classList.add(flavor);
      bubbleTeaPoured = true;
      
      setTimeout(() => {
        bobaStraw.classList.add('inserted');
      }, 600);
    }, 50);
  }

  addTeaBtn.addEventListener('click', () => pourTea('matcha'));
  addStrawberryBtn.addEventListener('click', () => pourTea('strawberry'));

  addGlitterBtn.addEventListener('click', () => {
    playSFX.sparkle();
    sparklesCount++;

    for (let i = 0; i < 8; i++) {
      const sparkle = document.createElement('div');
      sparkle.classList.add('glitter-particle');
      sparkle.innerHTML = '✨';
      
      const left = Math.random() * 80 + 10;
      const bottom = Math.random() * 120 + 20;
      
      sparkle.style.left = `${left}px`;
      sparkle.style.bottom = `${bottom}px`;
      sparkle.style.setProperty('--dx', `${(Math.random() - 0.5) * 40}px`);
      sparkle.style.setProperty('--dy', `-${Math.random() * 60 + 20}px`);
      
      bobaSparks.appendChild(sparkle);
      setTimeout(() => sparkle.remove(), 1000);
    }
  });

  // Adding Deluxe Cute Toppings (Cookies / Cherries)
  function dropTopping(toppingType, emoji) {
    if (!bubbleTeaPoured) {
      playSFX.pop();
      alert("Momo says: 'Pour some sweet tea first before adding luxury toppings! 🍵🍓'");
      return;
    }
    
    playSFX.jelly();
    const toppingCount = bobaToppingsContainer.children.length;
    if (toppingCount >= 4) return; // Max 4 toppings

    const topping = document.createElement('div');
    topping.classList.add('boba-topping-item');
    topping.innerHTML = emoji;
    
    // Stagger layout landing coordinates stacked on the tea surface
    const xCoord = 15 + toppingCount * 22;
    const yCoord = 115 + (Math.random() - 0.5) * 5;
    const rot = (Math.random() - 0.5) * 20;
    
    topping.style.left = `${xCoord}px`;
    topping.style.setProperty('--top-land', `${180 - yCoord}px`);
    topping.style.setProperty('--rot-land', `${rot}deg`);
    
    bobaToppingsContainer.appendChild(topping);
  }

  addCookieBtn.addEventListener('click', () => dropTopping('cookie', '🧸'));
  addCherryBtn.addEventListener('click', () => dropTopping('cherry', '🍒'));

  // Clicking boba straw wiggles it and mixes colors
  bobaStraw.addEventListener('click', () => {
    if (!bobaStraw.classList.contains('inserted')) return;
    playSFX.jelly();
    bobaStraw.classList.add('wiggling');
    setTimeout(() => bobaStraw.classList.remove('wiggling'), 500);
    
    // Recolor boba liquid to represent sweet mixing!
    if (bobaLiquid.classList.contains('matcha') && bobaLiquid.classList.contains('strawberry')) {
      // already mixed
    } else {
      bobaLiquid.style.filter = 'hue-rotate(20deg) saturate(1.1)';
      setTimeout(() => {
        bobaLiquid.style.filter = 'none';
      }, 800);
    }
  });

  resetBobaBtn.addEventListener('click', () => {
    playSFX.pop();
    bobaLiquid.className = 'boba-liquid';
    bobaPearlsContainer.innerHTML = '';
    bobaToppingsContainer.innerHTML = '';
    bobaStraw.classList.remove('inserted');
    bobaSparks.innerHTML = '';
    bubbleTeaPoured = false;
    sparklesCount = 0;
  });


  // ==========================================================================
  // 🫳 6. HEADPAT SIMULATOR INTERACTIVE FLOW
  // ==========================================================================
  
  const patTarget = document.getElementById('pat-target');
  const patCountVal = document.getElementById('pat-count');
  const happinessProgress = document.getElementById('happiness-progress');
  const happinessPercentText = document.getElementById('happiness-percent');
  const patFeedbackText = document.getElementById('pat-feedback-text');
  const patsEmojis = document.getElementById('pats-emojis');

  let patCounter = 0;
  let happinessPercent = 20;
  let sparkleModeActive = false;

  const feedbacks = [
    "Momo is cozy and purring. 🥰",
    "Momo loves headpats! Sparkles are gathering! ✨",
    "Starry eyes unlocked! Momo is happy! 🌸",
    "MOMO IS GLOWING! MAXIMUM HAPPINESS REACHED! 👑💕"
  ];

  patTarget.addEventListener('mousemove', (e) => {
    if (Math.random() > 0.08) return;
    
    playSFX.pop();
    patCounter++;
    patCountVal.innerText = patCounter;
    
    if (happinessPercent < 100) {
      happinessPercent += 4;
      if (happinessPercent > 100) happinessPercent = 100;
      happinessProgress.style.width = `${happinessPercent}%`;
      happinessPercentText.innerText = `${happinessPercent}%`;
    }

    if (happinessPercent >= 100 && !sparkleModeActive) {
      sparkleModeActive = true;
      patFeedbackText.innerText = feedbacks[3];
      playSFX.successJingle();
      
      momoSVG.classList.add('sparkle-mode-active');
      momoSVG.style.filter = 'drop-shadow(0 0 12px #ffd700)';
    } else if (happinessPercent >= 80 && happinessPercent < 100) {
      patFeedbackText.innerText = feedbacks[2];
    } else if (happinessPercent >= 50 && happinessPercent < 80) {
      patFeedbackText.innerText = feedbacks[1];
    } else if (happinessPercent < 50) {
      patFeedbackText.innerText = feedbacks[0];
    }

    const rect = patTarget.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    
    const emoji = document.createElement('span');
    emoji.classList.add('pat-emoji');
    const cuteList = ['🌸', '✨', '💖', '🥰', '🐾', '🧋', '🍬', '🍩'];
    emoji.innerText = cuteList[Math.floor(Math.random() * cuteList.length)];
    emoji.style.left = `${x}px`;
    emoji.style.top = `${y}px`;
    emoji.style.setProperty('--dx', `${(Math.random() - 0.5) * 60}px`);
    emoji.style.setProperty('--dy', `-${Math.random() * 80 + 30}px`);
    
    patsEmojis.appendChild(emoji);
    setTimeout(() => emoji.remove(), 1200);
  });


  // ==========================================================================
  // 📻 7. COZY LOFI PLAYER STATE LOGIC
  // ==========================================================================
  
  const playPauseBtn = document.getElementById('play-pause');
  const prevTrackBtn = document.getElementById('prev-track');
  const nextTrackBtn = document.getElementById('next-track');
  const trackName = document.getElementById('track-name');

  playPauseBtn.addEventListener('click', () => {
    playSFX.pop();
    if (isLofiPlaying) {
      stopLofiSynthEngine();
    } else {
      startLofiSynthEngine();
    }
  });

  function changeTrack(direction) {
    playSFX.pop();
    const wasPlaying = isLofiPlaying;
    
    if (wasPlaying) {
      stopLofiSynthEngine();
    }
    
    currentTrackIdx = (currentTrackIdx + direction + tracks.length) % tracks.length;
    trackName.innerText = tracks[currentTrackIdx].name;
    
    if (wasPlaying) {
      setTimeout(() => {
        startLofiSynthEngine();
      }, 200);
    }
  }

  prevTrackBtn.addEventListener('click', () => changeTrack(-1));
  nextTrackBtn.addEventListener('click', () => changeTrack(1));


  // ==========================================================================
  // 🔮 8. GACHAPON MACHINE & DAILY FORTUNES
  // ==========================================================================
  
  const gachaCrank = document.getElementById('gacha-crank');
  const gachaMachine = document.getElementById('gacha-machine');
  const gachaPrompt = document.getElementById('gacha-prompt');
  const openedCapsule = document.getElementById('opened-capsule');
  const fortuneText = document.getElementById('fortune-text');
  const gachaDispenser = document.getElementById('gacha-dispenser');

  const fortunesList = [
    "Your path is paved with sparkling pink stars today! ⭐ Keep shining!",
    "A fresh, delicious cup of Boba Milk Tea is in your near future! 🧋 Treat yourself!",
    "You will encounter a warm cozy sleeping kitty and it will make you smile! 🐱🐾",
    "Today is a 100% warm fluffy blanket day. Take deep breaths and rest! ☁️",
    "Momo thinks you are doing a magnificent job! Code sweet dreams! 🌸",
    "Your vibes are perfectly synced with retro cozy synthesizers today! 📻🎶",
    "A lovely, glowing surprise will sweeten your evening! 💖"
  ];

  gachaCrank.addEventListener('click', () => {
    if (gachaCrank.classList.contains('spin')) return;
    
    playSFX.pop();
    gachaCrank.classList.add('spin');
    gachaMachine.classList.add('wiggling');
    gachaPrompt.style.opacity = 0;
    openedCapsule.classList.add('hidden');
    
    setTimeout(() => {
      const cap = document.createElement('div');
      cap.classList.add('dispensed-capsule');
      
      const colors = ['#ffa6b9', '#a2d2ff', '#dfbdff', '#ffe494', '#baffc9'];
      cap.style.backgroundColor = colors[Math.floor(Math.random() * colors.length)];
      
      gachaDispenser.appendChild(cap);
      
      setTimeout(() => {
        playSFX.successJingle();
        cap.remove();
        openedCapsule.classList.remove('hidden');
        
        const randTxt = fortunesList[Math.floor(Math.random() * fortunesList.length)];
        fortuneText.innerText = randTxt;
        
        gachaCrank.classList.remove('spin');
        gachaMachine.classList.remove('wiggling');
      }, 700);

    }, 600);
  });


  // ==========================================================================
  // ✉️ 9. CUTE LETTERBOX ENVELOPE FORM HANDLERS
  // ==========================================================================
  
  const noteForm = document.getElementById('note-form');
  const noteText = document.getElementById('note-text');
  const noteSender = document.getElementById('note-sender');
  const sendLetterBtn = document.getElementById('send-letter-btn');
  const mailSuccessOverlay = document.getElementById('mail-success');
  const closeSuccessBtn = document.getElementById('close-success-btn');
  const miniEnvelope = document.getElementById('mini-envelope');

  [noteText, noteSender].forEach((el) => {
    el.addEventListener('focus', () => {
      miniEnvelope.classList.add('focus');
    });
  });

  document.addEventListener('click', (e) => {
    const box = document.getElementById('contact-envelope-box');
    if (box && !box.contains(e.target) && e.target !== sendLetterBtn) {
      miniEnvelope.classList.remove('focus');
    }
  });

  sendLetterBtn.addEventListener('click', (e) => {
    if (!noteText.value.trim() || !noteSender.value.trim()) {
      noteForm.reportValidity();
      return;
    }
    
    playSFX.whoosh();
    miniEnvelope.classList.remove('focus');
    miniEnvelope.style.transition = 'transform 1s cubic-bezier(0.1, 0.8, 0.3, 1), opacity 0.8s';
    miniEnvelope.style.transform = 'translateY(-250px) rotate(-15deg) scale(0.1)';
    miniEnvelope.style.opacity = 0;
    
    setTimeout(() => {
      mailSuccessOverlay.classList.remove('hidden');
      playSFX.successJingle();
    }, 900);
  });

  closeSuccessBtn.addEventListener('click', () => {
    playSFX.pop();
    mailSuccessOverlay.classList.add('hidden');
    
    miniEnvelope.style.transition = 'none';
    miniEnvelope.style.transform = 'translateY(0) rotate(0) scale(1)';
    miniEnvelope.style.opacity = 1;
    
    noteText.value = '';
    noteSender.value = '';
  });


  // ==========================================================================
  // 🐈 10. FLOATING CORNER PET (MIMI THE KITTY) INTERACTIONS
  // ==========================================================================
  
  const mimiBasket = document.getElementById('mimi-basket');
  const mimiKitty = document.getElementById('mimi-kitty');
  const mimiBubble = document.getElementById('mimi-bubble');
  const feedKittyBtn = document.getElementById('kitty-treat-btn');

  const kittyThoughts = [
    "Meow! 🐾 (Momo, can I have a strawberry?)",
    "Prrr... (I love chill lofi melodies! 🌧️)",
    "Nyaa~ (Give me a yummy cookie please!)",
    "Yawn... 💤 (Time for a sweet kitten nap...)",
    "Chirp! 🐦 (Look, a bird outside! Can we catch it?)",
    "Mrrrp? (Are you typing sweet code, bestie?)"
  ];

  // Mimi click actions
  mimiKitty.addEventListener('click', () => {
    playSFX.meow();
    
    // Jump wiggle animation
    mimiBasket.style.transition = 'none';
    mimiBasket.style.transform = 'translateY(-25px) scale(1.1) rotate(5deg)';
    setTimeout(() => {
      mimiBasket.style.transition = 'transform 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275)';
      mimiBasket.style.transform = 'translateY(0) scale(1) rotate(0)';
    }, 400);

    // Swap text bubble with active thoughts
    const randThought = kittyThoughts[Math.floor(Math.random() * kittyThoughts.length)];
    mimiBubble.innerText = randThought;
    
    // Force show bubble
    mimiBubble.style.opacity = 1;
    mimiBubble.style.transform = 'scale(1)';
    
    // Hide thought bubble after 3 seconds
    setTimeout(() => {
      if (!mimiBasket.matches(':hover')) {
        mimiBubble.style.opacity = 0;
        mimiBubble.style.transform = 'scale(0.6)';
      }
    }, 3000);

    // Spawn kitty paw particles in mouse trail
    const rect = mimiKitty.getBoundingClientRect();
    for (let i = 0; i < 8; i++) {
      const p = new CursorParticle(rect.left + rect.width / 2, rect.top + rect.height / 2);
      p.type = 'bubble'; // custom rounded paw sparks
      cursorParticles.push(p);
    }
  });

  // Feed Mimi Kitty
  feedKittyBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    playSFX.pop();
    
    // Create falling fish treat
    const fish = document.createElement('div');
    fish.className = 'falling-fish-food';
    fish.innerText = '🐟';
    
    const rect = mimiBasket.getBoundingClientRect();
    const spawnX = rect.left + 50;
    const spawnY = rect.top - 120;
    
    fish.style.left = `${spawnX}px`;
    fish.style.top = `${spawnY}px`;
    fish.style.setProperty('--dx', `${(Math.random() - 0.5) * 15}px`);
    fish.style.setProperty('--dy', '110px');
    
    document.body.appendChild(fish);
    
    // Land physics
    setTimeout(() => {
      fish.remove();
      playSFX.meow();
      playSFX.successJingle();
      
      // Update thought bubble
      mimiBubble.innerText = "Nom nom! 🐟 So yummy! Purrr... 🥰";
      mimiBubble.style.opacity = 1;
      mimiBubble.style.transform = 'scale(1)';
      
      // Spawn flying hearts around basket
      for (let i = 0; i < 12; i++) {
        const p = new CursorParticle(rect.left + 50 + (Math.random() - 0.5) * 30, rect.top + 50);
        p.type = 'heart';
        p.vy = -Math.random() * 2.5 - 1.5;
        cursorParticles.push(p);
      }
    }, 750);
  });


  // ==========================================================================
  // ⚙️ 11. APP CONTROLS (VOLUME / THEMES / CANDY RAIN)
  // ==========================================================================
  
  const soundToggle = document.getElementById('sound-toggle');
  const themeToggle = document.getElementById('theme-toggle');
  const candyRainBtn = document.getElementById('candy-rain-btn');

  // Trigger Candy Rain!
  candyRainBtn.addEventListener('click', () => {
    playSFX.sparkle();
    
    // Inject 50 floating candies into the background particles array
    for (let k = 0; k < 50; k++) {
      setTimeout(() => {
        const candyPart = new BgParticle();
        candyPart.type = 'candy';
        candyPart.y = -40; // spawn at the very top and drift down!
        candyPart.speed = -(Math.random() * 1.5 + 0.8); // reverse speed to drift downwards!
        candyPart.x = Math.random() * width;
        bgParticles.push(candyPart);
        
        // spawn micro cursor sparkles too
        if (k % 4 === 0) {
          cursorParticles.push(new CursorParticle(Math.random() * width, Math.random() * height));
        }
      }, k * 45);
    }
  });

  soundToggle.addEventListener('click', () => {
    sfxMuted = !sfxMuted;
    
    if (sfxMuted) {
      soundToggle.innerHTML = '<i class="fa-solid fa-volume-xmark"></i>';
      stopLofiSynthEngine();
    } else {
      soundToggle.innerHTML = '<i class="fa-solid fa-volume-high"></i>';
      playSFX.pop();
    }
  });

  themeToggle.addEventListener('click', () => {
    playSFX.pop();
    document.body.classList.toggle('theme-lilac');
    
    const momoSweater = momoSVG.querySelector('.momo-sweater');
    const momoBows = momoSVG.querySelectorAll('.momo-bow circle, .momo-bow path');
    
    if (document.body.classList.contains('theme-lilac')) {
      momoSweater.setAttribute('fill', '#c3b2ff');
      momoBows.forEach(el => el.setAttribute('fill', '#9f83ff'));
    } else {
      momoSweater.setAttribute('fill', '#ffb7c5');
      momoBows.forEach(el => el.setAttribute('fill', '#ff7898'));
    }

    for (let k = 0; k < 20; k++) {
      cursorParticles.push(new CursorParticle(mouse.x + (Math.random() - 0.5) * 150, mouse.y + (Math.random() - 0.5) * 150));
    }
  });


  // ==========================================================================
  // 🍮 12. HOVER JELLY SPRING TRIGGERS FOR EVERY BUTTON
  // ==========================================================================
  
  const allButtons = document.querySelectorAll('.jelly-button, button, .boba-btn, .player-btn');
  
  allButtons.forEach((btn) => {
    btn.addEventListener('click', () => {
      // Re-trigger jelly animation on tap
      btn.style.animation = 'none';
      btn.offsetHeight; // Trigger reflow
      btn.style.animation = 'jelly 0.45s ease';
    });
  });

});
