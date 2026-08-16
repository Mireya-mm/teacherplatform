// 家长 - 查看候选人
import router from '@ohos.router';
import { listCandidates, patchApplication, getDemand } from '../api/service';
import { toast, toastError, formatPrice, formatTime } from '../utils';
import { APPLICATION_STATUS_LABEL } from '../model';
import type { Application, Demand, ApplicationStatus } from '../model';
import { CertBadge } from '../components/CertBadge';
import { EmptyState } from '../components/EmptyState';

@Entry
@Component
struct MyCandidates {
  @State demandId: number = 0;
  @State list: Application[] = [];
  @State demand: Demand | null = null;
  @State loading: boolean = false;

  async aboutToAppear() {
    const p = router.getParams() as Record<string, number>;
    this.demandId = p.demandId;
    await this.load();
  }

  async load() {
    this.loading = true;
    try {
      this.list = await listCandidates(this.demandId);
      this.demand = await getDemand(this.demandId);
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.loading = false;
    }
  }

  async handleApp(item: Application, status: string) {
    try {
      await patchApplication(item.id, status);
      toast(status === 'accepted' ? '已接受' : '已拒绝');
      await this.load();
    } catch (e) {
      toastError(e as Error);
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
      Text('投递候选人')
        .fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })

      // 需求概要
      if (this.demand) {
        Column({ space: 6 }) {
          Row() {
            Text(this.demand.subject).fontSize(15).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
            Text(' · ' + this.demand.grade).fontSize(12).fontColor($r('app.color.text_secondary'))
            Blank()
            Text(formatPrice(this.demand.price_min, this.demand.price_max))
              .fontSize(13).fontColor($r('app.color.app_accent'))
          }.width('100%')
          Text('授课时间：' + (this.demand.schedule || '面议'))
            .fontSize(12).fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .padding(14)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ left: 16, right: 16 })
        .alignItems(HorizontalAlign.Start)
      }

      if (this.loading && this.list.length === 0) {
        Column() {
          Text('加载中...').fontSize(14).fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .padding(40)
        .justifyContent(FlexAlign.Center)
      } else if (this.list.length === 0) {
        EmptyState({ text: '暂无候选人投递' })
      } else {
        List({ space: 10 }) {
          ForEach(this.list, (item: Application) => {
            ListItem() {
              this.CandidateCard(item)
            }
          }, (item: Application) => item.id.toString())
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
  CandidateCard(item: Application) {
    Column({ space: 8 }) {
      Row() {
        Text(item.tutor_nickname || '家教')
          .fontSize(15).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        Blank()
        if (item.tutor_certified) {
          CertBadge()
        } else {
          Text('未认证').fontSize(12).fontColor($r('app.color.text_secondary'))
        }
      }.width('100%')

      Row({ space: 4 }) {
        Text('学校').fontSize(12).fontColor($r('app.color.text_secondary'))
        Text(item.tutor_school || '未填写')
          .fontSize(12).fontColor($r('app.color.text_primary'))
      }.width('100%')

      Row({ space: 4 }) {
        Text('投递时间').fontSize(12).fontColor($r('app.color.text_secondary'))
        Text(formatTime(item.created_at))
          .fontSize(12).fontColor($r('app.color.text_secondary'))
      }.width('100%')

      if (item.status === 'pending') {
        Row({ space: 12 }) {
          Button('接受')
            .layoutWeight(1).height(38)
            .backgroundColor($r('app.color.app_primary')).fontColor('#FFFFFF')
            .fontSize(13)
            .onClick(() => this.handleApp(item, 'accepted'))
          Button('拒绝')
            .layoutWeight(1).height(38)
            .backgroundColor($r('app.color.divider')).fontColor($r('app.color.text_primary'))
            .fontSize(13)
            .onClick(() => this.handleApp(item, 'rejected'))
        }.width('100%')
      } else {
        Row() {
          Blank()
          Text(APPLICATION_STATUS_LABEL[item.status])
            .fontSize(11).fontColor('#FFFFFF')
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .borderRadius(10)
            .backgroundColor(this.statusColor(item.status))
        }.width('100%')
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }
}
