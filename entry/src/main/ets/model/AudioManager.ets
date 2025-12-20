/**
 * 音频管理器
 * 负责游戏音效的初始化和播放
 */

import { media } from '@kit.MediaKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PieceType } from './GameTypes';

/**
 * 音频管理器类
 * 单例模式，管理游戏中的所有音效
 */
export class AudioManager {
  private static instance: AudioManager | null = null;

  private blackPiecePlayer: media.AVPlayer | null = null;
  private whitePiecePlayer: media.AVPlayer | null = null;
  private blackPlayerReady: boolean = false;
  private whitePlayerReady: boolean = false;
  private soundEnabled: boolean = true;
  private initialized: boolean = false;

  private constructor() {}

  /**
   * 获取单例实例
   */
  public static getInstance(): AudioManager {
    if (!AudioManager.instance) {
      AudioManager.instance = new AudioManager();
    }
    return AudioManager.instance;
  }

  /**
   * 初始化音频播放器
   */
  public async initialize(): Promise<void> {
    if (this.initialized) {
      return;
    }

    try {
      // 创建黑子音效播放器
      this.blackPiecePlayer = await media.createAVPlayer();
      this.blackPiecePlayer.on('stateChange', (state: string) => {
        hilog.info(0x0000, 'AudioManager', `Black player state: ${state}`);
        if (state === 'initialized') {
          this.blackPiecePlayer?.prepare();
        } else if (state === 'prepared') {
          this.blackPlayerReady = true;
        } else if (state === 'completed' || state === 'stopped') {
          this.blackPiecePlayer?.prepare();
        }
      });
      this.blackPiecePlayer.url = 'resource://rawfile/black_piece.mp3';

      // 创建白子音效播放器
      this.whitePiecePlayer = await media.createAVPlayer();
      this.whitePiecePlayer.on('stateChange', (state: string) => {
        hilog.info(0x0000, 'AudioManager', `White player state: ${state}`);
        if (state === 'initialized') {
          this.whitePiecePlayer?.prepare();
        } else if (state === 'prepared') {
          this.whitePlayerReady = true;
        } else if (state === 'completed' || state === 'stopped') {
          this.whitePiecePlayer?.prepare();
        }
      });
      this.whitePiecePlayer.url = 'resource://rawfile/white_piece.mp3';

      this.initialized = true;
      hilog.info(0x0000, 'AudioManager', 'Audio players initialized');
    } catch (error) {
      hilog.error(0x0000, 'AudioManager', `Failed to initialize audio players: ${error}`);
    }
  }

  /**
   * 播放落子音效
   * @param pieceType 棋子类型
   */
  public playPieceSound(pieceType: PieceType): void {
    if (!this.soundEnabled) {
      return;
    }

    try {
      if (pieceType === PieceType.BLACK && this.blackPiecePlayer && this.blackPlayerReady) {
        this.blackPiecePlayer.play();
        hilog.info(0x0000, 'AudioManager', 'Playing black piece sound');
      } else if (pieceType === PieceType.WHITE && this.whitePiecePlayer && this.whitePlayerReady) {
        this.whitePiecePlayer.play();
        hilog.info(0x0000, 'AudioManager', 'Playing white piece sound');
      }
    } catch (error) {
      hilog.error(0x0000, 'AudioManager', `Failed to play sound: ${error}`);
    }
  }

  /**
   * 设置声音开关
   * @param enabled 是否启用声音
   */
  public setSoundEnabled(enabled: boolean): void {
    this.soundEnabled = enabled;
    hilog.info(0x0000, 'AudioManager', `Sound enabled: ${enabled}`);
  }

  /**
   * 获取声音开关状态
   */
  public isSoundEnabled(): boolean {
    return this.soundEnabled;
  }

  /**
   * 释放资源
   */
  public release(): void {
    try {
      if (this.blackPiecePlayer) {
        this.blackPiecePlayer.release();
        this.blackPiecePlayer = null;
      }
      if (this.whitePiecePlayer) {
        this.whitePiecePlayer.release();
        this.whitePiecePlayer = null;
      }
      this.initialized = false;
      hilog.info(0x0000, 'AudioManager', 'Audio players released');
    } catch (error) {
      hilog.error(0x0000, 'AudioManager', `Failed to release audio players: ${error}`);
    }
  }
}
