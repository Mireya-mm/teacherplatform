// 首页 - 按身份动态分流 Tabs（家长端 / 家教端 / 管理员端）
import router from '@ohos.router';
import { getRole, getNickname, clearLoginInfo } from '../store';
import { toast } from '../utils';
import type { Role } from '../model';

@Entry
@Component
struct Home {
  @State role: Role | null = getRole();
  @State nickname: string = getNickname();

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      if (this.role === 'parent') {
        TabContent() {
          this.ParentOverview()
        }.tabBar(this.TabBuilder('首页', '🏠'))
        TabContent() {
          this.ParentDemands()
        }.tabBar(this.TabBuilder('我的需求', '📋'))
        TabContent() {
          this.ParentFindTutor()
        }.tabBar(this.TabBuilder('找家教', '🔍'))
        TabContent() {
          this.GoList('消息中心', '您与家教的双向沟通记录均会持久化留存，可用于纠纷溯源。', 'pages/ChatList')
        }.tabBar(this.TabBuilder('消息', '💬'))
        TabContent() {
          this.Mine()
        }.tabBar(this.TabBuilder('我的', '👤'))
      } else if (this.role === 'tutor') {
        TabContent() {
          this.TutorOverview()
        }.tabBar(this.TabBuilder('首页', '🏠'))
        TabContent() {
          this.GoList('浏览需求', '家长发布的辅导需求列表，按科目、价格筛选，向心仪需求投递简历。', 'pages/DemandList')
        }.tabBar(this.TabBuilder('浏览需求', '🗂️'))
        TabContent() {
          this.GoList('我的投递', '您已投递的意向记录，可查看家长处理状态。', 'pages/MyApplications')
        }.tabBar(this.TabBuilder('我的投递', '📤'))
        TabContent() {
          this.GoList('消息中心', '与家长的沟通记录均持久化留存。', 'pages/ChatList')
        }.tabBar(this.TabBuilder('消息', '💬'))
        TabContent() {
          this.Mine()
        }.tabBar(this.TabBuilder('我的', '👤'))
      } else {
        TabContent() {
          this.GoList('管理后台', '资质审核、需求管控、用户封禁、举报处理。', 'pages/Admin')
        }.tabBar(this.TabBuilder('管理', '🛡️'))
        TabContent() {
          this.Mine()
        }.tabBar(this.TabBuilder('我的', '👤'))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg'))
  }

  @Builder
  TabBuilder(label: string, icon: string) {
    Column({ space: 4 }) {
      Text(icon).fontSize(20)
      Text(label).fontSize(11).fontColor($r('app.color.text_secondary'))
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
  }

  @Builder
  ParentOverview() {
    Scroll() {
      Column({ space: 14 }) {
        Column({ space: 6 }) {
          Text(`您好，${this.nickname}`).fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
          Text('家长端 · 发布需求，等待家教投递').fontSize(13).fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ top: 24, left: 20, right: 20 })

        this.QuickCard('📝 立即发布家教需求', '描述年级、科目、价格区间与授课地点，平台将为您匹配家教。', '发布需求', () => router.pushUrl({ url: 'pages/PublishDemand' }))
        this.QuickCard('📋 查看我的需求', '管理已发布需求，查看投递候选人并接受/拒绝。', '我的需求', () => router.pushUrl({ url: 'pages/MyDemands' }))
        this.QuickCard('🔍 浏览家教', '按科目、价格区间、是否已认证筛选合适家教。', '找家教', () => router.pushUrl({ url: 'pages/TutorList' }))
        this.QuickCard('💬 与家教沟通', '联系方式将自动脱敏，初次试讲前会弹出安全须知。', '消息中心', () => router.pushUrl({ url: 'pages/ChatList' }))

        Text('💡 安全提示：手机号、详细地址在聊天界面默认脱敏，请谨慎交换联系方式。')
          .fontSize(12)
          .fontColor($r('app.color.app_accent'))
          .padding(14)
          .backgroundColor('#FFF7ED')
          .borderRadius(10)
          .margin({ left: 16, right: 16 })
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ParentDemands() {
    this.GoList('我的需求', '查看您发布的所有需求及候选人投递情况。', 'pages/MyDemands')
  }

  @Builder
  ParentFindTutor() {
    this.GoList('找家教', '按科目、价格区间、认证状态筛选家教，查看简历主页并主动发起沟通。', 'pages/TutorList')
  }

  @Builder
  TutorOverview() {
    Scroll() {
      Column({ space: 14 }) {
        Column({ space: 6 }) {
          Text(`您好，${this.nickname}`).fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
          Text('家教端 · 浏览需求，投递简历').fontSize(13).fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ top: 24, left: 20, right: 20 })

        this.QuickCard('🗂️ 浏览家教需求', '家长实时发布的需求列表，按科目、价格筛选。', '浏览需求', () => router.pushUrl({ url: 'pages/DemandList' }))
        this.QuickCard('📄 完善我的简历', '填写擅长学科、授课经验、期望单价，并上传资质证书。', '我的简历', () => router.pushUrl({ url: 'pages/TutorProfileEdit' }))
        this.QuickCard('📤 我的投递', '查看投递状态，家长接受后可发起沟通。', '我的投递', () => router.pushUrl({ url: 'pages/MyApplications' }))
        this.QuickCard('💬 消息中心', '与家长沟通，联系方式默认脱敏。', '消息中心', () => router.pushUrl({ url: 'pages/ChatList' }))

        Text('⚠️ 注意：未通过任何资质认证的家教无法投递意向，请先完成认证。')
          .fontSize(12)
          .fontColor($r('app.color.danger'))
          .padding(14)
          .backgroundColor('#FEF2F2')
          .borderRadius(10)
          .margin({ left: 16, right: 16 })
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  GoList(title: string, desc: string, url: string) {
    Column({ space: 16 }) {
      Column({ space: 6 }) {
        Text(title).fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        Text(desc).fontSize(13).fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ top: 60, left: 20, right: 20 })

      Button('进入')
        .width('60%')
        .height(44)
        .backgroundColor($r('app.color.app_primary'))
        .fontColor('#FFFFFF')
        .onClick(() => router.pushUrl({ url }))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  QuickCard(title: string, desc: string, btn: string, action: () => void) {
    Column({ space: 8 }) {
      Row() {
        Text(title).fontSize(16).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        Blank()
        Text('›').fontSize(24).fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      Text(desc).fontSize(12).fontColor($r('app.color.text_secondary'))
      Button(btn)
        .width('100%')
        .height(38)
        .backgroundColor($r('app.color.app_primary'))
        .fontColor('#FFFFFF')
        .fontSize(14)
        .onClick(action)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 16, right: 16 })
  }

  @Builder
  Mine() {
    Column({ space: 16 }) {
      Column({ space: 6 }) {
        Text(this.nickname).fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        Text(`身份：${this.role === 'parent' ? '家长' : this.role === 'tutor' ? '家教' : '管理员'}`)
          .fontSize(13).fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ top: 40, left: 20, right: 20 })

      Button('个人资料')
        .width('100%').height(46)
        .backgroundColor('#FFFFFF').fontColor($r('app.color.text_primary'))
        .onClick(() => router.pushUrl({ url: 'pages/Profile' }))
      Button('退出登录')
        .width('100%').height(46)
        .backgroundColor($r('app.color.danger')).fontColor('#FFFFFF')
        .onClick(async () => {
          await clearLoginInfo();
          toast('已退出登录');
          router.replaceUrl({ url: 'pages/Login' });
        })
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor($r('app.color.app_bg'))
  }
}
