// 家教投递列表
import router from '@ohos.router';
import { get } from '../api/http';
import { getRole } from '../store';
import { toast, toastError, formatTime } from '../utils';
import { APPLICATION_STATUS_LABEL } from '../model';
import type { Application, ApplicationStatus } from '../model';
import { EmptyState } from '../components/EmptyState';

// 后端可能附带需求概要字段；若无则回退显示「需求 #id」
interface MyApplicationItem extends Application {
  demand_subject?: string;
  demand_grade?: string;
  parent_nickname?: string;
}

@Entry
@Component
struct MyApplications {
  @State list: MyApplicationItem[] = [];
  @State loading: boolean = false;

  async aboutToAppear() {
    if (getRole() !== 'tutor') {
      toast('仅家教可访问');
      router.back();
      return;
    }
    await this.load();
  }

  async load() {
    this.loading = true;
    try {
      this.list = await get<MyApplicationItem[]>('/api/applications/mine');
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.loading = false;
    }
  }

  statusColor(status: ApplicationStatus): Resource {
    if (status === 'accepted') {
      return $r('app.color.app_primary');
    }
    if (status === 'rejected') {
      return $r('app.color.danger');
    }
    return $r('app.color.app_accent');
  }

  build() {
    Column({ space: 12 }) {
      Text('我的投递')
        .fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })

      if (this.loading && this.list.length === 0) {
        Column() {
          Text('加载中...').fontSize(14).fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .padding(40)
        .justifyContent(FlexAlign.Center)
      } else if (this.list.length === 0) {
        EmptyState({ text: '暂无投递记录' })
      } else {
        List({ space: 10 }) {
          ForEach(this.list, (item: MyApplicationItem) => {
            ListItem() {
              this.AppCard(item)
            }
          }, (item: MyApplicationItem) => item.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg'))
  }

  @Builder
  AppCard(item: MyApplicationItem) {
    Column({ space: 8 }) {
      Row() {
        Text(this.DemandTitle(item))
          .fontSize(16).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text(APPLICATION_STATUS_LABEL[item.status])
          .fontSize(11).fontColor('#FFFFFF')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(10)
          .backgroundColor(this.statusColor(item.status))
      }.width('100%')

      Row({ space: 4 }) {
        Text('家长').fontSize(12).fontColor($r('app.color.text_secondary'))
        Text(item.parent_nickname || '家长')
          .fontSize(12).fontColor($r('app.color.text_primary'))
      }.width('100%')

      Row({ space: 4 }) {
        Text('投递时间').fontSize(12).fontColor($r('app.color.text_secondary'))
        Text(formatTime(item.created_at))
          .fontSize(12).fontColor($r('app.color.text_secondary'))
      }.width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onClick(() => router.pushUrl({ url: 'pages/DemandDetail', params: { demandId: item.demand_id } }))
  }

  DemandTitle(item: MyApplicationItem): string {
    const subject = item.demand_subject || '';
    const grade = item.demand_grade || '';
    if (subject || grade) {
      return `${subject}${grade ? ' · ' + grade : ''}`;
    }
    return `需求 #${item.demand_id}`;
  }
}
