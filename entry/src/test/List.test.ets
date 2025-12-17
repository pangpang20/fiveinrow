import localUnitTest from './LocalUnit.test';
import gameLogicTest from './GameLogic.test';

export default function testsuite() {
  localUnitTest();
  gameLogicTest();
}