/**
 * 五子棋游戏主页面
 * 实现棋盘显示、落子交互、悔棋、胜负判定等功能
 */

import { PieceType, GameStatus, GameConfig, DEFAULT_CONFIG, CONFIG_30X30, BOARD_SIZE_OPTIONS } from '../model/GameTypes';
import { GameState } from '../model/GameState';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { media } from '@kit.MediaKit';

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
  @State isMaximized: boolean = false; // 最大化模式


  
  // 缩放相关状态（最大化模式使用）
  @State scaleValue: number = 1; // 当前缩放比例
  @State pinchValue: number = 1; // 捏合手势的缩放值
  @State minScale: number = 1.0; // 最小缩放
  @State maxScale: number = 2.0; // 最大缩放
  private baseCellSize30: number = 12; // 30路棋盘基础格子大小
  private basePieceSize30: number = 10; // 30路棋盘基础棋子大小
  private defaultScale15: number = 2.0; // 15路最大化默认缩放 200%
  private defaultScale30: number = 4.0; // 30路最大化默认缩放 400%
  private minScale15: number = 1.0; // 15路最小缩放 100%
  private maxScale15: number = 2.0; // 15路最大缩放 200%
  private minScale30: number = 1.0; // 30路最小缩放 100%
  private maxScale30: number = 4.0; // 30路最大缩放 400%
  
  // 拖动相关状态（最大化模式使用）
  @State offsetX: number = 0; // 水平偏移
  @State offsetY: number = 0; // 垂直偏移
  private panOffsetX: number = 0; // 拖动手势的水平偏移
  private panOffsetY: number = 0; // 拖动手势的垂直偏移

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

  // 音频播放器
  private blackPiecePlayer: media.AVPlayer | null = null;
  private whitePiecePlayer: media.AVPlayer | null = null;
  @State soundEnabled: boolean = true; // 是否启用声音

  aboutToAppear(): void {
    this.syncState();
    this.initAudioPlayers();
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
   * 初始化音频播放器
   */
  private async initAudioPlayers(): Promise<void> {
    try {
      // 创建黑子音效播放器
      this.blackPiecePlayer = await media.createAVPlayer();
      this.blackPiecePlayer.url = 'resource://rawfile/black_piece.mp3';
      
      // 创建白子音效播放器
      this.whitePiecePlayer = await media.createAVPlayer();
      this.whitePiecePlayer.url = 'resource://rawfile/white_piece.mp3';
      
      hilog.info(0x0000, 'GamePlay', 'Audio players initialized');
    } catch (error) {
      hilog.error(0x0000, 'GamePlay', `Failed to initialize audio players: ${error}`);
    }
  }

  /**
   * 播放落子音效
   */
  private playPieceSound(pieceType: PieceType): void {
    if (!this.soundEnabled) {
      return;
    }
    
    try {
      if (pieceType === PieceType.BLACK && this.blackPiecePlayer) {
        // 重置并播放黑子音效
        this.blackPiecePlayer.seek(0);
        this.blackPiecePlayer.play();
        hilog.info(0x0000, 'GamePlay', 'Playing black piece sound');
      } else if (pieceType === PieceType.WHITE && this.whitePiecePlayer) {
        // 重置并播放白子音效
        this.whitePiecePlayer.seek(0);
        this.whitePiecePlayer.play();
        hilog.info(0x0000, 'GamePlay', 'Playing white piece sound');
      }
    } catch (error) {
      hilog.error(0x0000, 'GamePlay', `Failed to play sound: ${error}`);
    }
  }

  /**
   * 处理落子事件
   */
  private handleCellClick(row: number, col: number): void {
    hilog.info(0x0000, 'GamePlay', `=== Cell clicked: row=${row}, col=${col} ===`);
    hilog.info(0x0000, 'GamePlay', `Current player: ${this.currentPlayer === PieceType.BLACK ? 'BLACK' : 'WHITE'}`);
    hilog.info(0x0000, 'GamePlay', `Game status: ${this.gameStatus}`);
    hilog.info(0x0000, 'GamePlay', `Total moves before: ${this.totalMoves}`);
    
    // 保存当前玩家（落子前）
    const currentPieceType = this.currentPlayer;
    
    if (this.gameState.placePiece(row, col)) {
      hilog.info(0x0000, 'GamePlay', `Piece placed successfully at (${row}, ${col})`);
      // 播放落子音效
      this.playPieceSound(currentPieceType);
      this.syncState();
      hilog.info(0x0000, 'GamePlay', `Total moves after: ${this.totalMoves}`);
      hilog.info(0x0000, 'GamePlay', `New game status: ${this.gameStatus}`);
    } else {
      hilog.warn(0x0000, 'GamePlay', `Failed to place piece at (${row}, ${col}) - position may be occupied or game is over`);
    }
  }

  /**
   * 处理悔棋事件
   */
  private handleUndo(): void {
    hilog.info(0x0000, 'GamePlay', '=== Undo button clicked ===');
    hilog.info(0x0000, 'GamePlay', `Total moves before undo: ${this.totalMoves}`);
    
    if (this.gameState.undo()) {
      hilog.info(0x0000, 'GamePlay', 'Undo successful');
      this.syncState();
      hilog.info(0x0000, 'GamePlay', `Total moves after undo: ${this.totalMoves}`);
    } else {
      hilog.warn(0x0000, 'GamePlay', 'Undo failed - no moves to undo');
    }
  }

  /**
   * 处理重新开始事件
   */
  private handleRestart(): void {
    hilog.info(0x0000, 'GamePlay', '=== Restart button clicked ===');
    
    
    this.gameState.reset();
    this.syncState();
    hilog.info(0x0000, 'GamePlay', 'Game reset successfully');
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
    hilog.info(0x0000, 'GamePlay', `=== Switch board size clicked: ${size} ===`);
    
    if (size === this.boardSize) {
      hilog.info(0x0000, 'GamePlay', `Board size already ${size}, no change needed`);
      return;
    }
    
    this.selectedBoardSize = size;
    this.boardSize = size;
    this.isMaximized = false; // 重置最大化状态
    hilog.info(0x0000, 'GamePlay', `Board size changed to: ${size}`);

    // 根据棋盘尺寸调整格子和棋子大小
    if (size === 30) {
      this.cellSize = this.baseCellSize30;
      this.pieceSize = this.basePieceSize30;
      this.scaleValue = 1; // 重置缩放
      this.pinchValue = 1;
      this.offsetX = 0; // 重置偏移
      this.offsetY = 0;
      this.panOffsetX = 0;
      this.panOffsetY = 0;
      this.gameState = new GameState(CONFIG_30X30);
      hilog.info(0x0000, 'GamePlay', '30x30 board initialized with scaling support');
    } else {
      this.cellSize = 22;
      this.pieceSize = 20;
      this.scaleValue = 1;
      this.pinchValue = 1;
      this.offsetX = 0;
      this.offsetY = 0;
      this.panOffsetX = 0;
      this.panOffsetY = 0;
      this.gameState = new GameState(DEFAULT_CONFIG);
      hilog.info(0x0000, 'GamePlay', '15x15 board initialized');
    }

    this.syncState();
  }



  build() {
    Column() {
      // 标题区域（非最大化模式显示）
      if (!this.isMaximized) {
        Text('FiveInRow 五子棋')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.primary_text'))
          .margin({ top: 20, bottom: 10 })
      }



      // 棋盘尺寸选择区域（非最大化模式显示）
      if (!this.isMaximized) {
        Row() {
          Text('棋盘尺寸:')
            .fontSize(14)
            .fontColor($r('app.color.secondary_text'))
            .margin({ right: 10 })

          Button('15×15')
            .fontSize(14)
            .fontColor(this.selectedBoardSize === 15 ? $r('app.color.button_text') : $r('app.color.primary_text'))
            .backgroundColor(this.selectedBoardSize === 15 ? $r('app.color.button_primary') : '#E0E0E0')
            .width(80)
            .height(32)
            .borderRadius(16)
            .onClick(() => this.switchBoardSize(15))

          Button('30×30')
            .fontSize(14)
            .fontColor(this.selectedBoardSize === 30 ? $r('app.color.button_text') : $r('app.color.primary_text'))
            .backgroundColor(this.selectedBoardSize === 30 ? $r('app.color.button_primary') : '#E0E0E0')
            .width(80)
            .height(32)
            .borderRadius(16)
            .margin({ left: 10 })
            .onClick(() => this.switchBoardSize(30))
        }
        .margin({ bottom: 5 })

        // 最大化按钮和声音开关
        Row() {
          Button('最大化')
            .fontSize(14)
            .fontColor($r('app.color.button_text'))
            .backgroundColor('#FF6B35')
            .width(80)
            .height(32)
            .borderRadius(16)
            .onClick(() => this.toggleMaximize())

          Button(this.soundEnabled ? '🔊 声音' : '🔇 静音')
            .fontSize(14)
            .fontColor($r('app.color.button_text'))
            .backgroundColor(this.soundEnabled ? '#4CAF50' : '#9E9E9E')
            .width(80)
            .height(32)
            .borderRadius(16)
            .margin({ left: 10 })
            .onClick(() => {
              this.soundEnabled = !this.soundEnabled;
            })
        }
        .margin({ bottom: 10 })
      }



      // 状态显示区域（非最大化模式显示完整信息）
      if (!this.isMaximized) {
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
          .margin({ bottom: this.boardSize === 30 ? 5 : 15 })
      }
      
      // 最大化模式：简化状态显示
      if (this.isMaximized) {
        Row() {
          // 缩小按钮
          Button('退出最大化')
            .fontSize(12)
            .fontColor($r('app.color.button_text'))
            .backgroundColor('#FF6B35')
            .height(28)
            .borderRadius(14)
            .margin({ right: 15 })
            .onClick(() => this.toggleMaximize())

          // 当前回合指示器
          if (this.gameStatus === GameStatus.PLAYING) {
            Circle({ width: 20, height: 20 })
              .fill(this.currentPlayer === PieceType.BLACK ?
                $r('app.color.black_turn_indicator') : $r('app.color.white_turn_indicator'))
              .stroke($r('app.color.board_line'))
              .strokeWidth(1)
              .margin({ right: 6 })
          }

          Text(this.getStatusText())
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.gameStatus !== GameStatus.PLAYING ?
              $r('app.color.win_color') : $r('app.color.primary_text'))

          Text(` | ${(this.scaleValue * 100).toFixed(0)}%`)
            .fontSize(12)
            .fontColor($r('app.color.secondary_text'))
            .margin({ left: 10 })

          Text(' | 双指缩放/移动')
            .fontSize(11)
            .fontColor('#888888')
            .margin({ left: 8 })
        }
        .margin({ top: 0, bottom: 0 })
      }
      
      // 缩放提示（非最大化的30×30棋盘）
      if (!this.isMaximized && this.boardSize === 30) {
        Text(`双指缩放: ${(this.scaleValue * 100).toFixed(0)}% | 支持双指拖拽移动`)
          .fontSize(12)
          .fontColor($r('app.color.secondary_text'))
          .margin({ bottom: 10 })
      }

      // 棋盘区域
      if (this.isMaximized || this.boardSize === 30) {
        // 最大化模式或30×30棋盘：支持缩放和拖拽
        Stack() {
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
          .scale({ x: this.scaleValue, y: this.scaleValue })
          .translate({ x: this.offsetX, y: this.offsetY })
        }
        .width('100%')
        .height('100%')
        .clip(true)
        .gesture(
          GestureGroup(GestureMode.Parallel,
            // 双指缩放手势（15×15和30×30都支持缩放）
            PinchGesture({ fingers: 2 })
              .onActionStart((event: GestureEvent) => {
                this.pinchValue = this.scaleValue;
              })
              .onActionUpdate((event: GestureEvent) => {
                if (event && event.scale) {
                  let newScale = this.pinchValue * event.scale;
                  // 根据棋盘尺寸使用不同的缩放限制
                  const minLimit = this.boardSize === 15 ? this.minScale15 : this.minScale30;
                  const maxLimit = this.boardSize === 15 ? this.maxScale15 : this.maxScale30;
                  newScale = Math.max(minLimit, Math.min(maxLimit, newScale));
                  this.scaleValue = newScale;
                }
              })
              .onActionEnd(() => {
                this.pinchValue = this.scaleValue;
              }),
            // 双指拖动手势
            PanGesture({ fingers: 2, direction: PanDirection.All })
              .onActionStart(() => {
                this.panOffsetX = this.offsetX;
                this.panOffsetY = this.offsetY;
              })
              .onActionUpdate((event: GestureEvent) => {
                if (event) {
                  this.offsetX = this.panOffsetX + (event.offsetX || 0);
                  this.offsetY = this.panOffsetY + (event.offsetY || 0);
                }
              })
              .onActionEnd(() => {
                this.panOffsetX = this.offsetX;
                this.panOffsetY = this.offsetY;
              })
          )
        )
        .layoutWeight(1)
        .margin({ bottom: this.isMaximized ? 0 : 10 })
      } else {
        // 15×15棋盘非最大化：保持原样
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
      }

      // 操作按钮区域
      Row() {
        Button('悔棋')
          .fontSize(this.isMaximized ? 14 : 16)
          .fontColor($r('app.color.button_text'))
          .backgroundColor($r('app.color.button_secondary'))
          .width(this.isMaximized ? 80 : 100)
          .height(this.isMaximized ? 36 : 44)
          .borderRadius(this.isMaximized ? 18 : 22)
          .enabled(this.totalMoves > 0)
          .opacity(this.totalMoves > 0 ? 1 : 0.5)
          .onClick(() => this.handleUndo())

        Button('重新开始')
          .fontSize(this.isMaximized ? 14 : 16)
          .fontColor($r('app.color.button_text'))
          .backgroundColor($r('app.color.button_primary'))
          .width(this.isMaximized ? 100 : 120)
          .height(this.isMaximized ? 36 : 44)
          .borderRadius(this.isMaximized ? 18 : 22)
          .margin({ left: 20 })
          .enabled(this.totalMoves > 0)
          .opacity(this.totalMoves > 0 ? 1 : 0.5)
          .onClick(() => this.handleRestart())
      }
      .margin({ bottom: this.isMaximized ? 0 : (this.boardSize === 30 ? 10 : 20) })

      // 版本信息和关于作者（非最大化模式显示）
      if (!this.isMaximized) {
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
        .margin({ bottom: this.boardSize === 30 ? 10 : 15 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 切换最大化模式
   */
  private toggleMaximize(): void {
    this.isMaximized = !this.isMaximized;
    hilog.info(0x0000, 'GamePlay', `Maximize mode: ${this.isMaximized}`);

    if (this.isMaximized) {
      // 进入最大化模式，设置默认缩放和缩放限制
      if (this.boardSize === 15) {
        this.scaleValue = this.defaultScale15; // 15×15 默认放大200%
        this.minScale = this.minScale15;
        this.maxScale = this.maxScale15;
      } else {
        this.scaleValue = this.defaultScale30; // 30×30 默认放大300%
        this.minScale = this.minScale30;
        this.maxScale = this.maxScale30;
      }
      this.pinchValue = this.scaleValue;
      this.offsetX = 0;
      this.offsetY = 0;
      this.panOffsetX = 0;
      this.panOffsetY = 0;
    } else {
      // 退出最大化模式，恢复默认缩放
      this.scaleValue = 1;
      this.pinchValue = 1;
      this.offsetX = 0;
      this.offsetY = 0;
      this.panOffsetX = 0;
      this.panOffsetY = 0;
    }
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
          // 棋子本体
          Circle({ width: this.pieceSize, height: this.pieceSize })
            .fill(this.boardData[row][col] === PieceType.BLACK ?
              $r('app.color.black_piece') : $r('app.color.white_piece'))
            .stroke(this.boardData[row][col] === PieceType.BLACK ? '#000000' : '#CCCCCC')
            .strokeWidth(0.5)
            .shadow({
              radius: 2,
              color: '#44000000',
              offsetX: 1,
              offsetY: 1
            })

          // 最后落子标记
          if (row === this.lastMoveRow && col === this.lastMoveCol) {
            Circle({ width: this.boardSize === 30 ? 4 : 6, height: this.boardSize === 30 ? 4 : 6 })
              .fill($r('app.color.last_move_marker'))
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
