// 编辑家教简历
import router from '@ohos.router';
import { getTutorProfile, updateTutorProfile, aiParseResume } from '../api/service';
import { getRole } from '../store';
import { toast, toastError, isEmpty } from '../utils';
import type { TutorProfile } from '../model';

@Entry
@Component
struct TutorProfileEdit {
  @State subjects: string = '';
  @State experience: string = '';
  @State priceMin: string = '';
  @State priceMax: string = '';
  @State region: string = '';
  @State intro: string = '';
  @State resumeText: string = '';
  @State loading: boolean = false;
  @State saving: boolean = false;
  @State parsing: boolean = false;

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
      const p = await getTutorProfile();
      this.subjects = p.subjects || '';
      this.experience = p.experience || '';
      this.priceMin = p.price_min ? p.price_min.toString() : '';
      this.priceMax = p.price_max ? p.price_max.toString() : '';
      this.region = p.region || '';
      this.intro = p.intro || '';
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.loading = false;
    }
  }

  async aiParse() {
    if (isEmpty(this.resumeText)) {
      toast('请输入简历自述');
      return;
    }
    this.parsing = true;
    try {
      const res = await aiParseResume(this.resumeText);
      if (res.subjects) {
        this.subjects = res.subjects;
      }
      if (res.tags) {
        if (isEmpty(this.intro)) {
          this.intro = res.tags;
        } else {
          this.intro = this.intro + '\n' + res.tags;
        }
      }
      toast('AI 已解析');
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.parsing = false;
    }
  }

  async save() {
    if (this.saving) {
      return;
    }
    this.saving = true;
    try {
      const payload: Partial<TutorProfile> = {
        subjects: this.subjects,
        experience: this.experience,
        price_min: isEmpty(this.priceMin) ? 0 : Number(this.priceMin),
        price_max: isEmpty(this.priceMax) ? 0 : Number(this.priceMax),
        region: this.region,
        intro: this.intro
      };
      await updateTutorProfile(payload);
      toast('保存成功');
      router.back();
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.saving = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Text('编辑简历')
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
          .width('100%')
          .padding({ left: 16, right: 16, top: 16 })

        // AI 解析区
        Column({ space: 8 }) {
          Text('AI 解析简历').fontSize(14).fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
          TextArea({ text: this.resumeText, placeholder: '粘贴你的简历自述，AI 将自动提取擅长科目与标签' })
            .height(100)
            .backgroundColor($r('app.color.app_bg'))
            .borderRadius(8)
            .onChange((v: string) => { this.resumeText = v; })
          Button(this.parsing ? '解析中...' : 'AI 解析')
            .width('100%').height(40)
            .backgroundColor($r('app.color.app_accent')).fontColor('#FFFFFF')
            .enabled(!this.parsing)
            .onClick(() => this.aiParse())
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ left: 16, right: 16 })
        .alignItems(HorizontalAlign.Start)

        // 表单
        if (this.loading) {
          Column() {
            Text('加载中...').fontSize(14).fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .padding(40)
          .justifyContent(FlexAlign.Center)
        } else {
          Column({ space: 12 }) {
            this.Field('擅长科目', '如 数学,英语', (v) => { this.subjects = v; })
            this.Field('授课经验', '如 3年家教经验', (v) => { this.experience = v; })

            Text('期望单价（元/课时）').fontSize(13).fontColor($r('app.color.text_secondary'))
              .width('100%')
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

            this.Field('可授课区域', '如 北京市海淀区', (v) => { this.region = v; })

            Text('自我介绍').fontSize(13).fontColor($r('app.color.text_secondary'))
              .width('100%')
            TextArea({ text: this.intro, placeholder: '介绍一下你的教学风格、特点等' })
              .height(100)
              .backgroundColor($r('app.color.app_bg'))
              .borderRadius(8)
              .onChange((v: string) => { this.intro = v; })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ left: 16, right: 16 })
          .alignItems(HorizontalAlign.Start)
        }

        // 操作按钮
        Button(this.saving ? '保存中...' : '保存简历')
          .width('90%').height(46)
          .backgroundColor($r('app.color.app_primary')).fontColor('#FFFFFF')
          .enabled(!this.saving && !this.loading)
          .margin({ top: 4 })
          .onClick(() => this.save())

        Button('去上传认证')
          .width('90%').height(46)
          .backgroundColor($r('app.color.divider')).fontColor($r('app.color.text_primary'))
          .margin({ bottom: 24 })
          .onClick(() => router.pushUrl({ url: 'pages/Certification' }))
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg'))
  }

  @Builder
  Field(label: string, placeholder: string, onChange: (v: string) => void) {
    Column({ space: 6 }) {
      Text(label).fontSize(13).fontColor($r('app.color.text_secondary')).width('100%')
      TextInput({ placeholder: placeholder })
        .height(42)
        .backgroundColor($r('app.color.app_bg'))
        .borderRadius(8)
        .onChange(onChange)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
