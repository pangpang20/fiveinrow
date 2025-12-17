/**
 * 五子棋游戏类型定义模块
 * 定义棋子类型、游戏状态、落子记录等核心数据结构
 */

/**
 * 棋子类型枚举
 */
export enum PieceType {
  EMPTY = 0,   // 空位
  BLACK = 1,   // 黑子
  WHITE = 2    // 白子
}

/**
 * 游戏状态枚举
 */
export enum GameStatus {
  PLAYING = 0,     // 游戏进行中
  BLACK_WIN = 1,   // 黑方获胜
  WHITE_WIN = 2,   // 白方获胜
  DRAW = 3         // 平局
}

/**
 * 落子记录接口
 */
export interface MoveRecord {
  row: number;          // 行索引 (0-based)
  col: number;          // 列索引 (0-based)
  piece: PieceType;     // 棋子类型
  timestamp: number;    // 时间戳
}

/**
 * 游戏配置接口
 */
export interface GameConfig {
  boardSize: number;      // 棋盘尺寸 (默认15)
  winCondition: number;   // 胜利条件 - 连子数量 (默认5)
  undoLimit: number;      // 悔棋次数限制 (-1表示无限制)
}

/**
 * 棋盘位置接口
 */
export interface Position {
  row: number;
  col: number;
}

/**
 * 方向向量 - 用于胜负判定
 * 4个方向：水平、垂直、左上-右下对角线、右上-左下对角线
 */
export const DIRECTIONS: Position[] = [
  { row: 0, col: 1 },   // 水平
  { row: 1, col: 0 },   // 垂直
  { row: 1, col: 1 },   // 左上-右下对角线
  { row: 1, col: -1 }   // 右上-左下对角线
];

/**
 * 默认游戏配置 - 15x15标准棋盘
 */
export const DEFAULT_CONFIG: GameConfig = {
  boardSize: 15,
  winCondition: 5,
  undoLimit: -1
};

/**
 * 30x30大棋盘配置
 */
export const CONFIG_30X30: GameConfig = {
  boardSize: 30,
  winCondition: 5,
  undoLimit: -1
};

/**
 * 棋盘尺寸选项
 */
export const BOARD_SIZE_OPTIONS: number[] = [15, 30];
