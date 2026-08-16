# 校园家教智能匹配平台

> 基于 OpenHarmony ArkTS 原生开发的去中介校园家教双向撮合鸿蒙 App，配套 Python Flask + SQLite 后端。聚焦「安全体系 + 智能匹配」两大差异化亮点。

---

## 一、项目亮点

1. **OpenHarmony 原生**：ArkTS Stage 模型（API 9+），真原生工程，非 H5 套壳 / 小程序。
2. **多层资质信任体系**：学籍 / 学历 / 四六级 / 教资四类证件上传 + 管理员审核，未通过认证的家教**无法投递意向**。
3. **内置线下授课安全防护机制**（最大亮点）：
   - 隐私脱敏：聊天界面手机号、详细地址自动脱敏（`138****1234`）
   - 线下安全须知强制确认弹窗（必须勾选「已阅读并知悉」方可继续）
   - 聊天记录后台持久化留存，可溯源
   - 违规管控 + 举报入口
4. **融合大模型实现智能供需匹配**（阿里百炼，可插拔 + 降级）：AI 故障时自动切换规则匹配，核心业务不中断。
5. **去中介、免费轻量化**：平台只做信息撮合，不介入资金交易。

---

## 二、目录结构

```
smart-support-platform/
├── CampusTutor/                      # 鸿蒙工程（DevEco Studio 打开此目录）
│   ├── AppScope/
│   │   ├── app.json5
│   │   └── resources/base/element/string.json
│   ├── entry/
│   │   ├── src/main/
│   │   │   ├── ets/
│   │   │   │   ├── entryability/
│   │   │   │   │   ├── EntryAbility.ets
│   │   │   │   │   └── pages/Index.ets        # 启动分发（自动登录）
│   │   │   │   ├── pages/                      # 22 个业务页面
│   │   │   │   │   ├── Login.ets / Register.ets
│   │   │   │   │   ├── Home.ets                 # 按 role 动态分流 Tabs
│   │   │   │   │   ├── DemandList / DemandDetail / PublishDemand / MyDemands / MyCandidates
│   │   │   │   │   ├── TutorList / TutorDetail / Certification / TutorProfileEdit / MyApplications
│   │   │   │   │   ├── ChatList / Chat / OrderDraft / SafetyNotice / Report / Evaluation
│   │   │   │   │   ├── Admin.ets / Profile.ets
│   │   │   │   ├── api/                          # HTTP 封装 + service + endpoints + config
│   │   │   │   ├── model/                        # 数据类型
│   │   │   │   ├── store/                        # preferences 封装
│   │   │   │   ├── utils/                        # 脱敏/格式化/toast
│   │   │   │   └── components/                   # CertBadge / EmptyState / SafetyNoticeDialog
│   │   │   ├── resources/base/                  # string/color/media/profile
│   │   │   └── module.json5
│   │   ├── build-profile.json5 / hvigorfile.ts / oh-package.json5
│   ├── build-profile.json5 / hvigorfile.ts / oh-package.json5 / hvigor/
│
└── backend/                          # Flask + SQLite 后端
    ├── app.py                        # 入口（host=0.0.0.0 port=5000）
    ├── models.py                     # 11 张 SQLAlchemy 表
    ├── db_init.py                    # 建表 + 种子数据（幂等）
    ├── requirements.txt
    ├── .env.example                  # DASHSCOPE_API_KEY 模板
    ├── utils/                        # auth（token 鉴权 + role_required）/ response
    ├── routes/                       # 12 个蓝图（auth/users/tutors/demands/applications/conversations/orders/reviews/reports/safety/admin/ai）
    └── ai/bailian.py                 # 百炼调用 + 规则降级
```

---

## 三、启动步骤

### 1. 启动后端

```bash
cd smart-support-platform/backend
pip install -r requirements.txt      # Flask / Flask-SQLAlchemy / Flask-CORS / dashscope / requests
python db_init.py                    # 初始化数据库 + 种子数据（幂等，可重复执行）
python app.py                        # 启动服务，监听 http://0.0.0.0:5000
```

