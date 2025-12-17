/**
 * 五子棋游戏逻辑单元测试
 * 测试核心逻辑模块的各项功能
 */

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { GameLogic } from '../main/ets/model/GameLogic';
import { GameState } from '../main/ets/model/GameState';
import { PieceType, GameStatus, DEFAULT_CONFIG, CONFIG_30X30 } from '../main/ets/model/GameTypes';

export default function gameLogicTest() {
  describe('GameLogic Tests', () => {
    let logic: GameLogic;
    let board: PieceType[][];

    beforeEach(() => {
      logic = new GameLogic(DEFAULT_CONFIG);
      // 初始化15x15空棋盘
      board = [];
      for (let i = 0; i < 15; i++) {
        const row: PieceType[] = [];
        for (let j = 0; j < 15; j++) {
          row.push(PieceType.EMPTY);
        }
        board.push(row);
      }
    });

    it('should validate position correctly', 0, () => {
      expect(logic.isValidPosition(0, 0)).assertTrue();
      expect(logic.isValidPosition(14, 14)).assertTrue();
      expect(logic.isValidPosition(7, 7)).assertTrue();
      expect(logic.isValidPosition(-1, 0)).assertFalse();
      expect(logic.isValidPosition(0, -1)).assertFalse();
      expect(logic.isValidPosition(15, 0)).assertFalse();
      expect(logic.isValidPosition(0, 15)).assertFalse();
    });

    it('should check if can place piece', 0, () => {
      expect(logic.canPlacePiece(board, 7, 7)).assertTrue();
      board[7][7] = PieceType.BLACK;
      expect(logic.canPlacePiece(board, 7, 7)).assertFalse();
    });

    it('should detect horizontal win', 0, () => {
      // 水平五子连珠
      for (let i = 0; i < 5; i++) {
        board[7][i] = PieceType.BLACK;
      }
      expect(logic.checkWin(board, 7, 2)).assertTrue();
    });

    it('should detect vertical win', 0, () => {
      // 垂直五子连珠
      for (let i = 0; i < 5; i++) {
        board[i][7] = PieceType.WHITE;
      }
      expect(logic.checkWin(board, 2, 7)).assertTrue();
    });

    it('should detect diagonal win (top-left to bottom-right)', 0, () => {
      // 对角线五子连珠（左上到右下）
      for (let i = 0; i < 5; i++) {
        board[i][i] = PieceType.BLACK;
      }
      expect(logic.checkWin(board, 2, 2)).assertTrue();
    });

    it('should detect diagonal win (top-right to bottom-left)', 0, () => {
      // 对角线五子连珠（右上到左下）
      for (let i = 0; i < 5; i++) {
        board[i][4 - i] = PieceType.WHITE;
      }
      expect(logic.checkWin(board, 2, 2)).assertTrue();
    });

    it('should not detect win with only 4 pieces', 0, () => {
      // 只有4个连珠不算获胜
      for (let i = 0; i < 4; i++) {
        board[7][i] = PieceType.BLACK;
      }
      expect(logic.checkWin(board, 7, 2)).assertFalse();
    });

    it('should detect board full', 0, () => {
      expect(logic.isBoardFull(board)).assertFalse();
      
      // 填满棋盘
      for (let i = 0; i < 15; i++) {
        for (let j = 0; j < 15; j++) {
          board[i][j] = (i + j) % 2 === 0 ? PieceType.BLACK : PieceType.WHITE;
        }
      }
      expect(logic.isBoardFull(board)).assertTrue();
    });

    it('should get opponent piece type', 0, () => {
      expect(logic.getOpponent(PieceType.BLACK)).assertEqual(PieceType.WHITE);
      expect(logic.getOpponent(PieceType.WHITE)).assertEqual(PieceType.BLACK);
    });

    it('should determine game status correctly', 0, () => {
      // 游戏进行中
      board[7][7] = PieceType.BLACK;
      expect(logic.determineGameStatus(board, 7, 7, PieceType.BLACK)).assertEqual(GameStatus.PLAYING);

      // 黑方获胜
      for (let i = 0; i < 5; i++) {
        board[0][i] = PieceType.BLACK;
      }
      expect(logic.determineGameStatus(board, 0, 2, PieceType.BLACK)).assertEqual(GameStatus.BLACK_WIN);

      // 白方获胜
      const board2: PieceType[][] = [];
      for (let i = 0; i < 15; i++) {
        const row: PieceType[] = [];
        for (let j = 0; j < 15; j++) {
          row.push(PieceType.EMPTY);
        }
        board2.push(row);
      }
      for (let i = 0; i < 5; i++) {
        board2[i][0] = PieceType.WHITE;
      }
      expect(logic.determineGameStatus(board2, 2, 0, PieceType.WHITE)).assertEqual(GameStatus.WHITE_WIN);
    });
  });

  describe('GameState Tests', () => {
    let gameState: GameState;

    beforeEach(() => {
      gameState = new GameState(DEFAULT_CONFIG);
    });

    it('should initialize with empty board', 0, () => {
      const board = gameState.getBoard();
      expect(board.length).assertEqual(15);
      expect(board[0].length).assertEqual(15);
      
      for (let i = 0; i < 15; i++) {
        for (let j = 0; j < 15; j++) {
          expect(board[i][j]).assertEqual(PieceType.EMPTY);
        }
      }
    });

    it('should start with black player', 0, () => {
      expect(gameState.getCurrentPlayer()).assertEqual(PieceType.BLACK);
    });

    it('should place piece and switch player', 0, () => {
      expect(gameState.placePiece(7, 7)).assertTrue();
      expect(gameState.getPiece(7, 7)).assertEqual(PieceType.BLACK);
      expect(gameState.getCurrentPlayer()).assertEqual(PieceType.WHITE);
      expect(gameState.getTotalMoves()).assertEqual(1);
    });

    it('should not place piece on occupied position', 0, () => {
      gameState.placePiece(7, 7);
      expect(gameState.placePiece(7, 7)).assertFalse();
    });

    it('should undo move correctly', 0, () => {
      gameState.placePiece(7, 7);
      gameState.placePiece(8, 8);
      expect(gameState.getTotalMoves()).assertEqual(2);
      
      expect(gameState.undo()).assertTrue();
      expect(gameState.getTotalMoves()).assertEqual(1);
      expect(gameState.getPiece(8, 8)).assertEqual(PieceType.EMPTY);
      expect(gameState.getCurrentPlayer()).assertEqual(PieceType.WHITE);
    });

    it('should reset game correctly', 0, () => {
      gameState.placePiece(7, 7);
      gameState.placePiece(8, 8);
      gameState.reset();
      
      expect(gameState.getTotalMoves()).assertEqual(0);
      expect(gameState.getCurrentPlayer()).assertEqual(PieceType.BLACK);
      expect(gameState.getGameStatus()).assertEqual(GameStatus.PLAYING);
      expect(gameState.getPiece(7, 7)).assertEqual(PieceType.EMPTY);
    });

    it('should detect game over', 0, () => {
      expect(gameState.isGameOver()).assertFalse();
      
      // 创建获胜局面
      for (let i = 0; i < 5; i++) {
        if (i < 4) {
          gameState.placePiece(0, i); // 黑
          gameState.placePiece(1, i); // 白
        } else {
          gameState.placePiece(0, i); // 黑获胜
        }
      }
      
      expect(gameState.isGameOver()).assertTrue();
    });

    it('should get last move correctly', 0, () => {
      expect(gameState.getLastMove()).assertNull();
      
      gameState.placePiece(7, 7);
      const lastMove = gameState.getLastMove();
      expect(lastMove).assertNotNull();
      if (lastMove) {
        expect(lastMove.row).assertEqual(7);
        expect(lastMove.col).assertEqual(7);
        expect(lastMove.piece).assertEqual(PieceType.BLACK);
      }
    });
  });

  describe('30x30 Board Tests', () => {
    let gameState30: GameState;
    let logic30: GameLogic;

    beforeEach(() => {
      gameState30 = new GameState(CONFIG_30X30);
      logic30 = new GameLogic(CONFIG_30X30);
    });

    it('should initialize 30x30 board correctly', 0, () => {
      const board = gameState30.getBoard();
      expect(board.length).assertEqual(30);
      expect(board[0].length).assertEqual(30);
      expect(gameState30.getBoardSize()).assertEqual(30);
    });

    it('should validate positions for 30x30 board', 0, () => {
      expect(logic30.isValidPosition(0, 0)).assertTrue();
      expect(logic30.isValidPosition(29, 29)).assertTrue();
      expect(logic30.isValidPosition(15, 15)).assertTrue();
      expect(logic30.isValidPosition(30, 0)).assertFalse();
      expect(logic30.isValidPosition(0, 30)).assertFalse();
    });

    it('should place pieces on 30x30 board', 0, () => {
      expect(gameState30.placePiece(15, 15)).assertTrue();
      expect(gameState30.getPiece(15, 15)).assertEqual(PieceType.BLACK);
      expect(gameState30.placePiece(20, 20)).assertTrue();
      expect(gameState30.getPiece(20, 20)).assertEqual(PieceType.WHITE);
    });

    it('should detect win on 30x30 board', 0, () => {
      const board: PieceType[][] = [];
      for (let i = 0; i < 30; i++) {
        const row: PieceType[] = [];
        for (let j = 0; j < 30; j++) {
          row.push(PieceType.EMPTY);
        }
        board.push(row);
      }
      
      // 在中心位置创建五子连珠
      for (let i = 0; i < 5; i++) {
        board[15][10 + i] = PieceType.BLACK;
      }
      
      expect(logic30.checkWin(board, 15, 12)).assertTrue();
    });
  });

  describe('Edge Cases Tests', () => {
    let gameState: GameState;
    let logic: GameLogic;

    beforeEach(() => {
      gameState = new GameState(DEFAULT_CONFIG);
      logic = new GameLogic(DEFAULT_CONFIG);
    });

    it('should handle boundary positions', 0, () => {
      // 测试边界位置
      expect(gameState.placePiece(0, 0)).assertTrue();
      expect(gameState.placePiece(14, 14)).assertTrue();
      expect(gameState.placePiece(0, 14)).assertTrue();
      expect(gameState.placePiece(14, 0)).assertTrue();
    });

    it('should handle win at board edges', 0, () => {
      const board: PieceType[][] = [];
      for (let i = 0; i < 15; i++) {
        const row: PieceType[] = [];
        for (let j = 0; j < 15; j++) {
          row.push(PieceType.EMPTY);
        }
        board.push(row);
      }
      
      // 顶部边缘获胜
      for (let i = 0; i < 5; i++) {
        board[0][i] = PieceType.BLACK;
      }
      expect(logic.checkWin(board, 0, 2)).assertTrue();
      
      // 底部边缘获胜
      for (let i = 0; i < 5; i++) {
        board[14][i] = PieceType.WHITE;
      }
      expect(logic.checkWin(board, 14, 2)).assertTrue();
    });

    it('should handle multiple undo operations', 0, () => {
      gameState.placePiece(7, 7);
      gameState.placePiece(8, 8);
      gameState.placePiece(9, 9);
      
      expect(gameState.undo()).assertTrue();
      expect(gameState.undo()).assertTrue();
      expect(gameState.undo()).assertTrue();
      expect(gameState.undo()).assertFalse(); // 没有更多可悔棋
      
      expect(gameState.getTotalMoves()).assertEqual(0);
    });
  });
}
