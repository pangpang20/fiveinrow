/**
 * 五子棋游戏状态管理模块
 * 管理棋盘状态、落子记录、悔棋等功能
 */

import { PieceType, GameStatus, MoveRecord, GameConfig, DEFAULT_CONFIG } from './GameTypes';
import { GameLogic } from './GameLogic';

/**
 * 游戏状态管理类
 * 负责维护游戏状态、处理落子、悔棋等操作
 */
export class GameState {
  private board: PieceType[][];
  private currentPlayer: PieceType;
  private gameStatus: GameStatus;
  private moveHistory: MoveRecord[];
  private undoCount: number;
  private logic: GameLogic;
  private config: GameConfig;

  constructor(config: GameConfig = DEFAULT_CONFIG) {
    this.config = config;
    this.logic = new GameLogic(config);
    this.board = [];
    this.moveHistory = [];
    this.currentPlayer = PieceType.BLACK;
    this.gameStatus = GameStatus.PLAYING;
    this.undoCount = 0;
    this.initBoard();
  }

  /**
   * 初始化棋盘
   */
  private initBoard(): void {
    this.board = [];
    for (let i = 0; i < this.config.boardSize; i++) {
      const row: PieceType[] = [];
      for (let j = 0; j < this.config.boardSize; j++) {
        row.push(PieceType.EMPTY);
      }
      this.board.push(row);
    }
  }

  /**
   * 重置游戏
   */
  reset(): void {
    this.initBoard();
    this.moveHistory = [];
    this.currentPlayer = PieceType.BLACK;
    this.gameStatus = GameStatus.PLAYING;
    this.undoCount = 0;
  }

  /**
   * 落子操作
   * @param row 行索引
   * @param col 列索引
   * @returns 是否成功落子
   */
  placePiece(row: number, col: number): boolean {
    // 游戏已结束，不能落子
    if (this.gameStatus !== GameStatus.PLAYING) {
      return false;
    }

    // 检查是否可以落子
    if (!this.logic.canPlacePiece(this.board, row, col)) {
      return false;
    }

    // 落子
    this.board[row][col] = this.currentPlayer;

    // 记录落子历史
    const record: MoveRecord = {
      row: row,
      col: col,
      piece: this.currentPlayer,
      timestamp: Date.now()
    };
    this.moveHistory.push(record);

    // 判断游戏状态
    this.gameStatus = this.logic.determineGameStatus(
      this.board, row, col, this.currentPlayer
    );

    // 切换玩家
    if (this.gameStatus === GameStatus.PLAYING) {
      this.currentPlayer = this.logic.getOpponent(this.currentPlayer);
    }

    return true;
  }

  /**
   * 悔棋操作
   * @returns 是否成功悔棋
   */
  undo(): boolean {
    // 检查悔棋次数限制
    if (this.config.undoLimit >= 0 && this.undoCount >= this.config.undoLimit) {
      return false;
    }

    // 检查是否有历史记录
    if (this.moveHistory.length === 0) {
      return false;
    }

    // 撤销最后一步
    const lastMove = this.moveHistory.pop();
    if (lastMove) {
      this.board[lastMove.row][lastMove.col] = PieceType.EMPTY;
      this.currentPlayer = lastMove.piece;
      this.gameStatus = GameStatus.PLAYING;
      this.undoCount++;
      return true;
    }

    return false;
  }

  /**
   * 获取棋盘状态
   */
  getBoard(): PieceType[][] {
    return this.board;
  }

  /**
   * 获取指定位置的棋子
   */
  getPiece(row: number, col: number): PieceType {
    if (this.logic.isValidPosition(row, col)) {
      return this.board[row][col];
    }
    return PieceType.EMPTY;
  }

  /**
   * 获取当前玩家
   */
  getCurrentPlayer(): PieceType {
    return this.currentPlayer;
  }

  /**
   * 获取游戏状态
   */
  getGameStatus(): GameStatus {
    return this.gameStatus;
  }

  /**
   * 获取落子历史
   */
  getMoveHistory(): MoveRecord[] {
    return this.moveHistory;
  }

  /**
   * 获取最后一步落子
   */
  getLastMove(): MoveRecord | null {
    if (this.moveHistory.length > 0) {
      return this.moveHistory[this.moveHistory.length - 1];
    }
    return null;
  }

  /**
   * 获取剩余悔棋次数
   */
  getRemainingUndos(): number {
    if (this.config.undoLimit < 0) {
      return -1; // 无限制
    }
    return Math.max(0, this.config.undoLimit - this.undoCount);
  }

  /**
   * 获取配置
   */
  getConfig(): GameConfig {
    return this.config;
  }

  /**
   * 获取棋盘大小
   */
  getBoardSize(): number {
    return this.config.boardSize;
  }

  /**
   * 检查游戏是否结束
   */
  isGameOver(): boolean {
    return this.gameStatus !== GameStatus.PLAYING;
  }

  /**
   * 获取总步数
   */
  getTotalMoves(): number {
    return this.moveHistory.length;
  }
}
