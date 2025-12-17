/**
 * 五子棋游戏主页面
 * 实现棋盘显示、落子交互、悔棋、胜负判定等功能
 */

import { PieceType, GameStatus, GameConfig, DEFAULT_CONFIG, CONFIG_30X30, BOARD_SIZE_OPTIONS } from '../model/GameTypes';
import { GameState } from '../model/GameState';
import { gamePlayer } from '@kit.GameServiceKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

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

  // 登录与模式状态
  private readonly LOGIN_MODE_NONE: number = 0;
  private readonly LOGIN_MODE_HUAWEI: number = 1;
  private readonly LOGIN_MODE_GUEST: number = 2;
  @State loginMode: number = 0;
  @State guestPlayCount: number = 0;
  private readonly guestPlayLimit: number = 3;
  @State playerAccountName: string = '';
  
  // 缩放相关状态（仅30×30棋盘使用）
  @State scaleValue: number = 1; // 当前缩放比例
  @State pinchValue: number = 1; // 捏合手势的缩放值
  @State minScale: number = 0.5; // 最小缩放
  @State maxScale: number = 3.0; // 最大缩放
  private baseCellSize30: number = 12; // 30路棋盘基础格子大小
  private basePieceSize30: number = 10; // 30路棋盘基础棋子大小
  
  // 拖动相关状态（仅30×30棋盘缩放后使用）
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
    if (this.loginMode === this.LOGIN_MODE_GUEST) {
      if (this.guestPlayCount >= this.guestPlayLimit) {
        return;
      }
      this.guestPlayCount = this.guestPlayCount + 1;
    }
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
      this.cellSize = this.baseCellSize30;
      this.pieceSize = this.basePieceSize30;
      this.scaleValue = 1; // 重置缩放
      this.pinchValue = 1;
      this.offsetX = 0; // 重置偏移
      this.offsetY = 0;
      this.panOffsetX = 0;
      this.panOffsetY = 0;
      this.gameState = new GameState(CONFIG_30X30);
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
    }

    this.syncState();
  }

  private handleHuaweiLogin(): void {
    hilog.info(0x0000, 'GameLogin', 'handleHuaweiLogin called');
    
    // 使用 Game Service Kit 进行华为账号联合登录
    const uiContext = this.getUIContext();
    if (!uiContext) {
      hilog.error(0x0000, 'GameLogin', 'uiContext is null');
      return;
    }
    const abilityContext = uiContext.getHostContext() as common.UIAbilityContext;

    const loginRequest: gamePlayer.UnionLoginParam = {
      showLoginDialog: false, // 优先使用上次登录选择
      thirdAccountInfos: [] // 单机游戏传空数组
    };

    try {
      gamePlayer.unionLogin(abilityContext, loginRequest).then((result: gamePlayer.UnionLoginResult) => {
        hilog.info(0x0000, 'GameLogin', `Succeeded in logining: ${result?.accountName}`);

        // 登录成功后进行合规校验（实名 + 防沉迷）
        const verifyRequest: gamePlayer.ThirdUserInfo = {
          thirdOpenId: '' // 单机游戏传空
        };
        gamePlayer.verifyLocalPlayer(abilityContext, verifyRequest).then(() => {
          hilog.info(0x0000, 'GameLogin', 'Succeeded in verifying local player.');
          // 校验通过后，切换为华为账号模式
          this.playerAccountName = result?.accountName ?? '';
          this.loginMode = this.LOGIN_MODE_HUAWEI;
        }).catch((error: BusinessError) => {
          hilog.error(0x0000, 'GameLogin', `Failed to verify. Code: ${error.code}, message: ${error.message}`);
        });
      }).catch((error: BusinessError) => {
        hilog.error(0x0000, 'GameLogin', `Failed to login. Code: ${error.code}, message: ${error.message}`);
      });
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, 'GameLogin', `Failed to login. Code: ${err.code}, message: ${err.message}`);
    }
  }

  private handleGuestLogin(): void {
    if (this.loginMode !== this.LOGIN_MODE_GUEST) {
      this.guestPlayCount = 1;
    }
    this.loginMode = this.LOGIN_MODE_GUEST;
  }

  build() {
    Column() {
      // 标题区域
      Text('五子棋')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.primary_text'))
        .margin({ top: 20, bottom: 10 })

      // 登录模式选择
      Row() {
        Button('华为账号快速开始')
          .fontSize(14)
          .fontColor($r('app.color.button_text'))
          .backgroundColor($r('app.color.button_primary'))
          .width(160)
          .height(36)
          .borderRadius(18)
          .onClick(() => this.handleHuaweiLogin())

        Button('游客模式（3局）')
          .fontSize(14)
          .fontColor(this.loginMode === this.LOGIN_MODE_GUEST ? $r('app.color.button_text') : $r('app.color.primary_text'))
          .backgroundColor(this.loginMode === this.LOGIN_MODE_GUEST ? $r('app.color.button_secondary') : '#E0E0E0')
          .width(140)
          .height(36)
          .borderRadius(18)
          .margin({ left: 12 })
          .onClick(() => this.handleGuestLogin())
      }
      .margin({ bottom: 10 })

      if (this.loginMode === this.LOGIN_MODE_HUAWEI) {
        Text(`当前玩家：${this.playerAccountName || '华为账号用户'}`)
          .fontSize(12)
          .fontColor($r('app.color.secondary_text'))
          .margin({ bottom: 4 })

        Text('快去找你的小伙伴一起玩吧')
          .fontSize(12)
          .fontColor($r('app.color.secondary_text'))
          .margin({ bottom: 8 })
      }

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
      .margin({ bottom: 10 })

      if (this.loginMode === this.LOGIN_MODE_GUEST) {
        Text(`游客模式：剩余${this.guestPlayLimit - this.guestPlayCount}局`)
          .fontSize(12)
          .fontColor($r('app.color.secondary_text'))
          .margin({ bottom: 6 })
      }

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
        .margin({ bottom: this.boardSize === 30 ? 5 : 15 })
      
      // 30×30棋盘缩放提示
      if (this.boardSize === 30) {
        Text(`双指缩放: ${(this.scaleValue * 100).toFixed(0)}% | 支持双指拖拽移动`)
          .fontSize(12)
          .fontColor($r('app.color.secondary_text'))
          .margin({ bottom: 10 })
      }

      // 棋盘区域
      if (this.boardSize === 30) {
        // 30×30棋盘：支持缩放和滚动
        Scroll() {
          Scroll() {
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
              .scale({ x: this.scaleValue, y: this.scaleValue })
              .translate({ x: this.offsetX, y: this.offsetY })
            }
            .gesture(
              // 双指缩放手势
              GestureGroup(GestureMode.Parallel,
                PinchGesture({ fingers: 2 })
                  .onActionStart((event: GestureEvent) => {
                    this.pinchValue = this.scaleValue;
                  })
                  .onActionUpdate((event: GestureEvent) => {
                    if (event && event.scale) {
                      let newScale = this.pinchValue * event.scale;
                      // 限制缩放范围
                      newScale = Math.max(this.minScale, Math.min(this.maxScale, newScale));
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
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Auto)
          .width('100%')
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .width('100%')
        .layoutWeight(1)
        .margin({ bottom: 15 })
      } else {
        // 15×15棋盘：保持原样
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
          .enabled(this.totalMoves > 0 && !(this.loginMode === this.LOGIN_MODE_GUEST && this.guestPlayCount >= this.guestPlayLimit))
          .opacity(this.totalMoves > 0 && !(this.loginMode === this.LOGIN_MODE_GUEST && this.guestPlayCount >= this.guestPlayLimit) ? 1 : 0.5)
          .onClick(() => this.handleRestart())
      }
      .margin({ bottom: this.boardSize === 30 ? 10 : 20 })

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
      .margin({ bottom: this.boardSize === 30 ? 10 : 15 })
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
