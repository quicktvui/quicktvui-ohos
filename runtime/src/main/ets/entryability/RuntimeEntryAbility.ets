import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { JSON } from '@kit.ArkTS';
import {
  LogUtils
} from 'hippy';
import { EsData } from '../eskit/EsData';
import { App } from '../App';

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
    console.log('++++++++++++++ launch', JSON.stringify(want), JSON.stringify(launchParam), onNewWant)

    App.instance.launchParams = want.parameters

    if (onNewWant) {
      let esData = EsData.tryParse(want.parameters)
      if (esData) {
        App.instance.nav?.pushDestination({name: 'AppView', param: esData }, {launchMode:LaunchMode.STANDARD})
      }
    }

  }

  onDestroy(): void {
    LogUtils.i(this.TAG, `Ability onDestroy`)
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    LogUtils.i(this.TAG, `Ability onWindowStageCreate`)

    // windowStage.loadContent('pages/Main', (err) => {
    windowStage.loadContent('eskit/ui/AppView', (err) => {
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
