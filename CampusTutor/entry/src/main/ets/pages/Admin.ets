// 管理员后台 - 资质审核 / 需求管控 / 用户管理 / 举报
import router from '@ohos.router';
import { get } from '../api/http';
import { adminListPendingCerts, adminReviewCert, adminTakedownDemand, adminBanUser } from '../api/service';
import { getRole } from '../store';
import { toast, toastError, formatTime, maskPhone } from '../utils';
import { CERT_TYPE_LABEL, DEMAND_STATUS_LABEL } from '../model';
import type { Certification, Demand, UserInfo, Report } from '../model';
import { EmptyState } from '../components/EmptyState';

// Certification 无 tutor_nickname，扩展以兼容后端附带字段
interface CertItem extends Certification {
  tutor_nickname?: string;
}

@Entry
@Component
struct Admin {
  @State currentTab: number = 0;
  @State certs: CertItem[] = [];
  @State demands: Demand[] = [];
  @State users: UserInfo[] = [];
  @State reports: Report[] = [];
  @State loading: boolean = false;

  async aboutToAppear() {
    if (getRole() !== 'admin') {
      toast('仅管理员可访问');
      router.back();
      return;
    }
    await this.loadTab(0);
  }

  async loadTab(index: number) {
    this.currentTab = index;
    this.loading = true;
    try {
      if (index === 0) {
        this.certs = await adminListPendingCerts();
      } else if (index === 1) {
        this.demands = await get<Demand[]>('/api/admin/demands');
      } else if (index === 2) {
        this.users = await get<UserInfo[]>('/api/admin/users');
      } else if (index === 3) {
        this.reports = await get<Report[]>('/api/admin/reports');
      }
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.loading = false;
    }
  }

  async reviewCert(id: number, status: string) {
    try {
      await adminReviewCert(id, status);
      toast(status === 'approved' ? '已通过' : '已驳回');
      await this.loadTab(0);
    } catch (e) {
      toastError(e as Error);
    }
  }

  async takedown(id: number) {
    try {
      await adminTakedownDemand(id);
      toast('已下架');
      await this.loadTab(1);
    } catch (e) {
      toastError(e as Error);
    }
  }

  async banUser(id: number) {
    try {
      await adminBanUser(id);
      toast('已封禁');
      await this.loadTab(2);
    } catch (e) {
      toastError(e as Error);
    }
  }

  roleLabel(role: string): string {
    if (role === 'parent') return '家长';
    if (role === 'tutor') return '家教';
    return '管理员';
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(24).fontColor($r('app.color.text_primary'))
          .onClick(() => router.back())
        Text('管理后台').fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary')).margin({ left: 8 })
        Blank()
      }
      .width('100%').height(52).padding({ left: 16, right: 16 }).backgroundColor('#FFFFFF')

