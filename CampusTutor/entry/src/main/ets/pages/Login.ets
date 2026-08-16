// 身份选择页（演示模式：免注册免登录，选身份直接进主页）
import router from '@ohos.router';
import { enterAsDemo } from '../store';
import { toast } from '../utils';
import type { Role } from '../model';

@Entry
@Component
struct Login {
  @State selectedRole: Role | null = null;
  @State loading: boolean = false;

  async enter() {
    if (this.selectedRole === null) {
      toast('请选择身份');
      return;
    }
    this.loading = true;
    try {
      await enterAsDemo(this.selectedRole);
      router.replaceUrl({ url: 'pages/Home' });
    } finally {
      this.loading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 8 }) {
          Text('🎓').fontSize(64)
          Text('师遇')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.app_primary'))
          Text('家长与家教双向智能撮合平台')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
        }
        .margin({ top: 40, bottom: 24 })

        Text('请选择您的身份进入')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .alignSelf(ItemAlign.Start)

        Row({ space: 12 }) {
          this.RoleCard('parent', '家长', '👨‍👩‍👧', '发布需求找家教', '#3B82F6')
          this.RoleCard('tutor', '家教', '🎓', '投递简历接单', '#F97316')
        }
        .width('100%')

        Row({ space: 12 }) {
          this.RoleCard('admin', '管理员', '🛡️', '审核与管控', '#6366F1')
        }
        .width('100%')

        Button('进入应用')
          .width('100%')
          .height(48)
          .backgroundColor($r('app.color.app_primary'))
          .fontColor('#FFFFFF')
          .fontSize(16)
          .enabled(!this.loading && this.selectedRole !== null)
          .margin({ top: 12 })
          .onClick(() => this.enter())

        Text('演示模式：无需注册登录，直接选择身份体验')
          .fontSize(11)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 16 })
      }
      .width('100%')
      .padding(24)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  RoleCard(value: Role, label: string, icon: string, desc: string, color: string) {
    Column({ space: 8 }) {
      Text(icon).fontSize(40)
      Text(label).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
      Text(desc).fontSize(11).fontColor('#FFFFFFCC')
    }
    .layoutWeight(1)
    .height(120)
    .justifyContent(FlexAlign.Center)
    .borderRadius(14)
    .backgroundColor(color)
    .border({
      width: this.selectedRole === value ? 3 : 0,
      color: '#111827'
    })
    .opacity(this.selectedRole !== null && this.selectedRole !== value ? 0.5 : 1)
    .onClick(() => {
      this.selectedRole = value;
    })
  }
}
