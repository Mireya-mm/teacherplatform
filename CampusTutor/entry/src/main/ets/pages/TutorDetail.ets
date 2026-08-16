// 家教简历主页
import router from '@ohos.router';
import { getTutorProfile, listReviewsByTutor } from '../api/service';
import { post } from '../api/http';
import { getRole, getUserId } from '../store';
import { toast, toastError, formatPrice, formatTime } from '../utils';
import type { TutorProfile, Review, Conversation, PostConversationPayload } from '../model';
import { CertBadge } from '../components/CertBadge';
import { EmptyState } from '../components/EmptyState';

@Entry
@Component
struct TutorDetail {
  @State tutorId: number = 0;
  @State profile: TutorProfile | null = null;
  @State reviews: Review[] = [];
  @State loading: boolean = false;
  @State starting: boolean = false;

  async aboutToAppear() {
    const p = router.getParams() as Record<string, number>;
    this.tutorId = p.tutorId;
    this.loading = true;
    try {
      const result = await Promise.all([
        getTutorProfile(this.tutorId),
        listReviewsByTutor(this.tutorId)
      ]) as [TutorProfile, Review[]];
      const profile = result[0];
      const reviews = result[1];
      this.profile = profile;
      this.reviews = reviews || [];
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.loading = false;
    }
  }

  isSelf(): boolean {
    return getUserId() === this.tutorId;
  }

  isParent(): boolean {
    return getRole() === 'parent';
  }

  async startChat() {
    this.starting = true;
    try {
      const payload: PostConversationPayload = { other_user_id: this.tutorId };
      const conv = await post<Conversation>('/api/conversations', payload);
      const otherNickname = this.profile ? this.profile.nickname : '';
      router.pushUrl({
        url: 'pages/Chat',
        params: { conversationId: conv.id, otherNickname }
      });
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.starting = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Row() {
          Text('家教简历').fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
          Blank()
          Text('举报')
            .fontSize(13)
            .fontColor($r('app.color.danger'))
            .onClick(() => router.pushUrl({
              url: 'pages/Report',
              params: { target_type: 'tutor', target_id: this.tutorId }
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
        } else if (this.profile) {
          this.DetailBody(this.profile as TutorProfile)
          this.ReviewsSection()
          this.BottomActions()
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
  DetailBody(p: TutorProfile) {
    Column({ space: 8 }) {
      Row() {
        Text(p.nickname || '家教')
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        if (p.certified) {
          CertBadge()
        }
      }.width('100%')
      Text(p.school || '未填写学校')
        .fontSize(13).fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 16, right: 16 })
    .alignItems(HorizontalAlign.Start)

    Column({ space: 12 }) {
      this.InfoRow('擅长科目', p.subjects || '未填写')
      this.InfoRow('期望单价', formatPrice(p.price_min, p.price_max))
      this.InfoRow('可授课区域', p.region || '未填写')
      this.InfoRow('授课经验', p.experience || '未填写')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 16, right: 16 })

    Column({ space: 8 }) {
      Text('自我介绍').fontSize(14).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
      Text(p.intro || '暂无介绍')
        .fontSize(13).fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 16, right: 16 })
    .alignItems(HorizontalAlign.Start)
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
  ReviewsSection() {
    Column({ space: 10 }) {
      Text('学员评价').fontSize(14).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
      if (this.reviews.length === 0) {
        Text('暂无评价').fontSize(13).fontColor($r('app.color.text_secondary'))
      } else {
        ForEach(this.reviews, (r: Review) => {
          Column({ space: 4 }) {
            Row() {
              Text(r.from_nickname || '学员')
                .fontSize(13).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
              Blank()
              Row({ space: 4 }) {
                Text(this.Stars(r.score)).fontSize(12).fontColor($r('app.color.gold_badge'))
                Text(r.score.toString()).fontSize(12).fontColor($r('app.color.gold_badge'))
              }
            }.width('100%')
            Text(r.comment || '')
              .fontSize(13).fontColor($r('app.color.text_primary'))
              .width('100%')
            Text(formatTime(r.created_at))
              .fontSize(11).fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .padding(10)
          .backgroundColor($r('app.color.app_bg'))
          .borderRadius(8)
          .alignItems(HorizontalAlign.Start)
        }, (r: Review) => r.id.toString())
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 16, right: 16 })
    .alignItems(HorizontalAlign.Start)
  }

  Stars(score: number): string {
    const n = score > 5 ? 5 : (score < 0 ? 0 : Math.floor(score));
    let s = '';
    for (let i = 0; i < n; i++) {
      s += '★';
    }
    return s;
  }

  @Builder
  BottomActions() {
    if (this.isParent()) {
      Button('开始沟通')
        .width('90%').height(46)
        .backgroundColor($r('app.color.app_primary')).fontColor('#FFFFFF')
        .enabled(!this.starting)
        .margin({ top: 4, bottom: 12 })
        .onClick(() => this.startChat())
    } else if (this.isSelf()) {
      Button('编辑简历')
        .width('90%').height(46)
        .backgroundColor($r('app.color.app_primary')).fontColor('#FFFFFF')
        .margin({ top: 4, bottom: 12 })
        .onClick(() => router.pushUrl({ url: 'pages/TutorProfileEdit' }))
    }
  }
}
