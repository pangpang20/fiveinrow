/**
 * 五子棋游戏逻辑模块
 * 包含胜负判定、规则检查等核心算法
 * 所有算法以最后落子点为中心，复杂度接近 O(1)
 */

import { PieceType, GameStatus, Position, DIRECTIONS, GameConfig, DEFAULT_CONFIG } from './GameTypes';

/**
 * 游戏逻辑类
 * 负责规则验证和胜负判定
 */
export class GameLogic {
  private config: GameConfig;

  constructor(config: GameConfig = DEFAULT_CONFIG) {
    this.config = config;
  }

  /**
   * 检查位置是否在棋盘范围内
   */
  isValidPosition(row: number, col: number): boolean {
    return row >= 0 && row < this.config.boardSize &&
           col >= 0 && col < this.config.boardSize;
  }

  /**
   * 检查指定位置是否可以落子
   * @param board 当前棋盘状态
   * @param row 行索引
   * @param col 列索引
   */
  canPlacePiece(board: PieceType[][], row: number, col: number): boolean {
    if (!this.isValidPosition(row, col)) {
      return false;
    }
    return board[row][col] === PieceType.EMPTY;
  }

  /**
   * 在指定方向上计算连续同色棋子数量
   * @param board 棋盘状态
   * @param row 起始行
   * @param col 起始列
   * @param piece 棋子类型
   * @param direction 方向向量
   * @returns 该方向上连续同色棋子数量（不含起点）
   */
  private countInDirection(
    board: PieceType[][],
    row: number,
    col: number,
    piece: PieceType,
    direction: Position
  ): number {
    let count = 0;
    let currentRow = row + direction.row;
    let currentCol = col + direction.col;

    while (this.isValidPosition(currentRow, currentCol) &&
           board[currentRow][currentCol] === piece) {
      count++;
      currentRow += direction.row;
      currentCol += direction.col;
    }

    return count;
  }

  /**
   * 检查指定位置是否形成获胜连线
   * 以最后落子点为中心，向4个方向双向扩展
   * 复杂度: O(4 * winCondition) ≈ O(1)
   *
   * @param board 棋盘状态
   * @param row 最后落子行
   * @param col 最后落子列
   * @returns 是否获胜
   */
  checkWin(board: PieceType[][], row: number, col: number): boolean {
    const piece = board[row][col];
    if (piece === PieceType.EMPTY) {
      return false;
    }

    // 检查4个方向
    for (const direction of DIRECTIONS) {
      // 正向计数
      const positiveCount = this.countInDirection(board, row, col, piece, direction);
      // 反向计数（方向取反）
      const negativeDirection: Position = {
        row: -direction.row,
        col: -direction.col
      };
      const negativeCount = this.countInDirection(board, row, col, piece, negativeDirection);

      // 总数 = 正向 + 反向 + 自身(1)
      const total = positiveCount + negativeCount + 1;
      if (total >= this.config.winCondition) {
        return true;
      }
    }

    return false;
  }

  /**
   * 检查棋盘是否已满（平局条件）
   */
  isBoardFull(board: PieceType[][]): boolean {
    for (let row = 0; row < this.config.boardSize; row++) {
      for (let col = 0; col < this.config.boardSize; col++) {
        if (board[row][col] === PieceType.EMPTY) {
          return false;
        }
      }
    }
    return true;
  }

  /**
   * 根据落子后的状态判断游戏结果
   * @param board 棋盘状态
   * @param lastRow 最后落子行
   * @param lastCol 最后落子列
   * @param currentPiece 当前落子的棋子类型
   */
  determineGameStatus(
    board: PieceType[][],
    lastRow: number,
    lastCol: number,
    currentPiece: PieceType
  ): GameStatus {
    // 检查是否获胜
    if (this.checkWin(board, lastRow, lastCol)) {
      return currentPiece === PieceType.BLACK ? GameStatus.BLACK_WIN : GameStatus.WHITE_WIN;
    }

    // 检查是否平局
    if (this.isBoardFull(board)) {
      return GameStatus.DRAW;
    }

    // 游戏继续
    return GameStatus.PLAYING;
  }

  /**
   * 获取对手棋子类型
   */
  getOpponent(piece: PieceType): PieceType {
    return piece === PieceType.BLACK ? PieceType.WHITE : PieceType.BLACK;
  }

  /**
   * 获取配置
   */
  getConfig(): GameConfig {
    return this.config;
  }
}