### 2. 启用阿里百炼 AI（可选）

```bash
cp backend/.env.example backend/.env
# 编辑 .env，填入 DASHSCOPE_API_KEY=sk-xxxx
```

未配置 Key 时三个 AI 接口自动走规则匹配降级路径，业务不中断。

### 3. 配置鸿蒙 App 后端地址

编辑 `CampusTutor/entry/src/main/ets/api/config.ets`：

```ts
// 模拟器访问本机后端
export const BASE_URL: string = 'http://127.0.0.1:5000';
// 真机调试改为后端机器局域网 IP，例如
// export const BASE_URL: string = 'http://192.168.1.100:5000';
```

### 4. 打开并编译鸿蒙工程

1. DevEco Studio → File → Open → 选中 `smart-support-platform/CampusTutor/` 目录
2. 等待 Sync 完成
3. Build → Build Hap(s) 编译（无 Error）
4. Run 到 HarmonyOS 模拟器或真机

---

## 四、演示账号

| 身份 | 手机号 | 密码 | 备注 |
|------|--------|------|------|
| 管理员 | 13800000000 | 123456 | 资质审核 / 需求管控 / 用户封禁 |
| 家长 | 13800000001 | 123456 | 已发布 1 条数学需求 |
| 家教 | 13800000002 | 123456 | 清华大学，已通过学籍认证（certified） |

---

## 五、演示流程脚本（核心闭环）

> 用两个演示账号完整走通：注册 → 上传证件 → 审核 → 发布需求 → 投递 → 接受 → 聊天 → 安全须知 → 电子协议 → 互评。

### 场景一：完整闭环（使用种子数据，最快演示）

1. 后端 `python db_init.py` 已写入种子数据（家教已认证 + 需求 + 投递 + 会话）。
2. 家长账号 `13800000001 / 123456` 登录 → 家长端首页。
3. 「我的需求」→ 看到数学需求 → 「查看候选人」→ 看到「李同学」投递 → 点「接受」。
4. 「找家教」→ 进入李同学简历 → 「开始沟通」→ 进入聊天。
5. 聊天页：进入即弹「线下见面谨慎交换联系方式」安全提示；右上角「安全须知」弹强制确认弹窗（必须勾选才能确认）。
6. 家长底部「生成电子协议」→ 填写价格/时间/模式 → 提交 → 「去评价」→ 5 星 + 评语 → 提交。
7. 切换家教账号 `13800000002 / 123456` 登录 → 「我的投递」看到状态变「已接受」。
8. 家教「我的简历」→ 可见评价展示；「资质认证」可见已通过学籍徽标。

### 场景二：注册身份分流演示

1. 登录页 → 「立即注册」。
2. 注册页：**大卡片单选**家长 / 家教（图标 + 文案说明，未选择无法提交）。
3. 填写手机号/密码/昵称，家教需填高校 → 注册成功自动登录。
4. 家长端首页底部 Tab：首页/我的需求/找家教/消息/我的；家教端：首页/浏览需求/我的投递/消息/我的——**两端 Tab 完全不同**，未授权功能对当前身份隐藏。

### 场景三：安全机制演示

1. 未认证家教投递：新注册一个家教账号（不上传证件）→ 浏览需求 → 「投递意向」按钮置灰，点击 toast「请先完成资质认证」。
2. 聊天脱敏：在聊天中发送「我的手机 13800001111」→ 对方看到的是 `138****1111`。
3. 管理员审核：管理员登录 → 管理后台 → 资质审核 Tab → 通过/驳回。
4. 管理员下架/封禁：需求管控 Tab 下架需求；用户管理 Tab 封禁用户。
5. 举报入口：需求详情/家教详情右上角「举报」→ 提交举报。

### 场景四：AI 模块演示

