export class SoundEngine {
  private ctx: AudioContext | null = null;
  public muted = false;

  private ensureContext(): AudioContext | null {
    if (this.muted || typeof window === 'undefined') return null;
    if (!this.ctx) {
      const Ctx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      if (Ctx) {
        this.ctx = new Ctx();
      }
    }
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume().catch(() => {});
    }
    return this.ctx;
  }

  public toggleMute(): boolean {
    this.muted = !this.muted;
    return this.muted;
  }

  private playTone(
    freqStart: number,
    freqEnd: number,
    duration: number,
    type: OscillatorType,
    volume: number,
    jitter = 0.08
  ) {
    const ctx = this.ensureContext();
    if (!ctx) return;
    const now = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    const mult = 1 + (Math.random() * 2 - 1) * jitter;
    osc.type = type;
    osc.frequency.setValueAtTime(Math.max(30, freqStart * mult), now);
    osc.frequency.exponentialRampToValueAtTime(Math.max(24, freqEnd * mult), now + duration);

    gain.gain.setValueAtTime(volume, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + duration);

    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(now);
    osc.stop(now + duration + 0.01);
  }

  private playNoise(duration: number, volume: number, lowpassHz: number) {
    const ctx = this.ensureContext();
    if (!ctx) return;
    const sampleRate = ctx.sampleRate;
    const frameCount = Math.max(1, Math.floor(sampleRate * duration));
    const buffer = ctx.createBuffer(1, frameCount, sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < frameCount; i++) {
      data[i] = Math.random() * 2 - 1;
    }

    const src = ctx.createBufferSource();
    src.buffer = buffer;

    const filter = ctx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(lowpassHz, ctx.currentTime);

    const gain = ctx.createGain();
    gain.gain.setValueAtTime(volume, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + duration);

    src.connect(filter);
    filter.connect(gain);
    gain.connect(ctx.destination);
    src.start();
  }

  public playMgShot() {
    this.playNoise(0.045, 0.055, 2200);
    this.playTone(260, 110, 0.05, 'square', 0.03);
  }

  public playCannon() {
    this.playNoise(0.16, 0.14, 700);
    this.playTone(135, 38, 0.19, 'sawtooth', 0.11);
  }

  public playRocketLaunch() {
    this.playNoise(0.24, 0.1, 1600);
    this.playTone(320, 620, 0.2, 'triangle', 0.05);
  }

  public playExplosion(heavy = false) {
    this.playNoise(heavy ? 0.55 : 0.28, heavy ? 0.24 : 0.14, heavy ? 420 : 680);
    this.playTone(heavy ? 95 : 130, 26, heavy ? 0.5 : 0.25, 'sawtooth', heavy ? 0.16 : 0.09);
  }

  public playOilDeposit() {
    this.playTone(440, 587, 0.12, 'triangle', 0.07, 0.02);
    setTimeout(() => this.playTone(587, 740, 0.14, 'triangle', 0.06, 0.02), 65);
  }

  public playCapture(friendly: boolean) {
    if (friendly) {
      this.playTone(330, 440, 0.16, 'triangle', 0.09, 0.01);
      setTimeout(() => this.playTone(440, 660, 0.22, 'triangle', 0.09, 0.01), 110);
    } else {
      this.playTone(260, 175, 0.28, 'sawtooth', 0.09, 0.01);
    }
  }

  public playOrderClick() {
    this.playTone(520, 390, 0.045, 'square', 0.04, 0.03);
  }

  public playUnitReady() {
    this.playTone(380, 520, 0.09, 'triangle', 0.06, 0.02);
  }

  public playPromotion() {
    this.playTone(440, 554, 0.11, 'triangle', 0.085, 0.01);
    setTimeout(() => this.playTone(554, 659, 0.12, 'triangle', 0.085, 0.01), 75);
    setTimeout(() => this.playTone(659, 880, 0.2, 'triangle', 0.095, 0.01), 150);
  }

  public playVictory() {
    const notes = [330, 440, 554, 659];
    notes.forEach((n, idx) => {
      setTimeout(() => this.playTone(n, n * 1.01, 0.26, 'triangle', 0.1, 0.005), idx * 110);
    });
  }

  public playDefeat() {
    const notes = [280, 240, 195, 145];
    notes.forEach((n, idx) => {
      setTimeout(() => this.playTone(n, n * 0.96, 0.3, 'sawtooth', 0.09, 0.005), idx * 140);
    });
  }
}
