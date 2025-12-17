/**
 * 五子棋游戏主页面
 * 实现棋盘显示、落子交互、悔棋、胜负判定等功能
 */

import { PieceType, GameStatus, GameConfig, DEFAULT_CONFIG, CONFIG_30X30, BOARD_SIZE_OPTIONS } from '../model/GameTypes';
import { GameState } from '../model/GameState';

@Entry
@Component
struct Index {
  // 游戏状态管理
  private gameState: GameState = new GameState(DEFAULT_CONFIG);

  // 版本信息
  private readonly appVersion: string = '1.0.0';
  private readonly author: string = '陈云亮';
  private readonly authorEmail: string = '676814828@qq.com';
  private readonly buildDate: string = '2024.12';

  // UI响应式状态
  @State boardData: PieceType[][] = [];
  @State currentPlayer: PieceType = PieceType.BLACK;
  @State gameStatus: GameStatus = GameStatus.PLAYING;
  @State lastMoveRow: number = -1;
  @State lastMoveCol: number = -1;
  @State totalMoves: number = 0;
  @State selectedBoardSize: number = 15; // 当前选中的棋盘尺寸
  @State boardSize: number = 15;
  @State cellSize: number = 22;
  @State pieceSize: number = 20;

  // 棋盘配置
  private readonly boardPadding: number = 15; // 棋盘边距

  // 星位坐标配置
  private readonly starPoints15: number[][] = [
    [3, 3], [3, 7], [3, 11],
    [7, 3], [7, 7], [7, 11],
    [11, 3], [11, 7], [11, 11]
  ];

  // 30路棋盘星位
  private readonly starPoints30: number[][] = [
    [3, 3], [3, 15], [3, 26],
    [15, 3], [15, 15], [15, 26],
    [26, 3], [26, 15], [26, 26]
  ];

  aboutToAppear(): void {
    this.syncState();
  }

  /**
   * 同步游戏状态到UI
   */
  private syncState(): void {
    this.boardData = this.gameState.getBoard();
    this.currentPlayer = this.gameState.getCurrentPlayer();
    this.gameStatus = this.gameState.getGameStatus();
    this.totalMoves = this.gameState.getTotalMoves();

    const lastMove = this.gameState.getLastMove();
    if (lastMove) {
      this.lastMoveRow = lastMove.row;
      this.lastMoveCol = lastMove.col;
    } else {
      this.lastMoveRow = -1;
      this.lastMoveCol = -1;
    }
  }

  /**
   * 处理落子事件
   */
  private handleCellClick(row: number, col: number): void {
    if (this.gameState.placePiece(row, col)) {
      this.syncState();
    }
  }

  /**
   * 处理悔棋事件
   */
  private handleUndo(): void {
    if (this.gameState.undo()) {
      this.syncState();
    }
  }

  /**
   * 处理重新开始事件
   */
  private handleRestart(): void {
    this.gameState.reset();
    this.syncState();
  }

  /**
   * 获取状态文本
   */
  private getStatusText(): string {
    switch (this.gameStatus) {
      case GameStatus.BLACK_WIN:
        return '黑方获胜！';
      case GameStatus.WHITE_WIN:
        return '白方获胜！';
      case GameStatus.DRAW:
        return '平局！';
      default:
        return this.currentPlayer === PieceType.BLACK ? '黑方回合' : '白方回合';
    }
  }

  /**
   * 检查是否为星位
   */
  private isStarPoint(row: number, col: number): boolean {
    const starPoints = this.boardSize === 15 ? this.starPoints15 : this.starPoints30;
    for (const point of starPoints) {
      if (point[0] === row && point[1] === col) {
        return true;
      }
    }
    return false;
  }

  /**
   * 切换棋盘尺寸
   */
  private switchBoardSize(size: number): void {
    if (size === this.boardSize) {
      return;
    }
    this.selectedBoardSize = size;
    this.boardSize = size;

    // 根据棋盘尺寸调整格子和棋子大小
    if (size === 30) {
      this.cellSize = 12;
      this.pieceSize = 10;
      this.gameState = new GameState(CONFIG_30X30);
    } else {
      this.cellSize = 22;
      this.pieceSize = 20;
      this.gameState = new GameState(DEFAULT_CONFIG);
    }

    this.syncState();
  }

