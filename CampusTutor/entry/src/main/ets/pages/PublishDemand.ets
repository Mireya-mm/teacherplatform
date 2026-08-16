// 发布需求
import router from '@ohos.router';
import { createDemand, aiNormalizeDemand } from '../api/service';
import { getRole } from '../store';
import { toast, toastError, isEmpty } from '../utils';
import type { Demand, TeachMode } from '../model';

@Entry
@Component
struct PublishDemand {
  @State grade: string = '';
  @State subject: string = '';
  @State priceMin: string = '';
  @State priceMax: string = '';
  @State location: string = '';
  @State mode: TeachMode = 'offline';
  @State schedule: string = '';
  @State description: string = '';
  @State aiText: string = '';
  @State aiLoading: boolean = false;
  @State submitting: boolean = false;

  async aboutToAppear() {
    if (getRole() !== 'parent') {
      toast('仅家长可发布需求');
      router.back();
    }
  }

  async doAiNormalize() {
    if (isEmpty(this.aiText)) {
      toast('请输入零散描述');
      return;
    }
    this.aiLoading = true;
    try {
      const res: Partial<Demand> = await aiNormalizeDemand(this.aiText);
      if (res.grade !== undefined) {
        this.grade = res.grade;
      }
      if (res.subject !== undefined) {
        this.subject = res.subject;
      }
      if (res.price_min !== undefined) {
        this.priceMin = `${res.price_min}`;
      }
      if (res.price_max !== undefined) {
        this.priceMax = `${res.price_max}`;
      }
      if (res.location !== undefined) {
        this.location = res.location;
      }
      if (res.mode !== undefined) {
        this.mode = res.mode;
      }
      if (res.schedule !== undefined) {
        this.schedule = res.schedule;
      }
      if (res.description !== undefined) {
        this.description = res.description;
      }
      toast('AI 已填充表单');
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.aiLoading = false;
    }
  }

  async submit() {
    if (isEmpty(this.grade) || isEmpty(this.subject)) {
      toast('请填写年级和科目');
      return;
    }
    if (isEmpty(this.priceMin) || isEmpty(this.priceMax)) {
      toast('请填写期望课时费区间');
      return;
    }
    if (isEmpty(this.location)) {
      toast('请填写授课地点');
      return;
    }
    if (isEmpty(this.schedule)) {
      toast('请填写授课时间');
      return;
    }
    const payload: Partial<Demand> = {
      grade: this.grade,
      subject: this.subject,
      price_min: Number(this.priceMin),
      price_max: Number(this.priceMax),
      location: this.location,
      mode: this.mode,
      schedule: this.schedule,
      description: this.description
    };
    this.submitting = true;
    try {
      await createDemand(payload);
      toast('发布成功');
      router.back();
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.submitting = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Text('发布需求')
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
          .width('100%')
          .padding({ left: 16, right: 16, top: 16 })

        // AI 智能规整
        Column({ space: 10 }) {
          Row() {
            Text('AI 智能规整').fontSize(14).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
            Blank()
            Text('可选').fontSize(11).fontColor($r('app.color.text_secondary'))
          }.width('100%')
          TextArea({ text: this.aiText, placeholder: '输入零散描述，例如：孩子初二数学跟不上，周末想找大学生辅导，希望每小时 80 到 120，在海淀区上门' })
            .height(96)
            .backgroundColor($r('app.color.app_bg'))
            .borderRadius(8)
            .fontSize(13)
            .onChange((v: string) => { this.aiText = v; })
          Button('AI 智能规整')
            .width('100%').height(40)
            .backgroundColor($r('app.color.app_accent')).fontColor('#FFFFFF')
            .fontSize(14)
            .enabled(!this.aiLoading)
            .onClick(() => this.doAiNormalize())
        }
        .width('100%')
        .padding(14)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ left: 16, right: 16 })
        .alignItems(HorizontalAlign.Start)

        // 表单
        Column({ space: 12 }) {
          this.FormInput('年级', '如 初二 / 高一', (v: string) => { this.grade = v; })
          this.FormInput('科目', '如 数学', (v: string) => { this.subject = v; })

          Column({ space: 6 }) {
            Text('期望课时费（元/课时）').fontSize(13).fontColor($r('app.color.text_secondary'))
            Row({ space: 8 }) {
              TextInput({ text: this.priceMin, placeholder: '最低' })
                .type(InputType.Number)
                .layoutWeight(1)
                .height(44)
                .backgroundColor($r('app.color.app_bg'))
                .borderRadius(8)
                .onChange((v: string) => { this.priceMin = v; })
              Text('-').fontSize(14).fontColor($r('app.color.text_secondary'))
              TextInput({ text: this.priceMax, placeholder: '最高' })
                .type(InputType.Number)
                .layoutWeight(1)
                .height(44)
                .backgroundColor($r('app.color.app_bg'))
                .borderRadius(8)
                .onChange((v: string) => { this.priceMax = v; })
            }.width('100%')
          }.width('100%').alignItems(HorizontalAlign.Start)

          this.FormInput('授课地点', '如 北京市海淀区中关村大街1号', (v: string) => { this.location = v; })

          Column({ space: 6 }) {
            Text('授课模式').fontSize(13).fontColor($r('app.color.text_secondary'))
            Row({ space: 24 }) {
              Row({ space: 6 }) {
                Radio({ value: 'offline', group: 'mode' })
                  .checked(this.mode === 'offline')
                  .onChange((v: boolean) => { if (v) { this.mode = 'offline'; } })
                Text('线下').fontSize(13).fontColor($r('app.color.text_primary'))
              }
              Row({ space: 6 }) {
                Radio({ value: 'online', group: 'mode' })
                  .checked(this.mode === 'online')
                  .onChange((v: boolean) => { if (v) { this.mode = 'online'; } })
                Text('线上').fontSize(13).fontColor($r('app.color.text_primary'))
              }
            }.width('100%')
          }.width('100%').alignItems(HorizontalAlign.Start)

          this.FormInput('授课时间', '如 周六上午 9:00-11:00', (v: string) => { this.schedule = v; })

          Column({ space: 6 }) {
            Text('详细描述').fontSize(13).fontColor($r('app.color.text_secondary'))
            TextArea({ text: this.description, placeholder: '补充孩子的学习情况、目标、对家教的要求等' })
              .height(96)
              .backgroundColor($r('app.color.app_bg'))
              .borderRadius(8)
              .fontSize(13)
              .onChange((v: string) => { this.description = v; })
          }.width('100%').alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding(14)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ left: 16, right: 16 })
        .alignItems(HorizontalAlign.Start)

        Button('发布需求')
          .width('100%').height(48)
          .backgroundColor($r('app.color.app_primary')).fontColor('#FFFFFF')
          .fontSize(16)
          .enabled(!this.submitting)
          .margin({ left: 16, right: 16, top: 4 })
          .onClick(() => this.submit())
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ bottom: 28 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg'))
  }

  @Builder
  FormInput(label: string, placeholder: string, onChange: (v: string) => void) {
    Column({ space: 6 }) {
      Text(label).fontSize(13).fontColor($r('app.color.text_secondary'))
      TextInput({ placeholder: placeholder })
        .height(44)
        .backgroundColor($r('app.color.app_bg'))
        .borderRadius(8)
        .onChange(onChange)
    }.width('100%').alignItems(HorizontalAlign.Start)
  }
}