      Tabs({ barPosition: BarPosition.Start }) {
        TabContent() { this.CertTab() }.tabBar(this.TabBuilder('资质审核', '📄'))
        TabContent() { this.DemandTab() }.tabBar(this.TabBuilder('需求管控', '📋'))
        TabContent() { this.UserTab() }.tabBar(this.TabBuilder('用户管理', '👤'))
        TabContent() { this.ReportTab() }.tabBar(this.TabBuilder('举报', '⚠️'))
      }
      .onChange((index: number) => this.loadTab(index))
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg'))
  }

  @Builder
  TabBuilder(label: string, icon: string) {
    Column({ space: 4 }) {
      Text(icon).fontSize(18)
      Text(label).fontSize(12).fontColor($r('app.color.text_primary'))
    }.justifyContent(FlexAlign.Center).width('100%').padding({ top: 6, bottom: 6 })
  }

  @Builder
  LoadingOrEmpty(listLen: number, emptyText: string) {
    if (this.loading && listLen === 0) {
      Column() {
        Text('加载中...').fontSize(14).fontColor($r('app.color.text_secondary'))
      }.width('100%').padding(40).justifyContent(FlexAlign.Center)
    } else if (listLen === 0) {
      EmptyState({ text: emptyText })
    }
  }

  // ===== 资质审核 =====
  @Builder
  CertTab() {
    Column({ space: 10 }) {
      if (this.loading && this.certs.length === 0) {
        this.LoadingOrEmpty(this.certs.length, '暂无待审核资质')
      } else if (this.certs.length === 0) {
        EmptyState({ text: '暂无待审核资质' })
      } else {
        List({ space: 10 }) {
          ForEach(this.certs, (item: CertItem) => {
            ListItem() {
              Column({ space: 8 }) {
                Row() {
                  Text(item.tutor_nickname || `家教 #${item.tutor_id}`)
                    .fontSize(15).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
                    .layoutWeight(1)
                  Text(CERT_TYPE_LABEL[item.type])
                    .fontSize(12).fontColor($r('app.color.app_primary'))
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                    .borderRadius(10)
                    .backgroundColor($r('app.color.app_bg'))
                }.width('100%')
                Text(formatTime(item.created_at)).fontSize(11).fontColor($r('app.color.text_secondary'))
                Row({ space: 10 }) {
                  Button('通过')
                    .layoutWeight(1).height(36)
                    .backgroundColor($r('app.color.app_primary')).fontColor('#FFFFFF').fontSize(13)
                    .onClick(() => this.reviewCert(item.id, 'approved'))
                  Button('驳回')
                    .layoutWeight(1).height(36)
                    .backgroundColor($r('app.color.danger')).fontColor('#FFFFFF').fontSize(13)
                    .onClick(() => this.reviewCert(item.id, 'rejected'))
                }.width('100%')
              }
              .width('100%').padding(14).backgroundColor('#FFFFFF').borderRadius(12)
            }
          }, (item: CertItem) => item.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8 })
      }
    }.width('100%').height('100%').backgroundColor($r('app.color.app_bg'))
  }

  // ===== 需求管控 =====
  @Builder
  DemandTab() {
    Column({ space: 10 }) {
      if (this.loading && this.demands.length === 0) {
        this.LoadingOrEmpty(this.demands.length, '暂无需求')
      } else if (this.demands.length === 0) {
        EmptyState({ text: '暂无需求' })
      } else {
        List({ space: 10 }) {
          ForEach(this.demands, (item: Demand) => {
            ListItem() {
              Column({ space: 8 }) {
                Row() {
                  Text(`${item.subject || '-'} · ${item.grade || '-'}`)
                    .fontSize(15).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
                    .layoutWeight(1)
                  Text(DEMAND_STATUS_LABEL[item.status])
                    .fontSize(11).fontColor('#FFFFFF')
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                    .borderRadius(10)
                    .backgroundColor($r('app.color.app_accent'))
                }.width('100%')
                Text(formatTime(item.created_at)).fontSize(11).fontColor($r('app.color.text_secondary'))
                Button('下架')
                  .width('100%').height(36)
                  .backgroundColor($r('app.color.danger')).fontColor('#FFFFFF').fontSize(13)
                  .onClick(() => this.takedown(item.id))
              }
              .width('100%').padding(14).backgroundColor('#FFFFFF').borderRadius(12)
            }
          }, (item: Demand) => item.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8 })
      }
    }.width('100%').height('100%').backgroundColor($r('app.color.app_bg'))
  }

  // ===== 用户管理 =====
  @Builder
  UserTab() {
    Column({ space: 10 }) {
      if (this.loading && this.users.length === 0) {
        this.LoadingOrEmpty(this.users.length, '暂无用户')
      } else if (this.users.length === 0) {
        EmptyState({ text: '暂无用户' })
      } else {
        List({ space: 10 }) {
          ForEach(this.users, (item: UserInfo) => {
            ListItem() {
              Column({ space: 8 }) {
                Row() {
                  Text(item.nickname)
                    .fontSize(15).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
                    .layoutWeight(1)
                  Text(this.roleLabel(item.role))
                    .fontSize(11).fontColor($r('app.color.app_primary'))
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                    .borderRadius(10)
                    .backgroundColor($r('app.color.app_bg'))
                }.width('100%')
                Row({ space: 12 }) {
                  Text(maskPhone(item.phone)).fontSize(12).fontColor($r('app.color.text_secondary'))
                  Blank()
                  Text(item.status === 'normal' ? '正常' : '已封禁')
                    .fontSize(12)
                    .fontColor(item.status === 'normal' ? $r('app.color.text_primary') : $r('app.color.danger'))
                }.width('100%')
                if (item.status === 'normal') {
                  Button('封禁')
                    .width('100%').height(36)
                    .backgroundColor($r('app.color.danger')).fontColor('#FFFFFF').fontSize(13)
                    .onClick(() => this.banUser(item.id))
                }
              }
              .width('100%').padding(14).backgroundColor('#FFFFFF').borderRadius(12)
            }
          }, (item: UserInfo) => item.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8 })
      }
    }.width('100%').height('100%').backgroundColor($r('app.color.app_bg'))
  }

  // ===== 举报 =====
  @Builder
  ReportTab() {
    Column({ space: 10 }) {
      if (this.loading && this.reports.length === 0) {
        this.LoadingOrEmpty(this.reports.length, '暂无举报')
      } else if (this.reports.length === 0) {
        EmptyState({ text: '暂无举报' })
      } else {
        List({ space: 10 }) {
          ForEach(this.reports, (item: Report) => {
            ListItem() {
              Column({ space: 6 }) {
                Row() {
                  Text(`对象：${item.target_type} #${item.target_id}`)
                    .fontSize(14).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
                    .layoutWeight(1)
                  Text(item.status)
                    .fontSize(11).fontColor('#FFFFFF')
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                    .borderRadius(10)
                    .backgroundColor($r('app.color.app_accent'))
                }.width('100%')
                Text(`理由：${item.reason}`)
                  .fontSize(12).fontColor($r('app.color.text_secondary'))
                  .width('100%')
                Text(formatTime(item.created_at)).fontSize(11).fontColor($r('app.color.text_secondary'))
              }
              .width('100%').padding(14).backgroundColor('#FFFFFF').borderRadius(12)
            }
          }, (item: Report) => item.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8 })
      }
    }.width('100%').height('100%').backgroundColor($r('app.color.app_bg'))
  }
}
