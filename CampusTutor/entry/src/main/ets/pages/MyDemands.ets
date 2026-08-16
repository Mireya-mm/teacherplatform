// 家长 - 我的需求
import router from '@ohos.router';
import { get } from '../api/http';
import { getRole } from '../store';
import { toast, toastError, formatPrice } from '../utils';
import { DEMAND_STATUS_LABEL } from '../model';
import type { Demand, DemandStatus } from '../model';
import { EmptyState } from '../components/EmptyState';

@Entry
@Component
struct MyDemands {
  @State list: Demand[] = [];
  @State loading: boolean = false;

  async aboutToAppear() {
    if (getRole() !== 'parent') {
      toast('仅家长可查看我的需求');
      router.back();
      return;
    }
    await this.load();
  }

  async load() {
    this.loading = true;
    try {
      this.list = await get<Demand[]>('/api/demands/mine');
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.loading = false;
    }
  }

  statusColor(status: DemandStatus): Resource {
    if (status === 'open') {
      return $r('app.color.app_accent');
    }
    if (status === 'matched') {
      return $r('app.color.gold_badge');
    }
    return $r('app.color.text_secondary');
  }

  build() {
    Column({ space: 12 }) {
      Text('我的需求')
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
        EmptyState({ text: '您还没有发布需求' })
      } else {
        List({ space: 10 }) {
          ForEach(this.list, (item: Demand) => {
            ListItem() {
              this.DemandCard(item)
            }
          }, (item: Demand) => item.id.toString())
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
  DemandCard(item: Demand) {
    Column({ space: 8 }) {
      Row() {
        Text(item.subject).fontSize(16).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        Text(' · ' + item.grade).fontSize(13).fontColor($r('app.color.text_secondary'))
        Blank()
        Text(DEMAND_STATUS_LABEL[item.status])
          .fontSize(11)
          .fontColor('#FFFFFF')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(10)
          .backgroundColor(this.statusColor(item.status))
      }.width('100%')

      Row({ space: 4 }) {
        Text('💰').fontSize(12)
        Text(formatPrice(item.price_min, item.price_max))
          .fontSize(13).fontColor($r('app.color.app_accent'))
      }.width('100%')

      Row() {
        Text('点击查看投递候选人 ›')
          .fontSize(12).fontColor($r('app.color.app_primary'))
        Blank()
        Text(item.mode === 'online' ? '线上' : '线下')
          .fontSize(12).fontColor($r('app.color.text_secondary'))
      }.width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onClick(() => router.pushUrl({ url: 'pages/MyCandidates', params: { demandId: item.id } }))
  }
}
