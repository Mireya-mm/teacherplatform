// 注册页 - 强制身份选择（家长/家教二选一，大卡片单选 + 图标）
import router from '@ohos.router';
import { register } from '../api/service';
import { saveLoginInfo } from '../store';
import { toast, toastError, isEmpty } from '../utils';
import type { LoginInfo, Role, RegisterPayload } from '../model';

@Entry
@Component
struct Register {
  @State phone: string = '';
  @State password: string = '';
  @State nickname: string = '';
  @State school: string = '';
  @State selectedRole: Role | null = null;
  @State loading: boolean = false;

  async doRegister() {
    if (isEmpty(this.phone) || isEmpty(this.password) || isEmpty(this.nickname)) {
      toast('请填写完整基本信息');
      return;
    }
    if (this.selectedRole === 'tutor' && isEmpty(this.school)) {
      toast('家教必须填写所在高校');
      return;
    }
    if (this.selectedRole === null) {
      toast('请选择身份（家长 / 家教）');
      return;
    }
    this.loading = true;
    try {
      const payload: RegisterPayload = {
        phone: this.phone,
        password: this.password,
        nickname: this.nickname,
        school: this.selectedRole === 'tutor' ? this.school : '',
        role: this.selectedRole
      };
      const info: LoginInfo = await register(payload);
      await saveLoginInfo(info);
      toast('注册成功');
      router.replaceUrl({ url: 'pages/Home' });
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.loading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('创建账号')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .margin({ top: 12, bottom: 8 })

        Text('请选择您的身份（注册后不可切换）')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .alignSelf(ItemAlign.Start)

        // 身份大卡片单选
        Row({ space: 12 }) {
          this.RoleCard('parent', '家长', '👨‍👩‍👧', '孩子需要辅导', '#3B82F6')
          this.RoleCard('tutor', '家教', '🎓', '我想接家教', '#F97316')
        }
        .width('100%')

        this.InputField('手机号', (v) => this.phone = v)
        this.InputField('密码', (v) => this.password = v, true)
        this.InputField('昵称', (v) => this.nickname = v)
        this.InputField('所在高校（家教必填）', (v) => this.school = v)

        Button('注册并登录')
          .width('100%')
          .height(48)
          .backgroundColor($r('app.color.app_primary'))
          .fontColor('#FFFFFF')
          .fontSize(16)
          .enabled(!this.loading)
          .margin({ top: 12 })
          .onClick(() => this.doRegister())

        Text('返回登录').fontSize(13).fontColor($r('app.color.text_secondary'))
          .onClick(() => router.back())
          .margin({ bottom: 16 })
      }
      .width('100%')
      .padding(24)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  RoleCard(value: Role, label: string, icon: string, desc: string, color: string) {
    Column({ space: 8 }) {
      Text(icon).fontSize(40)
      Text(label).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
      Text(desc).fontSize(11).fontColor('#FFFFFFCC')
    }
    .layoutWeight(1)
    .height(120)
    .justifyContent(FlexAlign.Center)
    .borderRadius(14)
    .backgroundColor(color)
    .border({
      width: this.selectedRole === value ? 3 : 0,
      color: '#111827'
    })
    .opacity(this.selectedRole !== null && this.selectedRole !== value ? 0.5 : 1)
    .onClick(() => {
      this.selectedRole = value;
    })
  }

  @Builder
  InputField(label: string, onChange: (v: string) => void, isPwd = false) {
    Column({ space: 6 }) {
      Text(label).fontSize(13).fontColor($r('app.color.text_secondary')).alignSelf(ItemAlign.Start)
      TextInput({ placeholder: `请输入${label}` })
        .type(isPwd ? InputType.Password : InputType.Normal)
        .height(48)
        .backgroundColor($r('app.color.app_bg'))
        .borderRadius(10)
        .onChange(onChange)
    }
    .width('100%')
  }
}
