// 会话列表
import router from '@ohos.router';
import { listConversations } from '../api/service';
import { getUserId } from '../store';
import { toast, toastError, formatTime, maskPhone } from '../utils';
import type { Conversation } from '../model';
import { EmptyState } from '../components/EmptyState';

@Entry
@Component
struct ChatList {
  @State list: Conversation[] = [];
  @State loading: boolean = false;

  async aboutToAppear() {
    await this.load();
  }

  // router.back 回来时刷新列表
  async onPageShow() {
    await this.load();
  }

  async load() {
    this.loading = true;
    try {
      this.list = await listConversations();
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.loading = false;
    }
  }

  otherNickname(item: Conversation): string {
    const me = getUserId();
    if (item.parent_id === me) {
      return item.tutor_nickname || '家教';
    }
    return item.parent_nickname || '家长';
  }

  build() {
    Column({ space: 12 }) {
      Text('消息中心')
        .fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })

      if (this.loading && this.list.length === 0) {
        Column() {
          Text('加载中...').fontSize(14).fontColor($r('app.color.text_secondary'))
        }
        .width('100%').padding(40).justifyContent(FlexAlign.Center)
      } else if (this.list.length === 0) {
        EmptyState({ text: '暂无会话' })
      } else {
        List({ space: 10 }) {
          ForEach(this.list, (item: Conversation) => {
            ListItem() {
              this.ConvCard(item)
            }
          }, (item: Conversation) => item.id.toString())
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
  ConvCard(item: Conversation) {
    Column({ space: 6 }) {
      Row() {
        Text(this.otherNickname(item))
          .fontSize(16).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text(formatTime(item.last_time || ''))
          .fontSize(11).fontColor($r('app.color.text_secondary'))
      }.width('100%')

      Text(maskPhone(item.last_message || '暂无消息'))
        .fontSize(13).fontColor($r('app.color.text_secondary'))
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onClick(() => router.pushUrl({
      url: 'pages/Chat',
      params: { conversationId: item.id, otherNickname: this.otherNickname(item) }
    }))
  }
}
