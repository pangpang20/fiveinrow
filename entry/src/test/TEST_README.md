# 五子棋单元测试

## 测试覆盖范围

本项目包含完整的单元测试，覆盖以下模块：

### 1. GameLogic（游戏逻辑）测试
- ✅ 位置验证（边界检查）
- ✅ 落子规则验证
- ✅ 水平方向获胜检测
- ✅ 垂直方向获胜检测
- ✅ 对角线获胜检测（左上到右下）
- ✅ 对角线获胜检测（右上到左下）
- ✅ 四子不获胜验证
- ✅ 棋盘已满检测
- ✅ 对手棋子类型获取
- ✅ 游戏状态判定

### 2. GameState（游戏状态）测试
- ✅ 棋盘初始化
- ✅ 初始玩家设置
- ✅ 落子与玩家切换
- ✅ 禁止重复落子
- ✅ 悔棋功能
- ✅ 游戏重置
- ✅ 游戏结束检测
- ✅ 最后落子记录

### 3. 30×30棋盘测试
- ✅ 30×30棋盘初始化
- ✅ 30×30位置验证
- ✅ 30×30落子功能
- ✅ 30×30获胜检测

### 4. 边界情况测试
- ✅ 边界位置落子
- ✅ 边缘获胜情况
- ✅ 多次悔棋操作

## 运行测试

### 使用DevEco Studio
1. 打开项目
2. 在左侧导航栏找到 `entry/src/test/`
3. 右键点击 `GameLogic.test.ets` 或 `List.test.ets`
4. 选择 "Run 'GameLogic.test.ets'" 或 "Run All Tests"

### 使用命令行
```bash
# 在项目根目录执行
hvigorw test
```

## 测试结果示例

```
GameLogic Tests
  ✓ should validate position correctly
  ✓ should check if can place piece
  ✓ should detect horizontal win
  ✓ should detect vertical win
  ✓ should detect diagonal win (top-left to bottom-right)
  ✓ should detect diagonal win (top-right to bottom-left)
  ✓ should not detect win with only 4 pieces
  ✓ should detect board full
  ✓ should get opponent piece type
  ✓ should determine game status correctly

GameState Tests
  ✓ should initialize with empty board
  ✓ should start with black player
  ✓ should place piece and switch player
  ✓ should not place piece on occupied position
  ✓ should undo move correctly
  ✓ should reset game correctly
  ✓ should detect game over
  ✓ should get last move correctly

30x30 Board Tests
  ✓ should initialize 30x30 board correctly
  ✓ should validate positions for 30x30 board
  ✓ should place pieces on 30x30 board
  ✓ should detect win on 30x30 board

Edge Cases Tests
  ✓ should handle boundary positions
  ✓ should handle win at board edges
  ✓ should handle multiple undo operations

Total: 25 tests passed
```

## 测试文件结构

```
entry/src/test/
├── List.test.ets           # 测试套件入口
├── LocalUnit.test.ets      # 示例测试
└── GameLogic.test.ets      # 游戏逻辑单元测试
```

## 关于棋子形状

✅ **棋子已确认为圆形**

在UI实现中，棋子使用了 `Circle` 组件进行渲染：

```typescript
Circle({ width: this.pieceSize, height: this.pieceSize })
  .fill(this.boardData[row][col] === PieceType.BLACK ?
    $r('app.color.black_piece') : $r('app.color.white_piece'))
  .shadow({
    radius: 3,
    color: '#66000000',
    offsetX: 1,
    offsetY: 2
  })
```

特性：
- 完美的圆形棋子
- 黑白两色区分
- 带有阴影效果，增强立体感
- 大小随棋盘尺寸自适应（15×15: 20px，30×30: 10px）
