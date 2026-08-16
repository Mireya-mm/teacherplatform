// 家教列表 + 筛选
import router from '@ohos.router';
import { get } from '../api/http';
import { toast, toastError, formatPrice, maskLocation, isEmpty } from '../utils';
import type { TutorProfile } from '../model';
import { CertBadge } from '../components/CertBadge';
import { EmptyState } from '../components/EmptyState';

@Entry
@Component
struct TutorList {
  @State list: TutorProfile[] = [];
  @State loading: boolean = false;
  @State subject: string = '';
  @State priceMin: string = '';
  @State priceMax: string = '';
  @State certifiedOnly: boolean = false;
  @State filtered: TutorProfile[] = [];

  async aboutToAppear() {
    await this.load();
  }

  async load() {
    this.loading = true;
    try {
      this.list = await get<TutorProfile[]>('/api/tutors');
      this.applyFilter();
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.loading = false;
    }
  }

  applyFilter() {
    const kw = this.subject.trim();
    const pMin = isEmpty(this.priceMin) ? 0 : Number(this.priceMin);
    const pMax = isEmpty(this.priceMax) ? 0 : Number(this.priceMax);
    this.filtered = this.list.filter((t: TutorProfile) => {
      if (kw && t.subjects.indexOf(kw) < 0) {
        return false;
      }
      if (pMin > 0 && t.price_max > 0 && t.price_max < pMin) {
        return false;
      }
      if (pMax > 0 && t.price_min > pMax) {
        return false;
      }
      if (this.certifiedOnly && !t.certified) {
        return false;
      }
      return true;
    });
  }

  resetFilter() {
    this.subject = '';
    this.priceMin = '';
    this.priceMax = '';
    this.certifiedOnly = false;
    this.applyFilter();
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        Text('浏览家教').fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
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
        }.width('100%')

        Row({ space: 12 }) {
          Button('筛选')
            .layoutWeight(1)
            .height(40)
            .backgroundColor($r('app.color.app_primary'))
            .fontColor('#FFFFFF')
            .enabled(!this.loading)
            .onClick(() => this.applyFilter())
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
      if (this.loading && this.filtered.length === 0) {
        Column() {
          Text('加载中...').fontSize(14).fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .padding(40)
        .justifyContent(FlexAlign.Center)
      } else if (this.filtered.length === 0) {
        EmptyState({ text: '暂无家教' })
      } else {
        List({ space: 10 }) {
          ForEach(this.filtered, (item: TutorProfile) => {
            ListItem() {
              this.TutorCard(item)
            }
          }, (item: TutorProfile) => item.user_id.toString())
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
  TutorCard(item: TutorProfile) {
    Column({ space: 8 }) {
      Row() {
        Text(item.nickname || '家教')
          .fontSize(16).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        if (item.certified) {
          CertBadge()
        }
        Blank()
        Text(formatPrice(item.price_min, item.price_max))
          .fontSize(13).fontColor($r('app.color.app_accent'))
      }.width('100%')

      Row({ space: 4 }) {
        Text('学校').fontSize(12).fontColor($r('app.color.text_secondary'))
        Text(item.school || '未填写')
          .fontSize(12).fontColor($r('app.color.text_primary'))
      }.width('100%')

      Row({ space: 4 }) {
        Text('擅长').fontSize(12).fontColor($r('app.color.text_secondary'))
        Text(item.subjects || '未填写')
          .fontSize(12).fontColor($r('app.color.text_primary'))
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }.width('100%')

      Row({ space: 4 }) {
        Text('区域').fontSize(12).fontColor($r('app.color.text_secondary'))
        Text(maskLocation(item.region) || '未填写')
          .fontSize(12).fontColor($r('app.color.text_secondary'))
      }.width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onClick(() => router.pushUrl({ url: 'pages/TutorDetail', params: { tutorId: item.user_id } }))
  }
}
