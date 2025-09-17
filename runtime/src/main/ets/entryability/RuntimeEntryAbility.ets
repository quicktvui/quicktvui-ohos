import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { url } from '@kit.ArkTS';
import libHippy from 'libhippy.so'
import {
  LogUtils
} from 'hippy';

export default class RuntimeEntryAbility extends UIAbility {
  public readonly TAG: string = 'RuntimeEntryAbility'
  //
  private runtimeNavPathStack: NavPathStack = new NavPathStack()

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    LogUtils.i(this.TAG, `Ability onCreate`)

    AppStorage.setOrCreate("RuntimeNavPathStack", this.runtimeNavPathStack)
    AppStorage.setOrCreate("libHippy", libHippy)
    AppStorage.setOrCreate("abilityContext", this.context)

    LogUtils.i(this.TAG, `onCreate: want: uri: ${want?.uri}  launchParam: ${launchParam}`)
    //
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
    let uri = want?.uri;
    if (uri) {
      let urlObject = url.URL.parseURL(want?.uri);
      let pkg = urlObject.params.get('pkg');
      let from = urlObject.params.get('from');
      LogUtils.i(this.TAG, `onNewWant: want: uri: pkg: ${pkg} from: ${from}`)
      // let action = urlObject.params.get('action');
      // 例如，当action为showall时，展示所有的节目。
      // if (action === "showall") {
      //   // ...
      // }
    }
    //TODO
    // this.runtimeNavPathStack?.pushPathByName('Animation', null, false);
  }

  onDestroy(): void {
    LogUtils.i(this.TAG, `Ability onDestroy`)
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    LogUtils.i(this.TAG, `Ability onWindowStageCreate`)

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
