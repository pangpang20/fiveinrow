import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { gamePlayer } from '@kit.GameServiceKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0x0000;

// Game Service 初始化状态（全局共享）
export class GameServiceState {
  static isInitialized: boolean = false;
  static initError: BusinessError | null = null;
}

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');

      // Game Service Kit 初始化（单点接入要求）
      hilog.info(DOMAIN, 'GameService', 'Starting Game Service initialization...');
      try {
        gamePlayer.init(this.context, () => {
          GameServiceState.isInitialized = true;
          GameServiceState.initError = null;
          hilog.info(DOMAIN, 'GameService', '✓ Game Service initialized successfully.');
          hilog.info(DOMAIN, 'GameService', '可以进行联合登录操作');
        });
      } catch (error) {
        let errInit = error as BusinessError;
        GameServiceState.isInitialized = false;
        GameServiceState.initError = errInit;
        hilog.error(DOMAIN, 'GameService', `✗ Failed to init Game Service. Code: ${errInit.code}, message: ${errInit.message}`);
        hilog.error(DOMAIN, 'GameService', '请检查：');
        hilog.error(DOMAIN, 'GameService', '1. AGC 控制台是否已开通 Game Service');
        hilog.error(DOMAIN, 'GameService', '2. module.json5 中 client_id/app_id 是否正确配置');
        hilog.error(DOMAIN, 'GameService', '3. 是否使用手动签名（自动签名不支持游戏服务）');
      }
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}