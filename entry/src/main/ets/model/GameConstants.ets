/**
 * 游戏常量配置
 * 包含版本信息、星位配置、缩放参数等常量
 */

/**
 * 应用版本信息
 */
export const APP_INFO = {
  version: '1.0.0',
  author: '陈云亮',
  email: '676814828@qq.com',
  buildDate: '2025.12'
} as const;

/**
 * 棋盘布局配置
 */
export const BOARD_LAYOUT = {
  padding: 15, // 棋盘边距

  // 15路棋盘配置
  board15: {
    cellSize: 22,
    pieceSize: 20
  },

  // 30路棋盘配置
  board30: {
    baseCellSize: 12,
    basePieceSize: 10
  }
} as const;

/**
 * 缩放配置
 */
export const SCALE_CONFIG = {
  // 15路棋盘缩放
  scale15: {
    min: 1.0,      // 最小 100%
    max: 2.0,      // 最大 200%
    default: 2.0   // 默认 200%
  },

  // 30路棋盘缩放
  scale30: {
    min: 1.0,      // 最小 100%
    max: 4.0,      // 最大 400%
    default: 4.0   // 默认 400%
  }
} as const;

/**
 * 15路棋盘星位坐标
 * 标准五子棋9个星位
 */
export const STAR_POINTS_15: readonly number[][] = [
  [3, 3], [3, 7], [3, 11],
  [7, 3], [7, 7], [7, 11],
  [11, 3], [11, 7], [11, 11]
];

/**
 * 30路棋盘星位坐标
 */
export const STAR_POINTS_30: readonly number[][] = [
  [3, 3], [3, 15], [3, 26],
  [15, 3], [15, 15], [15, 26],
  [26, 3], [26, 15], [26, 26]
];

/**
 * 判断指定位置是否为星位
 * @param row 行索引
 * @param col 列索引
 * @param boardSize 棋盘尺寸
 * @returns 是否为星位
 */
export function isStarPoint(row: number, col: number, boardSize: number): boolean {
  const starPoints = boardSize === 30 ? STAR_POINTS_30 : STAR_POINTS_15;
  return starPoints.some(point => point[0] === row && point[1] === col);
}

/**
 * 获取棋盘的缩放配置
 * @param boardSize 棋盘尺寸
 * @returns 缩放配置
 */
export function getScaleConfig(boardSize: number): { min: number; max: number; default: number } {
  return boardSize === 30 ? SCALE_CONFIG.scale30 : SCALE_CONFIG.scale15;
}

/**
 * 获取索引数组
 * @param size 数组大小
 * @returns 0 到 size-1 的数组
 */
export function getIndices(size: number): number[] {
  const indices: number[] = [];
  for (let i = 0; i < size; i++) {
    indices.push(i);
  }
  return indices;
}
