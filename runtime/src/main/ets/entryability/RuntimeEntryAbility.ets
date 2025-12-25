import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { JSON } from '@kit.ArkTS';
import {
  LogUtils
} from 'hippy';
import { EsData } from '../eskit/EsData';
import { App } from '../App';
import { LaunchConfigParser } from '../config/LaunchConfigParser';
import { ConfigResolver } from '../config/ConfigResolver';

export default class RuntimeEntryAbility extends UIAbility {
  public readonly TAG: string = 'RuntimeEntryAbility'

  //
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    LogUtils.i(this.TAG, `Ability onCreate`)
    LogUtils.i(this.TAG, `onCreate: want: uri: ${want?.uri}  launchParam: ${launchParam}`)

    App.instance.context = this.context
    App.instance.nav = new NavPathStack()

    this.launch(want, launchParam, false)
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    LogUtils.i(this.TAG,
      `onNewWant: want: uri: ${want.uri}  launchParam: ${JSON.stringify(launchParam)}`)
    this.launch(want, launchParam, true)
  }

  /**
   *
   * @param want
   * @param launchParam
   * @param onNewWant
   */
  private launch(want: Want, launchParam: AbilityConstant.LaunchParam, onNewWant: boolean) {
    LogUtils.d(this.TAG, `launch want: ` + JSON.stringify(want)
      + ' launchParam: ' + JSON.stringify(launchParam)
      + ' onNewWant: ' + JSON.stringify(onNewWant)
    )
    //--------------------------------------------------------------------
    const launchConfig = LaunchConfigParser.parse(
      want.parameters as Record<string, Object>
    )
    const runtimeConfig = ConfigResolver.resolve(launchConfig)
    LogUtils.e(this.TAG, `Ability runtimeConfig :` + JSON.stringify(runtimeConfig))

    App.instance.runtimeConfig = runtimeConfig
    //--------------------------------------------------------------------
    if (onNewWant) {
      let esData = EsData.tryParse(want.parameters)
      if (esData) {
        //
        App.instance.nav?.pushDestination(
          { name: runtimeConfig.appEntry, param: runtimeConfig.params },
          { launchMode: LaunchMode.STANDARD })
      }
    }
  }

  onDestroy(): void {
    LogUtils.i(this.TAG, `Ability onDestroy`)
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    LogUtils.i(this.TAG, `Ability onWindowStageCreate`)

    // windowStage.loadContent('pages/Main', (err) => {
    windowStage.loadContent('pages/Main', (err) => {
      if (err.code) {
        LogUtils.i(this.TAG, `Failed to load the content. Cause: ${JSON.stringify(err) ?? ''}`)
        return;
      }
      LogUtils.i(this.TAG, `Succeeded in loading the content.`)
    });
  }

  onWindowStageDestroy(): void {
    LogUtils.i(this.TAG, `Ability onWindowStageDestroy`)
  }

  onForeground(): void {
    LogUtils.i(this.TAG, `Ability onForeground`)
  }

  onBackground(): void {
    LogUtils.i(this.TAG, `Ability onBackground`)
  }
}
