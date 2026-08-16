// 评价页
import router from '@ohos.router';
import { createReview } from '../api/service';
import { toast, toastError, isEmpty } from '../utils';
import type { CreateReviewPayload } from '../model';

@Entry
@Component
struct Evaluation {
  @State score: number = 0;
  @State comment: string = '';
  @State submitting: boolean = false;
  private orderId: number = 0;
  private toUser: number = 0;

  aboutToAppear() {
    const p = router.getParams() as Record<string, string | number>;
    this.orderId = Number(p.orderId);
    this.toUser = Number(p.toUser);
  }

  async doSubmit() {
    if (this.score < 1) {
      toast('请选择评分');
      return;
    }
    if (isEmpty(this.comment.trim())) {
      toast('请填写评语');
      return;
    }
    this.submitting = true;
    try {
      const payload: CreateReviewPayload = {
        order_id: this.orderId,
        to_user: this.toUser,
        score: this.score,
        comment: this.comment.trim()
      };
      await createReview(payload);
      toast('评价成功');
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
        Text('评价').fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary')).margin({ left: 8 })
        Blank()
      }
      .width('100%').height(52).padding({ left: 16, right: 16 }).backgroundColor('#FFFFFF')

      Scroll() {
        Column({ space: 16 }) {
          // 评分
          Column({ space: 8 }) {
            Text('评分').fontSize(13).fontColor($r('app.color.text_secondary'))
              .alignSelf(ItemAlign.Start)
            Row({ space: 12 }) {
              ForEach([1, 2, 3, 4, 5], (n: number) => {
                Text('★')
                  .fontSize(40)
                  .fontColor(n <= this.score ? $r('app.color.gold_badge') : $r('app.color.divider'))
                  .onClick(() => { this.score = n })
              }, (n: number) => n.toString())
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            Text(this.score > 0 ? `${this.score} 星` : '请选择 1-5 星')
              .fontSize(12).fontColor($r('app.color.text_secondary'))
          }.width('100%')

          // 评语
          Column({ space: 6 }) {
            Text('评语').fontSize(13).fontColor($r('app.color.text_secondary'))
              .alignSelf(ItemAlign.Start)
            TextArea({ text: this.comment, placeholder: '请填写对本次授课的评价...' })
              .height(120)
              .backgroundColor($r('app.color.app_bg'))
              .borderRadius(10)
              .onChange((v: string) => this.comment = v)
          }.width('100%')

          Button('提交评价')
            .width('100%').height(46)
            .backgroundColor($r('app.color.app_primary')).fontColor('#FFFFFF')
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
