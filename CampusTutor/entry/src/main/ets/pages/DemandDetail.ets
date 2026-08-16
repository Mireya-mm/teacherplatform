// 需求详情
import router from '@ohos.router';
import { getDemand, applyDemand, getCertifications } from '../api/service';
import { getRole, getUserId } from '../store';
import { toast, toastError, formatPrice, maskLocation } from '../utils';
import { DEMAND_STATUS_LABEL } from '../model';
import type { Demand, DemandStatus } from '../model';
import { SafetyNoticeDialog } from '../components/SafetyNoticeDialog';

@Entry
@Component
struct DemandDetail {
  @State demandId: number = 0;
  @State demand: Demand | null = null;
  @State loading: boolean = false;
  @State certified: boolean = false;
  @State applying: boolean = false;
  controller: CustomDialogController = new CustomDialogController({
    builder: SafetyNoticeDialog({
      onConfirmed: () => { this.doApply(); }
    })
  });

  async aboutToAppear() {
    const p = router.getParams() as Record<string, number>;
    this.demandId = p.demandId;
    await this.load();
    if (getRole() === 'tutor') {
      await this.checkCert();
    }
  }

  async load() {
    this.loading = true;
    try {
      this.demand = await getDemand(this.demandId);
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.loading = false;
    }
  }

  async checkCert() {
    try {
      const certs = await getCertifications();
      this.certified = certs.some((c) => c.status === 'approved');
    } catch (e) {
      this.certified = false;
    }
  }

  isOwner(): boolean {
    return getRole() === 'parent' && getUserId() === (this.demand ? this.demand.parent_id : 0);
  }

  isTutor(): boolean {
    return getRole() === 'tutor';
  }

  async doApply() {
    this.applying = true;
    try {
      await applyDemand(this.demandId);
      toast('投递成功');
      this.demand = await getDemand(this.demandId);
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.applying = false;
    }
  }

  onApplyClick() {
    if (!this.certified) {
      toast('请先完成资质认证');
      return;
    }
    if (this.demand && this.demand.applied) {
      return;
    }
    this.controller.open();
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
    Scroll() {
      Column({ space: 12 }) {
        Row() {
          Text('需求详情').fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
          Blank()
          Text('举报')
            .fontSize(13)
            .fontColor($r('app.color.danger'))
            .onClick(() => router.pushUrl({
              url: 'pages/Report',
              params: { target_type: 'demand', target_id: this.demandId }
            }))
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })

        if (this.loading) {
          Column() {
            Text('加载中...').fontSize(14).fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .padding(40)
          .justifyContent(FlexAlign.Center)
        } else if (this.demand) {
          this.DetailBody(this.demand as Demand)
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg'))
  }

  @Builder
  DetailBody(d: Demand) {
    Column({ space: 8 }) {
      Row() {
        Text(d.subject).fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        Text(' · ' + d.grade).fontSize(14).fontColor($r('app.color.text_secondary'))
        Blank()
        Text(DEMAND_STATUS_LABEL[d.status])
          .fontSize(11)
          .fontColor('#FFFFFF')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(10)
          .backgroundColor(this.statusColor(d.status))
      }.width('100%')
      Text('发布者：' + (d.parent_nickname || '家长'))
        .fontSize(12).fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 16, right: 16 })
    .alignItems(HorizontalAlign.Start)

    Column({ space: 12 }) {
      this.InfoRow('价格区间', formatPrice(d.price_min, d.price_max))
      this.InfoRow('授课模式', d.mode === 'online' ? '线上' : '线下')
      this.InfoRow('授课地点', this.isOwner() ? (d.location || '未填写') : (maskLocation(d.location) || '未填写'))
      this.InfoRow('授课时间', d.schedule || '面议')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 16, right: 16 })

    Column({ space: 8 }) {
      Text('详细描述').fontSize(14).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
      Text(d.description || '暂无描述')
        .fontSize(13).fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 16, right: 16 })
    .alignItems(HorizontalAlign.Start)

    this.ActionButtons(d)
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label).fontSize(13).fontColor($r('app.color.text_secondary'))
      Blank()
      Text(value).fontSize(13).fontColor($r('app.color.text_primary'))
    }.width('100%')
  }

  @Builder
  ActionButtons(d: Demand) {
    if (this.isOwner()) {
      Button('查看候选人')
        .width('100%').height(46)
        .backgroundColor($r('app.color.app_primary')).fontColor('#FFFFFF')
        .margin({ left: 16, right: 16, top: 4 })
        .onClick(() => router.pushUrl({ url: 'pages/MyCandidates', params: { demandId: this.demandId } }))
    } else if (this.isTutor()) {
      if (d.applied) {
        Button('已投递')
          .width('100%').height(46)
          .backgroundColor($r('app.color.divider')).fontColor($r('app.color.text_secondary'))
          .enabled(false)
          .margin({ left: 16, right: 16, top: 4 })
      } else if (!this.certified) {
        Button('投递意向')
          .width('100%').height(46)
          .backgroundColor($r('app.color.divider')).fontColor($r('app.color.text_secondary'))
          .margin({ left: 16, right: 16, top: 4 })
          .onClick(() => toast('请先完成资质认证'))
      } else {
        Button('投递意向')
          .width('100%').height(46)
          .backgroundColor($r('app.color.app_primary')).fontColor('#FFFFFF')
          .enabled(!this.applying)
          .margin({ left: 16, right: 16, top: 4 })
          .onClick(() => this.onApplyClick())
      }
    }
  }
}
