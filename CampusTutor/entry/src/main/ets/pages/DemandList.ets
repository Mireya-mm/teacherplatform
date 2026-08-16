// 需求列表 + 筛选
import router from '@ohos.router';
import { listDemands } from '../api/service';
import { toast, toastError, formatPrice, maskLocation, isEmpty } from '../utils';
import { DEMAND_STATUS_LABEL } from '../model';
import type { Demand, DemandStatus, ListDemandsParams } from '../model';
import { EmptyState } from '../components/EmptyState';

@Entry
@Component
struct DemandList {
  @State list: Demand[] = [];
  @State loading: boolean = false;
  @State subject: string = '';
  @State priceMin: string = '';
  @State priceMax: string = '';
  @State certifiedOnly: boolean = false;
  @State sort: string = '';

  async aboutToAppear() {
    await this.load();
  }

  async load() {
    this.loading = true;
    try {
      const params: ListDemandsParams = {};
      if (!isEmpty(this.subject)) {
        params.subject = this.subject;
      }
      if (!isEmpty(this.priceMin)) {
        params.price_min = Number(this.priceMin);
      }
      if (!isEmpty(this.priceMax)) {
        params.price_max = Number(this.priceMax);
      }
      if (this.certifiedOnly) {
        params.certified = true;
      }
      if (this.sort) {
        params.sort = this.sort;
      }
      this.list = await listDemands(params);
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.loading = false;
    }
  }

  resetFilter() {
    this.subject = '';
    this.priceMin = '';
    this.priceMax = '';
    this.certifiedOnly = false;
    this.sort = '';
    this.load();
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
      Row() {
        Text('浏览需求').fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        Blank()
        Text('家长与家教均可查看').fontSize(11).fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16 })

      // 筛选区
      Column({ space: 10 }) {
        TextInput({ text: this.subject, placeholder: '科目，如 数学 / 英语' })
          .height(42)
          .backgroundColor($r('app.color.app_bg'))
          .borderRadius(8)
          .onChange((v: string) => { this.subject = v; })

        Row({ space: 8 }) {
          TextInput({ text: this.priceMin, placeholder: '最低价' })
            .type(InputType.Number)
            .layoutWeight(1)
            .height(42)
            .backgroundColor($r('app.color.app_bg'))
            .borderRadius(8)
            .onChange((v: string) => { this.priceMin = v; })
          Text('-').fontSize(14).fontColor($r('app.color.text_secondary'))
          TextInput({ text: this.priceMax, placeholder: '最高价' })
            .type(InputType.Number)
            .layoutWeight(1)
            .height(42)
            .backgroundColor($r('app.color.app_bg'))
            .borderRadius(8)
            .onChange((v: string) => { this.priceMax = v; })
        }.width('100%')

        Row() {
          Row({ space: 6 }) {
            Checkbox()
              .select(this.certifiedOnly)
              .onChange((v: boolean) => { this.certifiedOnly = v; })
            Text('仅看已认证').fontSize(13).fontColor($r('app.color.text_primary'))
          }
          Blank()
          Row({ space: 10 }) {
            Text('排序').fontSize(13).fontColor($r('app.color.text_secondary'))
            Text('按时间')
              .fontSize(13)
              .fontColor(this.sort === 'time' ? '#FFFFFF' : $r('app.color.text_primary'))
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .borderRadius(8)
              .backgroundColor(this.sort === 'time' ? $r('app.color.app_primary') : $r('app.color.app_bg'))
              .onClick(() => { this.sort = this.sort === 'time' ? '' : 'time'; })
            Text('按价格')
              .fontSize(13)
              .fontColor(this.sort === 'price' ? '#FFFFFF' : $r('app.color.text_primary'))
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .borderRadius(8)
              .backgroundColor(this.sort === 'price' ? $r('app.color.app_primary') : $r('app.color.app_bg'))
              .onClick(() => { this.sort = this.sort === 'price' ? '' : 'price'; })
          }
        }.width('100%')

        Row({ space: 12 }) {
          Button('搜索')
            .layoutWeight(1)
            .height(40)
            .backgroundColor($r('app.color.app_primary'))
            .fontColor('#FFFFFF')
            .enabled(!this.loading)
            .onClick(() => this.load())
          Button('重置')
            .layoutWeight(1)
            .height(40)
            .backgroundColor($r('app.color.divider'))
            .fontColor($r('app.color.text_primary'))
            .onClick(() => this.resetFilter())
        }.width('100%')
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ left: 16, right: 16 })

      // 列表
      if (this.loading && this.list.length === 0) {
        Column() {
          Text('加载中...').fontSize(14).fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .padding(40)
        .justifyContent(FlexAlign.Center)
      } else if (this.list.length === 0) {
        EmptyState({ text: '暂无需求' })
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

      Row({ space: 18 }) {
        Row({ space: 4 }) {
          Text('💰').fontSize(12)
          Text(formatPrice(item.price_min, item.price_max))
            .fontSize(13).fontColor($r('app.color.app_accent'))
        }
        Row({ space: 4 }) {
          Text('📱').fontSize(12)
          Text(item.mode === 'online' ? '线上' : '线下')
            .fontSize(13).fontColor($r('app.color.text_primary'))
        }
      }.width('100%')

      Row({ space: 4 }) {
        Text('地点').fontSize(12).fontColor($r('app.color.text_secondary'))
        Text(maskLocation(item.location) || '未填写')
          .fontSize(12).fontColor($r('app.color.text_secondary'))
      }.width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onClick(() => router.pushUrl({ url: 'pages/DemandDetail', params: { demandId: item.id } }))
  }
}
