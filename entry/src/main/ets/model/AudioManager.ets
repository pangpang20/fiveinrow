/**
 * 音频管理器
 * 负责游戏音效的初始化和播放
 */

import { media } from '@kit.MediaKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PieceType } from './GameTypes';

/**
 * 音频管理器类
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

  public static getInstance(): AudioManager {
    if (!AudioManager.instance) {
      AudioManager.instance = new AudioManager();
    }
    return AudioManager.instance;
  }

  public async initialize(): Promise<void> {
    if (this.initialized) {
      return;
    }

    try {
      await this.initBlackPlayer();
      await this.initWhitePlayer();
      this.initialized = true;
      hilog.info(0x0000, 'AudioManager', 'Audio players initialized');
    } catch (error) {
      hilog.error(0x0000, 'AudioManager', `Failed to initialize: ${error}`);
    }
  }

  private async initBlackPlayer(): Promise<void> {
    this.blackPiecePlayer = await media.createAVPlayer();
    this.blackPiecePlayer.on('stateChange', (state: string) => {
      hilog.info(0x0000, 'AudioManager', `Black player state: ${state}`);
      if (state === 'initialized') {
        this.blackPiecePlayer?.prepare();
      } else if (state === 'prepared') {
        this.blackPlayerReady = true;
        hilog.info(0x0000, 'AudioManager', 'Black player ready');
      } else if (state === 'completed') {
        // 播放完成后重置到开头，准备下次播放
        this.blackPlayerReady = false;
        this.blackPiecePlayer?.reset();
      } else if (state === 'idle') {
        // reset后重新设置url
        if (this.blackPiecePlayer) {
          this.blackPiecePlayer.url = 'resource://rawfile/black_piece.mp3';
        }
      }
    });
    this.blackPiecePlayer.on('error', (err: Error) => {
      hilog.error(0x0000, 'AudioManager', `Black player error: ${err.message}`);
    });
    this.blackPiecePlayer.url = 'resource://rawfile/black_piece.mp3';
  }

  private async initWhitePlayer(): Promise<void> {
    this.whitePiecePlayer = await media.createAVPlayer();
    this.whitePiecePlayer.on('stateChange', (state: string) => {
      hilog.info(0x0000, 'AudioManager', `White player state: ${state}`);
      if (state === 'initialized') {
        this.whitePiecePlayer?.prepare();
      } else if (state === 'prepared') {
        this.whitePlayerReady = true;
        hilog.info(0x0000, 'AudioManager', 'White player ready');
      } else if (state === 'completed') {
        this.whitePlayerReady = false;
        this.whitePiecePlayer?.reset();
      } else if (state === 'idle') {
        if (this.whitePiecePlayer) {
          this.whitePiecePlayer.url = 'resource://rawfile/white_piece.mp3';
        }
      }
    });
    this.whitePiecePlayer.on('error', (err: Error) => {
      hilog.error(0x0000, 'AudioManager', `White player error: ${err.message}`);
    });
    this.whitePiecePlayer.url = 'resource://rawfile/white_piece.mp3';
  }

  public playPieceSound(pieceType: PieceType): void {
    hilog.info(0x0000, 'AudioManager', `playPieceSound called, type: ${pieceType}, enabled: ${this.soundEnabled}`);
    
    if (!this.soundEnabled) {
      hilog.info(0x0000, 'AudioManager', 'Sound disabled, skip playing');
      return;
    }

    try {
      if (pieceType === PieceType.BLACK) {
        hilog.info(0x0000, 'AudioManager', `Black ready: ${this.blackPlayerReady}, player: ${this.blackPiecePlayer !== null}`);
        if (this.blackPiecePlayer && this.blackPlayerReady) {
          this.blackPiecePlayer.play();
          hilog.info(0x0000, 'AudioManager', 'Playing black piece sound');
        }
      } else if (pieceType === PieceType.WHITE) {
        hilog.info(0x0000, 'AudioManager', `White ready: ${this.whitePlayerReady}, player: ${this.whitePiecePlayer !== null}`);
        if (this.whitePiecePlayer && this.whitePlayerReady) {
          this.whitePiecePlayer.play();
          hilog.info(0x0000, 'AudioManager', 'Playing white piece sound');
        }
      }
    } catch (error) {
      hilog.error(0x0000, 'AudioManager', `Failed to play sound: ${error}`);
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
      if (this.blackPiecePlayer) {
        this.blackPiecePlayer.release();
        this.blackPiecePlayer = null;
      }
      if (this.whitePiecePlayer) {
        this.whitePiecePlayer.release();
        this.whitePiecePlayer = null;
      }
      this.initialized = false;
      this.blackPlayerReady = false;
      this.whitePlayerReady = false;
      hilog.info(0x0000, 'AudioManager', 'Audio players released');
    } catch (error) {
      hilog.error(0x0000, 'AudioManager', `Failed to release: ${error}`);
    }
  }
}
