// 空状态占位
@Component
export struct EmptyState {
  @Prop text: string = '暂无数据';

  build() {
    Column({ space: 12 }) {
      Text('🗂️').fontSize(48)
      Text(this.text).fontSize(14).fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(40)
    .justifyContent(FlexAlign.Center)
  }
}
