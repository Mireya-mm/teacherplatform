// 启动分发页：冷启动自动登录并按 role 跳转
import router from '@ohos.router';
import type common from '@ohos.app.ability.common';
import { initStore, isLoggedIn } from '../../store';

@Entry
@Component
struct Index {
  async aboutToAppear() {
    const ctx = getContext(this) as common.UIAbilityContext;
    await initStore(ctx);
    if (isLoggedIn()) {
      router.replaceUrl({ url: 'pages/Home' });
    } else {
      router.replaceUrl({ url: 'pages/Login' });
    }
  }

  build() {
    Column({ space: 16 }) {
      Text('🎓')
        .fontSize(72)
      Text('师遇')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.app_primary'))
      Text('去中介 · 安全可信 · 智能匹配')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
  }
}
