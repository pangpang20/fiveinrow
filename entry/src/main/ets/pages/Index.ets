/**
 * 五子棋游戏主页面
 * 实现棋盘显示、落子交互、悔棋、胜负判定等功能
 */

import { PieceType, GameStatus, DEFAULT_CONFIG, CONFIG_30X30 } from '../model/GameTypes';
import { GameState } from '../model/GameState';
import { AudioManager } from '../model/AudioManager';
import { APP_INFO, BOARD_LAYOUT, SCALE_CONFIG, isStarPoint, getIndices } from '../model/GameConstants';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 礼花粒子接口
interface ConfettiItem {
  id: number;
  x: number;
  y: number;
  color: string;
  size: number;
  rotation: number;
  symbol: string;
}

@Entry
@Component
struct Index {
  // 游戏状态管理
  private gameState: GameState = new GameState(DEFAULT_CONFIG);
  private audioManager: AudioManager = AudioManager.getInstance();

  // UI响应式状态
  @State boardData: PieceType[][] = [];
  @State currentPlayer: PieceType = PieceType.BLACK;
  @State gameStatus: GameStatus = GameStatus.PLAYING;
  @State lastMoveRow: number = -1;
  @State lastMoveCol: number = -1;
  @State totalMoves: number = 0;
  @State selectedBoardSize: number = 15;
  @State boardSize: number = 15;
  @State cellSize: number = BOARD_LAYOUT.board15.cellSize;
  @State pieceSize: number = BOARD_LAYOUT.board15.pieceSize;
  @State isMaximized: boolean = false;
  @State soundEnabled: boolean = true;

  // 庆祝动画状态
  @State showCelebration: boolean = false;
  @State celebrationText: string = '';
  @State winnerText: string = '';
  @State confettiItems: ConfettiItem[] = [];
  private celebrationTimer: number = -1;

  // 夸奖语列表
  private readonly praises: string[] = [
    '真棒！🎉',
    '太厉害了！👏',
    '神乎其技！✨',
    '无人能敌！💪',
    '棋艺超群！🏆',
    '完美胜利！🌟',
    '天才棋手！🧠',
    '实力超群！🔥',
    '战无不胜！⚔️',
    '霸气十足！👑',
    '高手如云！☁️',
    '技惊四座！🌍'
  ];

  // 缩放相关状态（最大化模式使用）
  @State scaleValue: number = 1;
  @State pinchValue: number = 1;
  @State minScale: number = 1.0;
  @State maxScale: number = 2.0;

  // 拖动相关状态（最大化模式使用）
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  private panOffsetX: number = 0;
  private panOffsetY: number = 0;

  aboutToAppear(): void {
    this.syncState();
    // 获取 Context 并初始化音频管理器
    const context = getContext(this);
    this.audioManager.setContext(context);
    this.audioManager.initialize();
  }

  aboutToDisappear(): void {
    this.audioManager.release();
  }

  /**
   * 同步游戏状态到UI
   */
  private syncState(): void {
    const previousStatus = this.gameStatus;
    
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

    // 检测是否刚刚获胜，触发庆祝动画
    if (previousStatus === GameStatus.PLAYING) {
      if (this.gameStatus === GameStatus.BLACK_WIN) {
        this.triggerCelebration(true);
      } else if (this.gameStatus === GameStatus.WHITE_WIN) {
        this.triggerCelebration(false);
      }
    }
  }

  /**
   * 处理落子事件
   */
  private handleCellClick(row: number, col: number): void {
    hilog.info(0x0000, 'GamePlay', `Cell clicked: row=${row}, col=${col}`);

    const currentPieceType = this.currentPlayer;

    if (this.gameState.placePiece(row, col)) {
      hilog.info(0x0000, 'GamePlay', `Piece placed at (${row}, ${col})`);
      if (this.soundEnabled) {
        this.audioManager.playPieceSound(currentPieceType);
      }
      this.syncState();
    }
  }

  /**
   * 处理悔棋事件
   */
  private handleUndo(): void {
    if (this.gameState.undo()) {
      hilog.info(0x0000, 'GamePlay', 'Undo successful');
      this.syncState();
    }
  }

  /**
   * 处理重新开始事件
   */
  private handleRestart(): void {
    this.closeCelebration();
    this.gameState.reset();
    this.syncState();
    hilog.info(0x0000, 'GamePlay', 'Game reset');
  }