  build() {
    Column() {
      // 标题区域
      Text('五子棋')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.primary_text'))
        .margin({ top: 20, bottom: 10 })

      // 棋盘尺寸选择区域
      Row() {
        Text('棋盘尺寸:')
          .fontSize(14)
          .fontColor($r('app.color.secondary_text'))
          .margin({ right: 10 })

        Button('15×15')
          .fontSize(14)
          .fontColor(this.selectedBoardSize === 15 ? $r('app.color.button_text') : $r('app.color.primary_text'))
          .backgroundColor(this.selectedBoardSize === 15 ? $r('app.color.button_primary') : '#E0E0E0')
          .width(70)
          .height(32)
          .borderRadius(16)
          .onClick(() => this.switchBoardSize(15))

        Button('30×30')
          .fontSize(14)
          .fontColor(this.selectedBoardSize === 30 ? $r('app.color.button_text') : $r('app.color.primary_text'))
          .backgroundColor(this.selectedBoardSize === 30 ? $r('app.color.button_primary') : '#E0E0E0')
          .width(70)
          .height(32)
          .borderRadius(16)
          .margin({ left: 10 })
          .onClick(() => this.switchBoardSize(30))
      }
      .margin({ bottom: 10 })

      // 状态显示区域
      Row() {
        // 当前回合指示器
        if (this.gameStatus === GameStatus.PLAYING) {
          Circle({ width: 24, height: 24 })
            .fill(this.currentPlayer === PieceType.BLACK ?
              $r('app.color.black_turn_indicator') : $r('app.color.white_turn_indicator'))
            .stroke($r('app.color.board_line'))
            .strokeWidth(1)
            .margin({ right: 8 })
        }

        Text(this.getStatusText())
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.gameStatus !== GameStatus.PLAYING ?
            $r('app.color.win_color') : $r('app.color.primary_text'))
      }
      .margin({ bottom: 10 })

      // 步数显示
      Text(`总步数: ${this.totalMoves}`)
        .fontSize(14)
        .fontColor($r('app.color.secondary_text'))
        .margin({ bottom: 15 })

      // 棋盘区域
      Stack() {
        // 棋盘背景
        Column() {
          // 绘制棋盘网格
          ForEach(this.getRowIndices(), (row: number) => {
            Row() {
              ForEach(this.getColIndices(), (col: number) => {
                this.BoardCell(row, col)
              })
            }
          })
        }
        .backgroundColor($r('app.color.board_background'))
        .padding(this.boardPadding)
        .borderRadius(8)
        .shadow({
          radius: 10,
          color: '#33000000',
          offsetX: 2,
          offsetY: 4
        })
      }
      .margin({ bottom: 20 })

      // 操作按钮区域
      Row() {
        Button('悔棋')
          .fontSize(16)
          .fontColor($r('app.color.button_text'))
          .backgroundColor($r('app.color.button_secondary'))
          .width(100)
          .height(44)
          .borderRadius(22)
          .enabled(this.totalMoves > 0)
          .opacity(this.totalMoves > 0 ? 1 : 0.5)
          .onClick(() => this.handleUndo())

        Button('重新开始')
          .fontSize(16)
          .fontColor($r('app.color.button_text'))
          .backgroundColor($r('app.color.button_primary'))
          .width(120)
          .height(44)
          .borderRadius(22)
          .margin({ left: 20 })
          .onClick(() => this.handleRestart())
      }
      .margin({ bottom: 20 })

      // 版本信息和关于作者
      Column() {
        Text(`v${this.appVersion}`)
          .fontSize(12)
          .fontColor($r('app.color.secondary_text'))
          .margin({ bottom: 4 })

        Text(`作者: ${this.author}`)
          .fontSize(11)
          .fontColor($r('app.color.secondary_text'))
          .margin({ bottom: 2 })

        Text(this.authorEmail)
          .fontSize(10)
          .fontColor($r('app.color.secondary_text'))
      }
      .margin({ bottom: 15 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 获取行索引数组
   */
  private getRowIndices(): number[] {
    const indices: number[] = [];
    for (let i = 0; i < this.boardSize; i++) {
      indices.push(i);
    }
    return indices;
  }

  /**
   * 获取列索引数组
   */
  private getColIndices(): number[] {
    const indices: number[] = [];
    for (let i = 0; i < this.boardSize; i++) {
      indices.push(i);
    }
    return indices;
  }

  /**
   * 棋盘单元格组件
   */
  @Builder
  BoardCell(row: number, col: number) {
    Stack() {
      // 绘制网格线
      Canvas(new CanvasRenderingContext2D(new RenderingContextSettings(true)))
        .width(this.cellSize)
        .height(this.cellSize)
        .onReady(() => { })

      // 网格线背景
      Column() {
        // 水平线
        if (row > 0 || row < this.boardSize - 1) {
          Line()
            .width(col === 0 ? this.cellSize / 2 : (col === this.boardSize - 1 ? this.cellSize / 2 : this.cellSize))
            .height(1)
            .backgroundColor($r('app.color.board_line'))
            .position({
              x: col === 0 ? this.cellSize / 2 : 0,
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
          .height(row === 0 ? this.cellSize / 2 : (row === this.boardSize - 1 ? this.cellSize / 2 : this.cellSize))
          .backgroundColor($r('app.color.board_line'))
          .position({
            x: this.cellSize / 2,
            y: row === 0 ? this.cellSize / 2 : 0
          })
      }
      .width(this.cellSize)
      .height(this.cellSize)

      // 星位
      if (this.isStarPoint(row, col)) {
        Circle({ width: this.boardSize === 30 ? 4 : 6, height: this.boardSize === 30 ? 4 : 6 })
          .fill($r('app.color.star_point'))
      }

      // 棋子
      if (this.boardData.length > row && this.boardData[row].length > col) {
        if (this.boardData[row][col] !== PieceType.EMPTY) {
          Stack() {
            // 棋子本体
            Circle({ width: this.pieceSize, height: this.pieceSize })
              .fill(this.boardData[row][col] === PieceType.BLACK ?
                $r('app.color.black_piece') : $r('app.color.white_piece'))
              .shadow({
                radius: 3,
                color: '#66000000',
                offsetX: 1,
                offsetY: 2
              })

            // 最后落子标记
            if (row === this.lastMoveRow && col === this.lastMoveCol) {
              Circle({ width: this.boardSize === 30 ? 4 : 6, height: this.boardSize === 30 ? 4 : 6 })
                .fill($r('app.color.last_move_marker'))
            }
          }
        }
      }
    }
    .width(this.cellSize)
    .height(this.cellSize)
    .onClick(() => {
      this.handleCellClick(row, col);
    })
  }
}
