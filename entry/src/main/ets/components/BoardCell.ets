/**
 * 棋盘单元格组件
 * 负责渲染单个格子的网格线、星位和棋子
 */

import { PieceType } from '../model/GameTypes';
import { isStarPoint } from '../model/GameConstants';

/**
 * 棋盘单元格属性
 */
interface BoardCellProps {
  row: number;
  col: number;
  boardSize: number;
  cellSize: number;
  pieceSize: number;
  pieceType: PieceType;
  isLastMove: boolean;
  onCellClick: (row: number, col: number) => void;
}

/**
 * 棋盘单元格组件
 */
@Component
export struct BoardCell {
  @Prop row: number = 0;
  @Prop col: number = 0;
  @Prop boardSize: number = 15;
  @Prop cellSize: number = 22;
  @Prop pieceSize: number = 20;
  @Prop pieceType: PieceType = PieceType.EMPTY;
  @Prop isLastMove: boolean = false;
  onCellClick: (row: number, col: number) => void = () => {};

  build() {
    Stack() {
      // 绘制网格线
      Canvas(new CanvasRenderingContext2D(new RenderingContextSettings(true)))
        .width(this.cellSize)
        .height(this.cellSize)
        .onReady(() => { })

      // 网格线背景 - 水平线
      Column() {
        if (this.row > 0 || this.row < this.boardSize - 1) {
          Line()
            .width(this.col === 0 ? this.cellSize / 2 : (this.col === this.boardSize - 1 ? this.cellSize / 2 : this.cellSize))
            .height(1)
            .backgroundColor($r('app.color.board_line'))
            .position({
              x: this.col === 0 ? this.cellSize / 2 : 0,
              y: this.cellSize / 2
            })
        }
      }
      .width(this.cellSize)
      .height(this.cellSize)

      // 垂直线
      Column() {
        Line()
          .width(1)
          .height(this.row === 0 ? this.cellSize / 2 : (this.row === this.boardSize - 1 ? this.cellSize / 2 : this.cellSize))
          .backgroundColor($r('app.color.board_line'))
          .position({
            x: this.cellSize / 2,
            y: this.row === 0 ? this.cellSize / 2 : 0
          })
      }
      .width(this.cellSize)
      .height(this.cellSize)

      // 星位
      if (isStarPoint(this.row, this.col, this.boardSize)) {
        Circle({ width: this.boardSize === 30 ? 4 : 6, height: this.boardSize === 30 ? 4 : 6 })
          .fill($r('app.color.star_point'))
      }

      // 棋子
      if (this.pieceType !== PieceType.EMPTY) {
        // 棋子本体 - 使用纯圆形，无阴影避免方形背景
        Circle({ width: this.pieceSize, height: this.pieceSize })
          .fill(this.pieceType === PieceType.BLACK ?
            $r('app.color.black_piece') : $r('app.color.white_piece'))
          .stroke(this.pieceType === PieceType.BLACK ? '#333333' : '#AAAAAA')
          .strokeWidth(1)

        // 最后落子标记
        if (this.isLastMove) {
          Circle({ width: this.boardSize === 30 ? 4 : 6, height: this.boardSize === 30 ? 4 : 6 })
            .fill($r('app.color.last_move_marker'))
        }
      }
    }
    .width(this.cellSize)
    .height(this.cellSize)
    .onClick(() => {
      this.onCellClick(this.row, this.col);
    })
  }
}
