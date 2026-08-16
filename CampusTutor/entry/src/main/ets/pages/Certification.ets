// 资质认证上传
import router from '@ohos.router';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import buffer from '@ohos.buffer';
import { getCertifications, uploadCertification } from '../api/service';
import { getRole } from '../store';
import { toast, toastError, formatTime } from '../utils';
import { CERT_TYPE_LABEL, CERT_STATUS_LABEL } from '../model';
import type { Certification, CertType, CertStatus } from '../model';
import { EmptyState } from '../components/EmptyState';

@Entry
@Component
struct CertificationPage {
  @State list: Certification[] = [];
  @State loading: boolean = false;
  @State uploading: boolean = false;
  @State certType: CertType = 'student';

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
      this.list = await getCertifications();
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.loading = false;
    }
  }

  statusColor(status: CertStatus): Resource {
    if (status === 'approved') {
      return $r('app.color.gold_badge');
    }
    if (status === 'rejected') {
      return $r('app.color.danger');
    }
    return $r('app.color.app_accent');
  }

  async pickAndUpload() {
    if (this.uploading) {
      return;
    }
    this.uploading = true;
    try {
      const photoPicker = new picker.PhotoViewPicker();
      const res = await photoPicker.select({
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      });
      const uri: string = res.photoUris[0];
      const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      try {
        const stat = fs.statSync(file.fd);
        const ab = new ArrayBuffer(stat.size);
        fs.readSync(file.fd, ab);
        const b64 = buffer.from(ab).toString('base64');
        await uploadCertification(this.certType, b64);
        toast('已上传，等待审核');
        await this.load();
      } finally {
        fs.closeSync(file);
      }
    } catch (e) {
      toastError(e as Error);
    } finally {
      this.uploading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Text('资质认证')
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
          .width('100%')
          .padding({ left: 16, right: 16, top: 16 })

        // 已有证件列表
        Text('已上传证件').fontSize(14).fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
          .margin({ left: 16, top: 4 })

        if (this.loading && this.list.length === 0) {
          Column() {
            Text('加载中...').fontSize(14).fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .padding(40)
          .justifyContent(FlexAlign.Center)
        } else if (this.list.length === 0) {
          EmptyState({ text: '暂未上传证件' })
        } else {
          List({ space: 10 }) {
            ForEach(this.list, (item: Certification) => {
              ListItem() {
                this.CertCard(item)
              }
            }, (item: Certification) => item.id.toString())
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
        }

        // 上传区
        Column({ space: 12 }) {
          Text('上传新证件').fontSize(14).fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .width('100%')

          Text('证件类型').fontSize(13).fontColor($r('app.color.text_secondary'))
            .width('100%')
          Row({ space: 8 }) {
            this.TypeRadio('student', '学籍')
            this.TypeRadio('degree', '学历')
            this.TypeRadio('cet4', '四六级')
            this.TypeRadio('teacher', '教资')
          }.width('100%')

          Button(this.uploading ? '上传中...' : '选择图片并上传')
            .width('100%').height(46)
            .backgroundColor($r('app.color.app_primary')).fontColor('#FFFFFF')
            .enabled(!this.uploading)
            .onClick(() => this.pickAndUpload())
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ left: 16, right: 16, bottom: 24 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_bg'))
  }

  @Builder
  TypeRadio(value: CertType, label: string) {
    Row({ space: 4 }) {
      Radio({ value: value, group: 'certType' })
        .checked(this.certType === value)
        .onChange((checked: boolean) => { if (checked) this.certType = value; })
      Text(label).fontSize(12).fontColor($r('app.color.text_primary'))
    }
  }

  @Builder
  CertCard(item: Certification) {
    Column({ space: 8 }) {
      Row() {
        Text(CERT_TYPE_LABEL[item.type])
          .fontSize(15).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
        Blank()
        Text(CERT_STATUS_LABEL[item.status])
          .fontSize(11).fontColor('#FFFFFF')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(10)
          .backgroundColor(this.statusColor(item.status))
      }.width('100%')

      Row({ space: 4 }) {
        Text('上传时间').fontSize(12).fontColor($r('app.color.text_secondary'))
        Text(formatTime(item.created_at))
          .fontSize(12).fontColor($r('app.color.text_secondary'))
      }.width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }
}