  /**
   * 触发庆祝动画
   */
  private triggerCelebration(isBlackWin: boolean): void {
    // 设置获胜者文本
    this.winnerText = isBlackWin ? '⬛ 黑方获胜！' : '⬜ 白方获胜！';
    
    // 随机选择夸奖语
    const randomIndex = Math.floor(Math.random() * this.praises.length);
    this.celebrationText = this.praises[randomIndex];
    
    // 生成礼花粒子
    this.generateConfetti();
    
    // 显示庆祝弹窗
    this.showCelebration = true;
    
    // 5秒后自动关闭
    this.celebrationTimer = setTimeout(() => {
      this.showCelebration = false;
    }, 5000) as number;
  }

  /**
   * 生成礼花粒子
   */
  private generateConfetti(): void {
    const colors = [
      '#FFD700', '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', 
      '#FFEAA7', '#DDA0DD', '#98D8C8', '#F7DC6F', '#BB8FCE', 
      '#85C1E9', '#FF69B4', '#00CED1', '#FF4500', '#32CD32'
    ];
    const symbols = ['✨', '⭐', '🌟', '♥', '◆', '●', '💎', '🌈'];
    const items: ConfettiItem[] = [];
    
    // 创建更多粒子，均匀分布
    for (let i = 0; i < 100; i++) {
      items.push({
        id: i,
        x: Math.random() * 100,
        y: Math.random() * 100,
        color: colors[Math.floor(Math.random() * colors.length)],
        size: 14 + Math.random() * 22,
        rotation: Math.random() * 360,
        symbol: symbols[Math.floor(Math.random() * symbols.length)]
      });
    }
    
    this.confettiItems = items;
  }

