// 举报入口
import router from '@ohos.router';
import { createReport } from '../api/service';
import { toast, toastError, isEmpty } from '../utils';
import type { CreateReportPayload } from '../model';

@Entry
@Component
struct Report {
  @State targetType: string = 'demand';
  @State targetId: string = '';
  @State targetIdLocked: boolean = false;
  @State reason: string = '';
  @State submitting: boolean = false;

  aboutToAppear() {
    const p = router.getParams() as Record<string, string | number>;
    if (p && p.target_type) {
      this.targetType = String(p.target_type);
    }
    if (p && p.target_id !== undefined && p.target_id !== '') {
      this.targetId = String(p.target_id);
      this.targetIdLocked = true;
    }
  }

  async doSubmit() {
    if (isEmpty(this.targetId)) {
      toast('请填写举报对象ID');
      return;
    }
    if (isEmpty(this.reason.trim())) {
      toast('请填写举报理由');
      return;
    }
    this.submitting = true;
    try {
      const payload: CreateReportPayload = {
        target_type: this.targetType,
        target_id: Number(this.targetId),
        reason: this.reason.trim()
      };
      await createReport(payload);
      toast('举报已提交，平台将尽快处理');
      router.back();
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.submitting = false;
    }
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        Text('‹').fontSize(24).fontColor($r('app.color.text_primary'))
          .onClick(() => router.back())
        Text('举报').fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary')).margin({ left: 8 })
        Blank()
      }
      .width('100%').height(52).padding({ left: 16, right: 16 }).backgroundColor('#FFFFFF')

      Scroll() {
        Column({ space: 14 }) {
          // 举报对象类型
          Column({ space: 6 }) {
            Text('举报对象类型').fontSize(13).fontColor($r('app.color.text_secondary'))
              .alignSelf(ItemAlign.Start)
            Row({ space: 16 }) {
              Row({ space: 4 }) {
                Radio({ value: 'demand', group: 'target' })
                  .checked(this.targetType === 'demand')
                  .onChange((isChecked: boolean) => { if (isChecked) this.targetType = 'demand' })
                Text('需求').fontSize(14).fontColor($r('app.color.text_primary'))
              }
              Row({ space: 4 }) {
                Radio({ value: 'tutor', group: 'target' })
                  .checked(this.targetType === 'tutor')
                  .onChange((isChecked: boolean) => { if (isChecked) this.targetType = 'tutor' })
                Text('家教').fontSize(14).fontColor($r('app.color.text_primary'))
              }
              Row({ space: 4 }) {
                Radio({ value: 'message', group: 'target' })
                  .checked(this.targetType === 'message')
                  .onChange((isChecked: boolean) => { if (isChecked) this.targetType = 'message' })
                Text('消息').fontSize(14).fontColor($r('app.color.text_primary'))
              }
            }.width('100%')
          }.width('100%')

          // 对象ID
          Column({ space: 6 }) {
            Text('举报对象ID').fontSize(13).fontColor($r('app.color.text_secondary'))
              .alignSelf(ItemAlign.Start)
            TextInput({ text: this.targetId, placeholder: '请输入对象ID' })
              .type(InputType.Number)
              .height(44)
              .backgroundColor($r('app.color.app_bg'))
              .borderRadius(10)
              .enabled(!this.targetIdLocked)
              .onChange((v: string) => this.targetId = v)
          }.width('100%')

          // 举报理由
          Column({ space: 6 }) {
            Text('举报理由').fontSize(13).fontColor($r('app.color.text_secondary'))
              .alignSelf(ItemAlign.Start)
            TextArea({ text: this.reason, placeholder: '请详细描述举报理由...' })
              .height(120)
              .backgroundColor($r('app.color.app_bg'))
              .borderRadius(10)
              .onChange((v: string) => this.reason = v)
          }.width('100%')

          Button('提交举报')
            .width('100%').height(46)
            .backgroundColor($r('app.color.danger')).fontColor('#FFFFFF')
            .enabled(!this.submitting)
            .onClick(() => this.doSubmit())
        }
        .width('100%')
        .padding(16)
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg'))
  }
}
