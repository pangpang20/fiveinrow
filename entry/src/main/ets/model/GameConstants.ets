/**
 * 游戏常量配置
 * 包含版本信息、星位配置、缩放参数等常量
 */

/**
 * 应用版本信息接口
 */
interface AppInfoType {
  version: string;
  author: string;
  email: string;
  buildDate: string;
}

/**
 * 棋盘尺寸配置接口
 */
interface BoardSizeConfig {
  cellSize: number;
  pieceSize: number;
}

/**
 * 30路棋盘配置接口
 */
interface Board30Config {
  baseCellSize: number;
  basePieceSize: number;
}

/**
 * 棋盘布局配置接口
 */
interface BoardLayoutType {
  padding: number;
  board15: BoardSizeConfig;
  board30: Board30Config;
}

/**
 * 缩放配置项接口
 */
interface ScaleConfigItem {
  min: number;
  max: number;
  defaultValue: number;
}

/**
 * 缩放配置接口
 */
interface ScaleConfigType {
  scale15: ScaleConfigItem;
  scale30: ScaleConfigItem;
}

/**
 * 应用版本信息
 */
export const APP_INFO: AppInfoType = {
  version: '1.0.0',
  author: '陈云亮',
  email: '676814828@qq.com',
  buildDate: '2025.12'
};

/**
 * 棋盘布局配置
 */
export const BOARD_LAYOUT: BoardLayoutType = {
  padding: 15,
  board15: {
    cellSize: 22,
    pieceSize: 20
  },
  board30: {
    baseCellSize: 12,
    basePieceSize: 10
  }
};

/**
 * 缩放配置
 */
export const SCALE_CONFIG: ScaleConfigType = {
  scale15: {
    min: 1.0,
    max: 2.0,
    defaultValue: 2.0
  },
  scale30: {
    min: 1.0,
    max: 4.0,
    defaultValue: 4.0
  }
};

/**
 * 15路棋盘星位坐标
 */
export const STAR_POINTS_15: number[][] = [
  [3, 3], [3, 7], [3, 11],
  [7, 3], [7, 7], [7, 11],
  [11, 3], [11, 7], [11, 11]
];

/**
 * 30路棋盘星位坐标
 */
export const STAR_POINTS_30: number[][] = [
  [3, 3], [3, 15], [3, 26],
  [15, 3], [15, 15], [15, 26],
  [26, 3], [26, 15], [26, 26]
];

/**
 * 判断指定位置是否为星位
 */
export function isStarPoint(row: number, col: number, boardSize: number): boolean {
  const starPoints = boardSize === 30 ? STAR_POINTS_30 : STAR_POINTS_15;
  for (let i = 0; i < starPoints.length; i++) {
    if (starPoints[i][0] === row && starPoints[i][1] === col) {
      return true;
    }
  }
  return false;
}

/**
 * 获取棋盘的缩放配置
 */
export function getScaleConfig(boardSize: number): ScaleConfigItem {
  return boardSize === 30 ? SCALE_CONFIG.scale30 : SCALE_CONFIG.scale15;
}

/**
 * 获取索引数组
 */
export function getIndices(size: number): number[] {
  const indices: number[] = [];
  for (let i = 0; i < size; i++) {
    indices.push(i);
  }
  return indices;
}