1. 家教「我的简历」→ 编辑简历 → AI 解析：粘贴一段自述文本 → 点「AI 解析」→ 自动填充擅长科目。
2. 家长「发布需求」→ AI 智能规整：输入零散描述 → 点「AI 智能规整」→ 自动填充表单。
3. **断网/无 Key 降级**：未配置 `DASHSCOPE_API_KEY` 时，AI 接口返回结果带 `ai_degraded: true`，走规则匹配，业务不中断。

---

## 六、功能清单与完成度

| 编号 | 功能 | 状态 |
|------|------|------|
| F1 | 账号注册登录与身份分流（强制身份卡片选择 + 按 role 分流首页 + 后端权限校验） | ✅ |
| F2 | 家教资质认证（四类证件上传 + 审核状态 + 未认证禁止投递） | ✅ |
| F3 | 家长发布家教需求（含状态流转） | ✅ |
| F4 | 家教简历主页（擅长/经验/单价/区域/认证/评价） | ✅ |
| F5 | 筛选检索（科目/价格/认证/排序） | ✅ |
| F6 | 投递意向（投递 + 候选人查看 + 接受/拒绝） | ✅ |
| F7 | 简易在线聊天（会话组织 + 后台持久化） | ✅ |
| F8 | 评价体系（双向互评 + 公开展示） | ✅ |
| F9 | 阿里百炼大模型（解析简历 / 智能匹配 / 规整需求，可插拔 + 降级） | ✅ |
| F10.1 | 隐私保护隔离（手机号/地址脱敏 + 见面提示） | ✅ |
| F10.2 | 线下授课安全指引弹窗（强制勾选确认） | ✅ |
| F10.3 | 沟通内容日志留存（后台持久化 + 管理员可查） | ✅ |
| F10.4 | 违规管控（下架/封禁 + 举报入口） | ✅ |
| F11 | 订单预约草稿（电子协议） | ✅ |

---

## 七、项目短板（答辩预案）

- **资金交易不介入**：平台只做信息撮合，不搭建线上支付；课时费双方线下协商。
- **证件仅线上图片初审**：无联网官方核验接口；页面明确标注「平台仅做初步展示，家长自主甄别」。

---

## 八、自评表（评分维度）

| 维度 | 权重 | 自评分 | 扣分点说明 |
|------|------|--------|-----------|
| D1 功能完整性 | 20% | 9 | F1-F8 全部闭环可演示；F11 电子协议较简化 |
| D2 鸿蒙原生规范度 | 15% | 9 | ArkTS Stage 模型；正确使用 UIAbility、router、@ohos.net.http、@ohos.data.preferences、@ohos.file.picker/fs/buffer、@ohos.promptAction |
| D3 可运行性 | 15% | 8 | 工程结构完整；需 DevEco Studio 环境 Sync 后编译；后端 python app.py 一键启动 |
| D4 安全机制实现度 | 15% | 10 | 脱敏 + 强制弹窗 + 留痕 + 违规管控 + 举报全部真实生效 |
| D5 AI 模块可插拔性 | 10% | 9 | 百炼调用 try/except 包裹，失败降级规则匹配；三功能真实调用非 mock |
| D6 代码质量 | 10% | 9 | 前后端分层清晰；统一响应/鉴权/异常处理；无明显重复 |
| D7 数据与接口规范 | 5% | 9 | 11 张表带外键；RESTful；统一错误码；token 鉴权中间件 |
| D8 UI / UX 完成度 | 5% | 8 | 蓝白主色 + 橙色强调；列表/空态/加载/错误态齐全；身份卡片大单选 |
| D9 文档与可演示性 | 5% | 9 | README 含启动/账号/演示脚本；种子数据齐全 |
| D10 创新与亮点表达 | 5% | 9 | 鸿蒙原生 + 安全体系在代码与文档显性体现 |

**加权总分：约 8.9 / 10**

---

## 九、常用命令速查

```bash
# 后端
cd backend && python db_init.py        # 重置数据库（幂等）
cd backend && python app.py            # 启动服务

# 鸿蒙
# DevEco Studio 打开 CampusTutor/ → Build → Build Hap(s)
# Run → 模拟器/真机
```
