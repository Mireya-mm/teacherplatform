import UIAbility from '@ohos.app.ability.UIAbility';
import type AbilityConstant from '@ohos.app.ability.AbilityConstant';
import type Want from '@ohos.app.ability.Want';
import window from '@ohos.window';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    console.info('[CampusTutor] EntryAbility onCreate');
  }

  onDestroy() {
    console.info('[CampusTutor] EntryAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    windowStage.loadContent('entryability/pages/Index', (err) => {
      if (err.code) {
        console.error(`[CampusTutor] loadContent failed: ${JSON.stringify(err)}`);
        return;
      }
      console.info('[CampusTutor] Index loaded');
    });
  }

  onWindowStageDestroy() {
    console.info('[CampusTutor] onWindowStageDestroy');
  }

  onForeground() {
    console.info('[CampusTutor] onForeground');
  }

  onBackground() {
    console.info('[CampusTutor] onBackground');
  }
}
