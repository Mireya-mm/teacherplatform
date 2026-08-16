// 电子协议草稿页
import router from '@ohos.router';
import { createOrder, listOrders, listConversations } from '../api/service';
import { toast, toastError, formatTime } from '../utils';
import { ORDER_STATUS_LABEL } from '../model';
import type { Order, TeachMode, Conversation, CreateOrderPayload } from '../model';
import { EmptyState } from '../components/EmptyState';

@Entry
@Component
struct OrderDraft {
  @State orders: Order[] = [];
  @State loading: boolean = false;
  @State submitting: boolean = false;
  @State price: string = '';
  @State schedule: string = '';
  @State mode: TeachMode = 'online';
  private conversationId: number = 0;
  private tutorId: number = 0;

  async aboutToAppear() {
    const p = router.getParams() as Record<string, string | number>;
    this.conversationId = Number(p.conversationId);
    this.tutorId = Number(p.tutorId);
    // 若路由未传 tutorId，从会话列表解析
    if (!this.tutorId) {
      await this.resolveTutorId();
    }
    await this.loadOrders();
  }

  async resolveTutorId() {
    try {
      const list: Conversation[] = await listConversations();
      const conv = list.find(c => c.id === this.conversationId);
      if (conv) {
        this.tutorId = conv.tutor_id;
      }
    } catch (e) {
      // 静默
    }
  }

  async loadOrders() {
    this.loading = true;
    try {
      this.orders = await listOrders();
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.loading = false;
    }
  }

  async doSubmit() {
    if (!this.price) {
      toast('请填写课时价格');
      return;
    }
    if (!this.schedule) {
      toast('请填写授课时间');
      return;
    }
    if (!this.tutorId) {
      toast('未获取到家教信息，请稍后重试');
      return;
    }
    this.submitting = true;
    try {
      const payload: CreateOrderPayload = {
        tutor_id: this.tutorId,
        price: Number(this.price),
        schedule: this.schedule,
        mode: this.mode
      };
      await createOrder(payload);
      toast('已生成电子协议草稿');
      this.price = '';
      this.schedule = '';
      this.mode = 'online';
      await this.loadOrders();
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
        Text('电子协议').fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary')).margin({ left: 8 })
        Blank()
      }
      .width('100%').height(52).padding({ left: 16, right: 16 }).backgroundColor('#FFFFFF')

      Scroll() {
        Column({ space: 14 }) {
          // 草稿表单
          Column({ space: 12 }) {
            Text('新建协议草稿').fontSize(15).fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary')).alignSelf(ItemAlign.Start)

            Column({ space: 6 }) {
              Text('课时价格（元/课时）').fontSize(13).fontColor($r('app.color.text_secondary'))
                .alignSelf(ItemAlign.Start)
              TextInput({ text: this.price, placeholder: '请输入数字' })
                .type(InputType.Number)
                .height(44)
                .backgroundColor($r('app.color.app_bg'))
                .borderRadius(10)
                .onChange((v: string) => this.price = v)
            }.width('100%')

            Column({ space: 6 }) {
              Text('授课时间').fontSize(13).fontColor($r('app.color.text_secondary'))
                .alignSelf(ItemAlign.Start)
              TextInput({ text: this.schedule, placeholder: '如：每周六 14:00-16:00' })
                .height(44)
                .backgroundColor($r('app.color.app_bg'))
                .borderRadius(10)
                .onChange((v: string) => this.schedule = v)
            }.width('100%')

            Column({ space: 6 }) {
              Text('授课模式').fontSize(13).fontColor($r('app.color.text_secondary'))
                .alignSelf(ItemAlign.Start)
              Row({ space: 16 }) {
                Row({ space: 4 }) {
                  Radio({ value: 'online', group: 'mode' })
                    .checked(this.mode === 'online')
                    .onChange((isChecked: boolean) => { if (isChecked) this.mode = 'online' })
                  Text('线上').fontSize(14).fontColor($r('app.color.text_primary'))
                }
                Row({ space: 4 }) {
                  Radio({ value: 'offline', group: 'mode' })
                    .checked(this.mode === 'offline')
                    .onChange((isChecked: boolean) => { if (isChecked) this.mode = 'offline' })
                  Text('线下').fontSize(14).fontColor($r('app.color.text_primary'))
                }
              }.width('100%')
            }.width('100%')

            Button('生成草稿')
              .width('100%').height(44)
              .backgroundColor($r('app.color.app_primary')).fontColor('#FFFFFF')
              .enabled(!this.submitting)
              .onClick(() => this.doSubmit())
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)

          // 已有协议列表
          Text('已有协议').fontSize(15).fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .width('100%')

          if (this.loading && this.orders.length === 0) {
            Text('加载中...').fontSize(14).fontColor($r('app.color.text_secondary'))
              .width('100%').textAlign(TextAlign.Center).padding(20)
          } else if (this.orders.length === 0) {
            EmptyState({ text: '暂无协议' })
          } else {
            ForEach(this.orders, (order: Order) => {
              this.OrderCard(order)
            }, (order: Order) => order.id.toString())
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 20 })
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg'))
  }

  @Builder
  OrderCard(order: Order) {
    Column({ space: 8 }) {
      Row() {
        Text(`${order.price}元/课时`)
          .fontSize(15).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text(ORDER_STATUS_LABEL[order.status])
          .fontSize(11).fontColor('#FFFFFF')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(10)
          .backgroundColor(order.status === 'confirmed' ? $r('app.color.app_primary') : $r('app.color.app_accent'))
      }.width('100%')

      Row({ space: 4 }) {
        Text('授课时间').fontSize(12).fontColor($r('app.color.text_secondary'))
        Text(order.schedule || '-').fontSize(12).fontColor($r('app.color.text_primary'))
      }.width('100%')

      Row({ space: 4 }) {
        Text('模式').fontSize(12).fontColor($r('app.color.text_secondary'))
        Text(order.mode === 'online' ? '线上' : '线下')
          .fontSize(12).fontColor($r('app.color.text_primary'))
        Blank()
        Text(formatTime(order.created_at)).fontSize(11).fontColor($r('app.color.text_secondary'))
      }.width('100%')

      Button('去评价')
        .width('100%').height(36)
        .backgroundColor($r('app.color.app_primary')).fontColor('#FFFFFF').fontSize(13)
        .margin({ top: 4 })
        .onClick(() => router.pushUrl({
          url: 'pages/Evaluation',
          params: { orderId: order.id, toUser: order.tutor_id }
        }))
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }
}
