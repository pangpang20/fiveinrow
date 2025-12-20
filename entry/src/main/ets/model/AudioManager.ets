/**
 * 音频管理器
 * 使用 media.createSoundPool 播放短音效
 */

import { media } from '@kit.MediaKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PieceType } from './GameTypes';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 音频管理器类
 */
export class AudioManager {
  private static instance: AudioManager | null = null;
  private soundPool: media.SoundPool | null = null;
  private blackSoundId: number = -1;
  private whiteSoundId: number = -1;
  private soundEnabled: boolean = true;
  private initialized: boolean = false;
  private context: Context | null = null;

  private constructor() {}

  public static getInstance(): AudioManager {
    if (!AudioManager.instance) {
      AudioManager.instance = new AudioManager();
    }
    return AudioManager.instance;
  }

  public setContext(context: Context): void {
    this.context = context;
  }

  public async initialize(): Promise<void> {
    if (this.initialized) {
      return;
    }

    try {
      hilog.info(0x0000, 'AudioManager', 'Starting initialization...');
      
      // 创建 SoundPool
      this.soundPool = await media.createSoundPool(2, {
        usage: 1, // STREAM_USAGE_MEDIA
        rendererFlags: 0
      });
      
      hilog.info(0x0000, 'AudioManager', 'SoundPool created');

      // 加载音效文件
      if (this.context) {
        const blackFd = await this.context.resourceManager.getRawFd('black_piece.mp3');
        this.blackSoundId = await this.soundPool.load(blackFd.fd, blackFd.offset, blackFd.length);
        hilog.info(0x0000, 'AudioManager', `Black sound loaded, id: ${this.blackSoundId}`);

        const whiteFd = await this.context.resourceManager.getRawFd('white_piece.mp3');
        this.whiteSoundId = await this.soundPool.load(whiteFd.fd, whiteFd.offset, whiteFd.length);
        hilog.info(0x0000, 'AudioManager', `White sound loaded, id: ${this.whiteSoundId}`);
      } else {
        hilog.error(0x0000, 'AudioManager', 'Context is null, cannot load sounds');
      }

      this.initialized = true;
      hilog.info(0x0000, 'AudioManager', 'Initialization complete');
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(0x0000, 'AudioManager', `Failed to initialize: ${err.code} - ${err.message}`);
    }
  }

  public playPieceSound(pieceType: PieceType): void {
    if (!this.soundEnabled || !this.soundPool) {
      hilog.info(0x0000, 'AudioManager', `Skip playing: enabled=${this.soundEnabled}, pool=${this.soundPool !== null}`);
      return;
    }

    try {
      const soundId = pieceType === PieceType.BLACK ? this.blackSoundId : this.whiteSoundId;
      if (soundId >= 0) {
        this.soundPool.play(soundId, {
          loop: 0,
          rate: 1.0,
          leftVolume: 1.0,
          rightVolume: 1.0,
          priority: 0
        });
        hilog.info(0x0000, 'AudioManager', `Playing sound id: ${soundId}`);
      } else {
        hilog.warn(0x0000, 'AudioManager', `Sound not loaded: ${soundId}`);
      }
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(0x0000, 'AudioManager', `Failed to play: ${err.code} - ${err.message}`);
    }
  }

  public setSoundEnabled(enabled: boolean): void {
    this.soundEnabled = enabled;
    hilog.info(0x0000, 'AudioManager', `Sound enabled: ${enabled}`);
  }

  public isSoundEnabled(): boolean {
    return this.soundEnabled;
  }

  public release(): void {
    try {
      if (this.soundPool) {
        this.soundPool.release();
        this.soundPool = null;
      }
      this.initialized = false;
      this.blackSoundId = -1;
      this.whiteSoundId = -1;
      hilog.info(0x0000, 'AudioManager', 'Released');
    } catch (error) {
      hilog.error(0x0000, 'AudioManager', `Failed to release: ${error}`);
    }
  }
}
