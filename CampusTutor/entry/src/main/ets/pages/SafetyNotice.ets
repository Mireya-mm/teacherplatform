// 独立安全须知页（F10.2 全屏模态感）
import router from '@ohos.router';
import { ackSafety } from '../api/service';
import { toast, toastError } from '../utils';
import type { AckSafetyPayload } from '../model';

@Entry
@Component
struct SafetyNotice {
  @State checked: boolean = false;
  @State submitting: boolean = false;

  async doConfirm() {
    this.submitting = true;
    try {
      const payload: AckSafetyPayload = { ack_text: '已阅读并知悉线下授课安全须知' };
      await ackSafety(payload);
      toast('已确认');
      router.back();
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.submitting = false;
    }
  }

  build() {
    Column({ space: 16 }) {
      Text('线下授课安全须知')
        .fontSize(22).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        .margin({ top: 16 })

      Scroll() {
        Column({ space: 14 }) {
          this.NoticeItem('1', '初次见面优先选择公共场所', '建议在图书馆、咖啡店等公共场所进行试讲，避免独自上门。')
          this.NoticeItem('2', '不建议独自上门', '如确需上门授课，建议家长全程陪同，确保环境安全。')
          this.NoticeItem('3', '谨慎交换联系方式', '初步沟通达成意向后，再考虑交换手机号、微信等联系方式。')
          this.NoticeItem('4', '留存沟通记录', '本平台所有聊天记录均会持久化保存，出现纠纷可溯源。')
          this.NoticeItem('5', '理性评估资质', '平台仅做证件图片初审，请家长自主甄别家教真实能力。')
        }
        .padding(16)
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .backgroundColor($r('app.color.app_bg'))

      Row({ space: 8 }) {
        Checkbox()
          .select(this.checked)
          .onChange((v: boolean) => { this.checked = v })
        Text('已阅读并知悉上述安全须知')
          .fontSize(14).fontColor($r('app.color.text_primary'))
          .onClick(() => { this.checked = !this.checked })
      }
      .padding({ left: 16, right: 16 })
      .width('100%')

      Button('确认')
        .width('90%').height(46)
        .backgroundColor(this.checked ? $r('app.color.app_primary') : $r('app.color.divider'))
        .fontColor('#FFFFFF')
        .enabled(this.checked && !this.submitting)
        .margin({ bottom: 16 })
        .onClick(() => this.doConfirm())
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg'))
  }

  @Builder
  NoticeItem(num: string, title: string, desc: string) {
    Row({ space: 10 }) {
      Text(num)
        .width(24).height(24).borderRadius(12)
        .backgroundColor($r('app.color.app_primary'))
        .fontColor('#FFFFFF').fontSize(13).fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
      Column({ space: 4 }) {
        Text(title).fontSize(15).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
        Text(desc).fontSize(13).fontColor($r('app.color.text_secondary'))
      }.alignItems(HorizontalAlign.Start)
    }
    .alignItems(VerticalAlign.Top)
    .width('100%')
  }
}