  /**
   * 关闭庆祝弹窗
   */
  private closeCelebration(): void {
    this.showCelebration = false;
    if (this.celebrationTimer !== -1) {
      clearTimeout(this.celebrationTimer);
      this.celebrationTimer = -1;
    }
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
   * 切换棋盘尺寸
   */
  private switchBoardSize(size: number): void {
    if (size === this.boardSize) return;

    this.selectedBoardSize = size;
    this.boardSize = size;
    this.isMaximized = false;
    this.resetTransform();

    if (size === 30) {
      this.cellSize = BOARD_LAYOUT.board30.baseCellSize;
      this.pieceSize = BOARD_LAYOUT.board30.basePieceSize;
      this.gameState = new GameState(CONFIG_30X30);
    } else {
      this.cellSize = BOARD_LAYOUT.board15.cellSize;
      this.pieceSize = BOARD_LAYOUT.board15.pieceSize;
      this.gameState = new GameState(DEFAULT_CONFIG);
    }

    this.syncState();
    hilog.info(0x0000, 'GamePlay', `Board size changed to: ${size}`);
  }

  /**
   * 切换最大化模式
   */
  private toggleMaximize(): void {
    this.isMaximized = !this.isMaximized;

    if (this.isMaximized) {
      const config = this.boardSize === 30 ? SCALE_CONFIG.scale30 : SCALE_CONFIG.scale15;
      this.scaleValue = config.defaultValue;
      this.minScale = config.min;
      this.maxScale = config.max;
      this.pinchValue = this.scaleValue;
    } else {
      this.resetTransform();
    }

    hilog.info(0x0000, 'GamePlay', `Maximize mode: ${this.isMaximized}`);
  }

  /**
   * 重置变换状态
   */
  private resetTransform(): void {
    this.scaleValue = 1;
    this.pinchValue = 1;
    this.offsetX = 0;
    this.offsetY = 0;
    this.panOffsetX = 0;
    this.panOffsetY = 0;
  }

  build() {
    Stack() {
      // 主内容
      Column() {
      // 标题区域（非最大化模式）
      if (!this.isMaximized) {
        Text('FiveInRow互动五子棋')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.primary_text'))
          .margin({ top: 20, bottom: 10 })

        // 棋盘尺寸选择
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

        // 最大化和声音开关
        Row() {
          Button('最大化')
            .fontSize(14)
            .fontColor($r('app.color.button_text'))
            .backgroundColor('#FF6B35')
            .width(80)
            .height(32)
            .borderRadius(16)
            .onClick(() => this.toggleMaximize())

          Button(this.soundEnabled ? '声音 开' : '声音 关')
            .fontSize(14)
            .fontColor($r('app.color.button_text'))
            .backgroundColor(this.soundEnabled ? '#4CAF50' : '#9E9E9E')
            .width(80)
            .height(32)
            .borderRadius(16)
            .margin({ left: 10 })
            .onClick(() => {
              this.soundEnabled = !this.soundEnabled;
              this.audioManager.setSoundEnabled(this.soundEnabled);
            })
        }
        .margin({ bottom: 10 })

        // 状态显示
        Row() {
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

        Text(`总步数: ${this.totalMoves}`)
          .fontSize(14)
          .fontColor($r('app.color.secondary_text'))
          .margin({ bottom: this.boardSize === 30 ? 5 : 15 })
      }

      // 最大化模式：简化状态栏
      if (this.isMaximized) {
        Row() {
          Button('退出最大化')
            .fontSize(12)
            .fontColor($r('app.color.button_text'))
            .backgroundColor('#FF6B35')
            .height(28)
            .borderRadius(14)
            .margin({ right: 15 })
            .onClick(() => this.toggleMaximize())

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

          Text(' | 双指缩放/三指移动')
            .fontSize(11)
            .fontColor('#888888')
            .margin({ left: 8 })
        }
        .margin({ top: 0, bottom: 0 })
      }

      // 非最大化30路缩放提示
      if (!this.isMaximized && this.boardSize === 30) {
        Text(`双指缩放: ${(this.scaleValue * 100).toFixed(0)}% | 支持三指拖拽移动`)
          .fontSize(12)
          .fontColor($r('app.color.secondary_text'))
          .margin({ bottom: 10 })
      }

      // 棋盘区域
      if (this.isMaximized || this.boardSize === 30) {
        this.ScalableBoard()
      } else {
        this.StaticBoard()
      }

      // 操作按钮
      Row() {
        Button('悔棋')
          .fontSize(this.isMaximized ? 14 : 16)
          .fontColor($r('app.color.button_text'))
          .backgroundColor($r('app.color.button_secondary'))
          .width(this.isMaximized ? 80 : 100)
          .height(this.isMaximized ? 36 : 44)
          .borderRadius(this.isMaximized ? 18 : 22)
          .enabled(this.totalMoves > 0 && this.gameStatus === GameStatus.PLAYING)
          .opacity(this.totalMoves > 0 && this.gameStatus === GameStatus.PLAYING ? 1 : 0.5)
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

      // 版本信息（非最大化模式）
      if (!this.isMaximized) {
        Column() {
          Text(`v${APP_INFO.version}`)
            .fontSize(12)
            .fontColor($r('app.color.secondary_text'))
            .margin({ bottom: 4 })

          Text(`作者: ${APP_INFO.author}`)
            .fontSize(11)
            .fontColor($r('app.color.secondary_text'))
            .margin({ bottom: 2 })

          Text(APP_INFO.email)
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

      // 庆祝弹窗层
      if (this.showCelebration) {
        Stack() {
          // 半透明背景
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('#99000000')
            .onClick(() => this.closeCelebration())

          // 礼花粒子
          ForEach(this.confettiItems, (item: ConfettiItem) => {
            Text(item.symbol)
              .fontSize(item.size)
              .fontColor(item.color)
              .position({ x: `${item.x}%`, y: `${item.y}%` })
              .rotate({ angle: item.rotation })
              .opacity(0.85)
              .shadow({ radius: 8, color: item.color, offsetX: 0, offsetY: 0 })
          })

          // 中心内容卡片
          Column() {
            // 获胜者文本
            Text(this.winnerText)
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .margin({ bottom: 16 })
              .textShadow({ radius: 10, color: '#000000', offsetX: 2, offsetY: 2 })

            // 夸奖语
            Text(this.celebrationText)
              .fontSize(52)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFD700')
              .margin({ bottom: 30 })
              .textShadow({ radius: 15, color: '#FF8C00', offsetX: 0, offsetY: 0 })

            // 分割线
            Row()
              .width(120)
              .height(3)
              .backgroundColor('#FFD700')
              .borderRadius(2)
              .margin({ bottom: 30 })

            // 再来一局按钮
            Button('🎮 再来一局')
              .fontSize(18)
              .fontColor('#FFFFFF')
              .backgroundColor('#4CAF50')
              .width(180)
              .height(55)
              .borderRadius(28)
              .shadow({ radius: 15, color: '#2E7D32', offsetX: 0, offsetY: 5 })
              .onClick(() => {
                this.closeCelebration();
                this.handleRestart();
              })
          }
          .padding(40)
          .backgroundColor('#CC000000')
          .borderRadius(24)
          .shadow({ radius: 30, color: '#000000', offsetX: 0, offsetY: 10 })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 可缩放棋盘（最大化或30路）
   */
  @Builder
  ScalableBoard() {
    Stack() {
      Column() {
        ForEach(getIndices(this.boardSize), (row: number) => {
          Row() {
            ForEach(getIndices(this.boardSize), (col: number) => {
              this.BoardCell(row, col)
            })
          }
        })
      }
      .backgroundColor($r('app.color.board_background'))
      .padding(BOARD_LAYOUT.padding)
      .borderRadius(8)
      .shadow({ radius: 10, color: '#33000000', offsetX: 2, offsetY: 4 })
      .scale({ x: this.scaleValue, y: this.scaleValue })
      .translate({ x: this.offsetX, y: this.offsetY })
    }
    .width('100%')
    .height('100%')
    .clip(true)
    .gesture(
      GestureGroup(GestureMode.Exclusive,
        // 三指移动手势（优先级更高，放在前面）
        PanGesture({ fingers: 3, direction: PanDirection.All })
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
          }),
        // 双指缩放手势
        PinchGesture({ fingers: 2 })
          .onActionStart(() => { this.pinchValue = this.scaleValue; })
          .onActionUpdate((event: GestureEvent) => {
            if (event?.scale) {
              const config = this.boardSize === 30 ? SCALE_CONFIG.scale30 : SCALE_CONFIG.scale15;
              let newScale = this.pinchValue * event.scale;
              this.scaleValue = Math.max(config.min, Math.min(config.max, newScale));
            }
          })
          .onActionEnd(() => { this.pinchValue = this.scaleValue; })
      )
    )
    .layoutWeight(1)
    .margin({ bottom: this.isMaximized ? 0 : 10 })
  }

  /**
   * 静态棋盘（15路非最大化）
   */
  @Builder
  StaticBoard() {
    Stack() {
      Column() {
        ForEach(getIndices(this.boardSize), (row: number) => {
          Row() {
            ForEach(getIndices(this.boardSize), (col: number) => {
              this.BoardCell(row, col)
            })
          }
        })
      }
      .backgroundColor($r('app.color.board_background'))
      .padding(BOARD_LAYOUT.padding)
      .borderRadius(8)
      .shadow({ radius: 10, color: '#33000000', offsetX: 2, offsetY: 4 })
    }
    .margin({ bottom: 20 })
  }

  /**
   * 棋盘单元格
   */
  @Builder
  BoardCell(row: number, col: number) {
    Stack() {
      Canvas(new CanvasRenderingContext2D(new RenderingContextSettings(true)))
        .width(this.cellSize)
        .height(this.cellSize)
        .onReady(() => { })

      // 水平线
      Column() {
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
      if (isStarPoint(row, col, this.boardSize)) {
        Circle({ width: this.boardSize === 30 ? 4 : 6, height: this.boardSize === 30 ? 4 : 6 })
          .fill($r('app.color.star_point'))
      }

      // 棋子
      if (this.boardData.length > row && this.boardData[row].length > col) {
        if (this.boardData[row][col] !== PieceType.EMPTY) {
          Circle({ width: this.pieceSize, height: this.pieceSize })
            .fill(this.boardData[row][col] === PieceType.BLACK ?
              $r('app.color.black_piece') : $r('app.color.white_piece'))
            .stroke(this.boardData[row][col] === PieceType.BLACK ? '#333333' : 'transparent')
            .strokeWidth(this.boardData[row][col] === PieceType.BLACK ? 1 : 0)

          if (row === this.lastMoveRow && col === this.lastMoveCol) {
            Circle({ width: this.boardSize === 30 ? 4 : 6, height: this.boardSize === 30 ? 4 : 6 })
              .fill($r('app.color.last_move_marker'))
          }
        }
      }
    }
    .width(this.cellSize)
    .height(this.cellSize)
    .onClick(() => { this.handleCellClick(row, col); })
  }
}
