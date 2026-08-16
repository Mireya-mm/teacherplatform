// 已认证金色徽标
@Component
export struct CertBadge {
  build() {
    Row({ space: 4 }) {
      Text('✔').fontSize(12).fontColor('#FFFFFF')
      Text('已认证').fontSize(12).fontColor('#FFFFFF')
    }
    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
    .borderRadius(10)
    .backgroundColor($r('app.color.gold_badge'))
  }
}
