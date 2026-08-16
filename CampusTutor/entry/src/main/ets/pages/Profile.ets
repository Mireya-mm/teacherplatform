// 个人资料页
import router from '@ohos.router';
import { getMe } from '../api/service';
import { getRole, clearLoginInfo } from '../store';
import { toast, toastError, maskPhone } from '../utils';
import type { UserInfo } from '../model';

@Entry
@Component
struct Profile {
  @State user: UserInfo | null = null;
  @State loading: boolean = false;
  @State role: string = getRole() || '';

  async aboutToAppear() {
    await this.load();
  }

  async load() {
    this.loading = true;
    try {
      this.user = await getMe();
      this.role = this.user.role;
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.loading = false;
    }
  }

  roleLabel(role: string): string {
    if (role === 'parent') return '家长';
    if (role === 'tutor') return '家教';
    return '管理员';
  }

  async doLogout() {
    await clearLoginInfo();
    toast('已退出登录');
    router.replaceUrl({ url: 'pages/Login' });
  }

  build() {
    Column({ space: 14 }) {
      Row() {
        Text('‹').fontSize(24).fontColor($r('app.color.text_primary'))
          .onClick(() => router.back())
        Text('个人资料').fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary')).margin({ left: 8 })
        Blank()
      }
      .width('100%').height(52).padding({ left: 16, right: 16 }).backgroundColor('#FFFFFF')

      if (this.loading && this.user === null) {
        Column() {
          Text('加载中...').fontSize(14).fontColor($r('app.color.text_secondary'))
        }.width('100%').padding(40).justifyContent(FlexAlign.Center)
      } else if (this.user !== null) {
        Scroll() {
          Column({ space: 14 }) {
            // 头像昵称区
            Column({ space: 6 }) {
              Text('👤').fontSize(48)
              Text(this.user.nickname)
                .fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
              Text(this.roleLabel(this.role))
                .fontSize(13).fontColor('#FFFFFF')
                .padding({ left: 10, right: 10, top: 3, bottom: 3 })
                .borderRadius(10)
                .backgroundColor($r('app.color.app_primary'))
            }
            .width('100%')
            .padding({ top: 24, bottom: 24 })
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .alignItems(HorizontalAlign.Center)

            // 信息行
            Column({ space: 0 }) {
              this.InfoRow('手机号', maskPhone(this.user.phone))
              this.InfoRow('学校', this.user.school || '-')
              this.InfoRow('状态', this.user.status === 'normal' ? '正常' : '已封禁')
            }
            .width('100%')
            .backgroundColor('#FFFFFF')
            .borderRadius(12)

            // 身份相关按钮
            if (this.role === 'tutor') {
              Button('编辑简历')
                .width('100%').height(46)
                .backgroundColor('#FFFFFF').fontColor($r('app.color.text_primary'))
                .onClick(() => router.pushUrl({ url: 'pages/TutorProfileEdit' }))
              Button('资质认证')
                .width('100%').height(46)
                .backgroundColor('#FFFFFF').fontColor($r('app.color.text_primary'))
                .onClick(() => router.pushUrl({ url: 'pages/Certification' }))
            }

            if (this.role === 'admin') {
              Button('进入管理后台')
                .width('100%').height(46)
                .backgroundColor($r('app.color.app_primary')).fontColor('#FFFFFF')
                .onClick(() => router.pushUrl({ url: 'pages/Admin' }))
            }

            Button('退出登录')
              .width('100%').height(46)
              .backgroundColor($r('app.color.danger')).fontColor('#FFFFFF')
              .onClick(() => this.doLogout())
          }
          .width('100%')
          .padding(16)
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg'))
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label).fontSize(14).fontColor($r('app.color.text_secondary'))
      Blank()
      Text(value).fontSize(14).fontColor($r('app.color.text_primary'))
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
  }
}
