// 聊天页 - 脱敏核心 + 安全提示（F10.1）
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { listMessages, sendMessage, listConversations, ackSafety } from '../api/service';
import { getUserId, getRole } from '../store';
import { toast, toastError, maskPhone, formatTime, isEmpty } from '../utils';
import type { Message, Conversation, AckSafetyPayload } from '../model';
import { SafetyNoticeDialog } from '../components/SafetyNoticeDialog';

@Entry
@Component
struct Chat {
  @State messages: Message[] = [];
  @State input: string = '';
  @State loading: boolean = false;
  @State sending: boolean = false;
  @State tutorId: number = 0;
  @State otherNickname: string = '';
  private conversationId: number = 0;

  dialogController: CustomDialogController = new CustomDialogController({
    builder: SafetyNoticeDialog({
      onConfirmed: () => {
        this.doAckSafety();
      }
    })
  });

  async aboutToAppear() {
    const p = router.getParams() as Record<string, string | number>;
    this.conversationId = Number(p.conversationId);
    this.otherNickname = String(p.otherNickname || '对方');

    // 首次进入安全提示
    promptAction.showDialog({
      title: '安全提示',
      message: '线下见面谨慎交换联系方式，初次试讲请选择公共场所',
      buttons: [{ text: '我知道了', color: '#3B82F6' }]
    });

    await this.loadMessages();
    await this.loadConversation();
  }

  async loadMessages() {
    this.loading = true;
    try {
      this.messages = await listMessages(this.conversationId);
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.loading = false;
    }
  }

  // 取会话以解析 tutor_id（用于生成电子协议）及准确昵称
  async loadConversation() {
    try {
      const list: Conversation[] = await listConversations();
      const conv = list.find(c => c.id === this.conversationId);
      if (conv) {
        this.tutorId = conv.tutor_id;
        if (conv.parent_id === getUserId()) {
          this.otherNickname = conv.tutor_nickname || this.otherNickname;
        } else {
          this.otherNickname = conv.parent_nickname || this.otherNickname;
        }
      }
    } catch (e) {
      // 静默处理，不影响聊天主流程
    }
  }

  async doSend() {
    const content = this.input.trim();
    if (isEmpty(content)) {
      toast('请输入消息内容');
      return;
    }
    this.sending = true;
    try {
      const msg = await sendMessage(this.conversationId, content);
      // 本地追加，无需重新拉全部
      this.messages = [...this.messages, msg];
      this.input = '';
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.sending = false;
    }
  }

  async doAckSafety() {
    try {
      const payload: AckSafetyPayload = { ack_text: '已阅读并知悉' };
      await ackSafety(payload);
      toast('已记录安全须知确认');
    } catch (e) {
      toastError(e as Error);
    }
  }

  isMine(msg: Message): boolean {
    return msg.sender_id === getUserId();
  }

  build() {
    Column() {
      // 顶部栏
      Row() {
        Text('‹').fontSize(24).fontColor($r('app.color.text_primary'))
          .onClick(() => router.back())
        Text(this.otherNickname)
          .fontSize(18).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
          .layoutWeight(1).margin({ left: 8 })
        Text('安全须知').fontSize(13).fontColor($r('app.color.app_primary'))
          .onClick(() => this.dialogController.open())
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // 消息列表
      if (this.loading && this.messages.length === 0) {
        Column() {
          Text('加载中...').fontSize(14).fontColor($r('app.color.text_secondary'))
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.messages.length === 0) {
        Column() {
          Text('暂无消息，发送第一条吧').fontSize(14).fontColor($r('app.color.text_secondary'))
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.messages, (msg: Message) => {
            ListItem() {
              this.MsgBubble(msg)
            }
          }, (msg: Message) => msg.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      }

      // 家长身份底部「生成电子协议」按钮
      if (getRole() === 'parent') {
        Button('生成电子协议')
          .width('90%').height(38)
          .backgroundColor($r('app.color.app_accent')).fontColor('#FFFFFF').fontSize(13)
          .margin({ top: 4, bottom: 4 })
          .onClick(() => router.pushUrl({
            url: 'pages/OrderDraft',
            params: {
              conversationId: this.conversationId,
              tutorId: this.tutorId,
              otherNickname: this.otherNickname
            }
          }))
      }

      // 底部输入区
      Row({ space: 8 }) {
        TextInput({ text: this.input, placeholder: '输入消息...' })
          .layoutWeight(1)
          .height(40)
          .backgroundColor($r('app.color.app_bg'))
          .borderRadius(20)
          .onChange((v: string) => this.input = v)
        Button('发送')
          .height(40)
          .backgroundColor($r('app.color.app_primary')).fontColor('#FFFFFF')
          .enabled(!this.sending)
          .onClick(() => this.doSend())
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg'))
  }

  @Builder
  MsgBubble(msg: Message) {
    Row() {
      if (this.isMine(msg)) {
        Blank()
        Column({ space: 4 }) {
          Text(maskPhone(msg.content))
            .fontSize(14).fontColor('#FFFFFF')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .borderRadius(12)
            .backgroundColor($r('app.color.app_primary'))
          Text(formatTime(msg.created_at)).fontSize(10).fontColor($r('app.color.text_secondary'))
        }
        .alignItems(HorizontalAlign.End)
        .width('75%')
      } else {
        Column({ space: 4 }) {
          Text(maskPhone(msg.content))
            .fontSize(14).fontColor($r('app.color.text_primary'))
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .borderRadius(12)
            .backgroundColor('#FFFFFF')
          Text(formatTime(msg.created_at)).fontSize(10).fontColor($r('app.color.text_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
        .width('75%')
        Blank()
      }
    }.width('100%').alignItems(VerticalAlign.Top)
  }
}
