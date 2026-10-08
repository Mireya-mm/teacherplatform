# 众测AI 开发提示词 · 基于OpenHarmony校园家教智能匹配平台

> 本文件用于指导众测AI生成一个**可运行的鸿蒙（OpenHarmony ArkTS）原生移动应用**，并配套 Python Flask + SQLite 后端。请众测AI严格按照本提示词的功能清单、技术栈、评分维度与验收标准进行开发。

---

## 〇、角色设定与任务目标

### 你（众测AI）的角色
你是一名同时精通 **OpenHarmony ArkTS 鸿蒙原生开发** 与 **Python Flask 后端开发** 的全栈工程师。你需要交付一个**能在 DevEco Studio 中直接编译运行、端云联调通过、演示流程完整**的鸿蒙 App 项目。

### 核心交付目标
1. 一个可直接在 DevEco Studio 打开编译的鸿蒙工程（ArkTS + Stage 模型）。
2. 一个可独立启动的 Flask 后端服务（含 SQLite 初始化脚本与种子数据）。
3. App 与后端通过 HTTP 通信，**核心功能闭环可演示**（注册→登录→发布需求→投递→聊天→评价→安全提示全流程跑通）。
4. 安全机制模块完整实现（这是本项目的最大亮点）。
5. 阿里百炼大模型模块以**可插拔**方式集成，接口故障时业务系统仍完整可用。

### 不可妥协的硬约束
- 必须是 **OpenHarmony ArkTS 原生工程**，**禁止**用 H5 套壳 / React Native / 小程序方案冒充。
- **必须交付一个 DevEco Studio 可直接打开的工程文件目录**（`CampusTutor/`，含 `AppScope/`、`entry/`、`build-profile.json5`、`oh-package.json5` 等完整工程文件），用户用 DevEco Studio → File → Open → 选中该目录即可加载，Build → Build Hap(s) 必须无 Error。
- 后端使用 **Python Flask + SQLite**，无需额外部署服务器，`python app.py` 即可启动。
- 鸿蒙工程最低 API 9（HarmonyOS 4.0 / OpenHarmony 4.x），Stage 模型。
- 所有 AI 调用必须包裹在 `try/except` 或 `try/catch` 中，失败时降级为规则匹配，**不得因 AI 故障导致核心业务不可用**。
- **注册必须强制身份选择**（家长/家教二选一），登录后按身份分流到不同首页与功能入口，未授权功能对当前身份隐藏（详见 F1）。

---

## 一、项目背景与定位

- **赛道**：程序设计应用（含移动应用）
- **项目名称**：基于OpenHarmony校园家教智能匹配平台
- **项目定位**：去中介校园家教双向撮合鸿蒙 App
- **解决痛点**：
  1. 市面家教中介抽成高
  2. 微信群信息杂乱、无资质审核
  3. 线下上门缺少安全规范
  4. 供需匹配低效

---

## 二、角色划分

| 角色 | 核心职责 |
|------|----------|
| 家长 | 发布辅导需求、筛选家教、在线沟通、课后评价 |
| 大学生家教 | 创建简历、资质上传、浏览需求、投递意向 |
| 平台管理员 | 资质审核、违规内容管控、纠纷备查 |

---

## 三、技术栈

| 层 | 技术 |
|----|------|
| 前端 | OpenHarmony ArkTS（Stage 模型，API 9+） |
| 后端 | Python Flask |
| 数据库 | SQLite（演示用，无需额外部署） |
| AI 服务 | 阿里百炼大模型（可选扩展模块，可插拔） |
| 通信 | HTTP REST + JSON，鸿蒙 `@ohos.net.http` |

---

## 四、完整功能清单

### ✅ 核心基础功能（答辩最低标准，优先开发）

#### F1 账号注册登录与身份分流【核心入口，必须重点实现】

**注册阶段强制身份选择**：
- 注册页面**必须**提供家长 / 家教 二选一的身份选择控件（建议用大卡片单选 + 图标，非下拉框），用户必须选择一种身份才能提交注册。
- 注册后身份**不可切换**（数据库 role 字段固定，前端不提供切换入口）。
- 字段：手机号、密码（明文入库需在答辩时说明仅演示，正式应加密）、昵称、所在高校（家教必填）、身份。

**登录后按身份分流到不同端（关键）**：
- 登录成功后根据 `role` 字段路由到**不同首页**：
  - **家长端首页**：主导航 = 发布需求 / 我的需求 / 找家教 / 消息 / 我的；突出"发布需求"和"查看候选人"入口。
  - **家教端首页**：主导航 = 浏览需求 / 我的投递 / 我的简历 / 消息 / 我的；突出"浏览需求"和"投递意向"入口，并显示认证状态徽标。
  - **管理员端首页**（可选）：资质审核待办 / 需求管控 / 用户封禁 / 举报处理。
- 同一 App 内通过身份字段动态渲染底部 Tab 与功能入口，**未授权功能对当前身份隐藏**（如家长看不到"投递意向"入口，家教看不到"发布需求"入口）。
- 后端接口须校验身份权限：家教调用 `/api/demands`（POST 发布）应返回 403；家长调用 `/api/applications`（POST 投递）应返回 403。

**登录态**：
- 登录返回 token，后续请求携带。
- token + role 存 `@ohos.data.preferences`，冷启动自动登录并按 role 跳转对应首页。

#### F2 家教资质认证模块【重点亮点】
- 家教可选择上传：学籍证明、学历证书、四六级证书、教资证书（图片上传，base64 或文件存储）。
- 每张证件含状态：待审核 / 已通过 / 已驳回。
- 平台在简历主页对已通过的家教展示【已认证】标签。
- **关键规则**：未通过任何认证的家教**可以浏览需求，但不能投递意向**，前端按钮置灰并提示"请先完成资质认证"。

#### F3 家长发布家教需求
- 字段：年级、科目、期望课时费区间（min/max）、授课地点、线上/线下、授课时间、详细描述。
- 需求状态：发布中 / 已关闭 / 已撮合。

#### F4 家教简历主页
- 擅长学科、授课经验、期望单价、可授课区域、各类认证展示。

#### F5 筛选检索
- 按科目、价格区间、是否资质认证、距离排序（距离可用地点字符串模糊匹配或经纬度近似）。

#### F6 投递意向
- 家教向家长投递简历（生成一条 Application 记录）。
- 家长在"我的需求"详情查看候选人列表，可接受/拒绝。

#### F7 简易在线聊天系统
- 留言对话，双方可收发文本消息，按会话（conversation）组织。
- 消息后台持久化保存（安全模块依赖）。

#### F8 评价体系
- 课程结束后双向互评（评分 + 文字）。
- 评价对外公开展示在家教简历主页。

### ✅ 拓展功能（有时间实现，强化创新点）

#### F9 阿里百炼大模型接入（可插拔增值模块）
- **必须可降级**：AI 接口故障时整套业务系统依旧可用。
- F9.1 AI 自动解析家教简历 → 提取擅长科目、优势标签。
- F9.2 根据家长需求文本 → 智能匹配推送合适家教。
- F9.3 自动规整家长零散文字需求 → 生成标准化需求表单。

#### F10 平台安全机制【答辩重大加分项，必须实现】

> 这是本项目区别于普通校园系统的最大亮点，**不可省略**。

- **F10.1 隐私保护隔离**
  - 手机号、详细家庭地址**不在聊天界面直接明文展示**（脱敏：138****1234）。
  - 双方初步沟通达成意向后，系统弹窗提示："线下见面谨慎交换联系方式"。
- **F10.2 线下授课安全指引弹窗**
  - 双方确认试讲前**强制弹出**安全须知：
    - 优先选择公共场所（图书馆、咖啡店）初次试讲
    - 不建议独自上门；建议家长全程陪同
    - 留存沟通记录
  - 用户必须勾选"已阅读并知悉"方可继续。
- **F10.3 沟通内容日志留存**
  - 聊天记录后台持久保存，出现纠纷可溯源（管理员可查）。
- **F10.4 违规管控**
  - 管理员可下架违规需求、封禁恶意账号。
  - 用户举报入口（对需求/家教/消息发起举报）。

#### F11 订单预约草稿
- 双方沟通达成一致后，可在线生成简易电子协议：课时价格、授课时间、授课形式，留存约定记录。

---

## 五、鸿蒙工程结构建议

```
CampusTutor/                          # 鸿蒙工程根目录（DevEco Studio 打开此目录）
├── AppScope/
│   └── app.json5
├── entry/
│   ├── src/main/
│   │   ├── ets/
│   │   │   ├── entryability/
│   │   │   │   └── EntryAbility.ets        # Stage 模型 UIAbility
│   │   │   ├── pages/                       # 页面
│   │   │   │   ├── Login.ets
│   │   │   │   ├── Register.ets
│   │   │   │   ├── Home.ets                  # 首页 Tab
│   │   │   │   ├── DemandList.ets            # 需求列表/筛选
│   │   │   │   ├── DemandDetail.ets
│   │   │   │   ├── PublishDemand.ets
│   │   │   │   ├── TutorList.ets             # 家教列表
│   │   │   │   ├── TutorDetail.ets           # 家教简历主页
│   │   │   │   ├── ChatList.ets
│   │   │   │   ├── Chat.ets                  # 聊天页（脱敏展示）
│   │   │   │   ├── MyApplications.ets        # 我投递的
│   │   │   │   ├── MyCandidates.ets           # 家长看候选人
│   │   │   │   ├── Certification.ets         # 资质上传
│   │   │   │   ├── Profile.ets
│   │   │   │   ├── OrderDraft.ets            # 电子协议草稿
│   │   │   │   ├── SafetyNotice.ets          # 安全须知弹窗页
│   │   │   │   ├── Report.ets                 # 举报入口
│   │   │   │   └── Admin.ets                  # 管理后台
│   │   │   ├── components/                    # 复用组件（卡片、标签、弹窗）
│   │   │   ├── api/                           # HTTP 封装
│   │   │   │   ├── http.ts
│   │   │   │   └── endpoints.ts
│   │   │   ├── model/                         # 数据类型
│   │   │   ├── store/                         # preferences 封装
│   │   │   └── utils/
│   │   └── resources/                         # 图片/字符串/颜色
│   └── module.json5
└── build-profile.json5
```

后端单独一个目录 `backend/`：
```
backend/
├── app.py                  # Flask 入口
├── models.py               # SQLAlchemy 模型
├── db_init.py              # 建表 + 种子数据
├── routes/                 # 按模块拆分蓝图
├── ai/                     # 百炼调用，可插拔
│   └── bailian.py
├── requirements.txt
└── tutor.db                # 运行后生成
```

---

## 六、数据库表设计建议（SQLite）

- `users`（id, phone, password, nickname, role[parent|tutor|admin], school, created_at, status[normal|banned]）
- `tutor_profiles`（user_id, subjects, experience, price_min, price_max, region, intro）
- `certifications`（id, tutor_id, type[student|degree|cet4|teacher], file_path, status[pending|approved|rejected], reviewed_by, created_at）
- `demands`（id, parent_id, grade, subject, price_min, price_max, location, mode[online|offline], schedule, description, status[open|matched|closed], created_at）
- `applications`（id, demand_id, tutor_id, status[pending|accepted|rejected], created_at）
- `conversations`（id, parent_id, tutor_id, created_at）
- `messages`（id, conversation_id, sender_id, content, created_at, is_flagged）
- `orders`（id, demand_id, tutor_id, parent_id, price, schedule, mode, status[draft|confirmed], created_at）
- `reviews`（id, order_id, from_user, to_user, score, comment, created_at）
- `reports`（id, reporter_id, target_type, target_id, reason, status[pending|handled], created_at）
- `safety_acknowledgements`（id, user_id, demand_id, tutor_id, ack_text, created_at）  # 安全须知已读留痕

---

## 七、API 接口设计建议（REST）

```
POST   /api/auth/register
POST   /api/auth/login
GET    /api/users/me
PUT    /api/tutors/profile
POST   /api/tutors/certifications                 # 上传证件
GET    /api/tutors/certifications
POST   /api/demands
GET    /api/demands?subject=&price_min=&price_max=&certified=&sort=
GET    /api/demands/:id
POST   /api/demands/:id/applications             # 家教投递
GET    /api/demands/:id/applications             # 家长看候选人
PATCH  /api/applications/:id                     # 接受/拒绝
GET    /api/conversations
POST   /api/conversations/:id/messages
GET    /api/conversations/:id/messages
POST   /api/orders                               # 生成电子协议
POST   /api/reviews
POST   /api/reports
POST   /api/safety/acknowledge                   # 安全须知已读
# 管理员
GET    /api/admin/certifications/pending
PATCH  /api/admin/certifications/:id
POST   /api/admin/demands/:id/takedown
POST   /api/admin/users/:id/ban
# AI（可插拔）
POST   /api/ai/parse-resume
POST   /api/ai/match
POST   /api/ai/normalize-demand
```

---

## 八、UI / UX 要求

- 使用 ArkTS 声明式 UI，组件化，避免单文件超长。
- 配色：清新校园风（蓝白主色 + 橙色强调），暗色模式可选不强制。
- **身份选择 UI**：注册页家长/家教选择控件使用**大卡片单选 + 图标 + 文案说明**（家长卡片：孩子需要辅导；家教卡片：我想接家教），**禁用下拉框/单行 Radio**，确保用户第一眼明确两条入口。
- **首页分流**：家长端与家教端底部 Tab 数组按 role 动态生成，家长看不到"投递意向"、家教看不到"发布需求"，从视觉上区分两端。
- 关键状态视觉化：【已认证】金色徽标；【未认证投递】按钮置灰 + 提示。
- 列表使用 `List` + `LazyForEach` 优化性能。
- 聊天页消息气泡区分发送方；联系方式字段统一脱敏渲染。
- 安全须知弹窗为**模态全屏**，必须勾选确认才能关闭。

---

## 九、评分维度（众测AI 自检 & 评委评分通用）

> 每个维度按 0–10 分自评，并在交付文档中给出扣分点说明。

| 维度 | 权重 | 评分要点 |
|------|------|----------|
| **D1 功能完整性** | 20% | 8 项核心功能是否全部闭环可演示（注册→发布→投递→聊天→评价全流程跑通）；缺一项即扣分。 |
| **D2 鸿蒙原生规范度** | 15% | 是否真 ArkTS Stage 模型；是否正确使用 UIAbility、页面路由、`@ohos.net.http`、`@ohos.data.preferences`、`@ohos.multimedia.imagePicker` 等系统能力；非 H5 套壳。 |
| **D3 可运行性** | 15% | DevEco Studio 一键编译通过；模拟器/真机可启动；后端 `python app.py` 起服务；端云联调无报错。 |
| **D4 安全机制实现度** | 15% | 隐私脱敏、线下安全弹窗强制确认、聊天留痕、违规管控、举报入口是否齐全且真实生效（非占位 UI）。 |
| **D5 AI 模块可插拔性** | 10% | 百炼调用失败是否优雅降级；AI 失效时核心业务是否仍完整可用；解析/匹配/规整三功能是否真实调用而非 mock 假返回。 |
| **D6 代码质量** | 10% | 目录结构清晰；前后端分层；无硬编码密钥泄露；异常处理；命名规范；无大量重复代码。 |
| **D7 数据与接口规范** | 5% | 表结构合理有外键；接口 RESTful；统一错误码与返回结构；分页/鉴权中间件。 |
| **D8 UI / UX 完成度** | 5% | 配色统一；列表流畅；空状态/加载/错误态齐全；关键交互有反馈。 |
| **D9 文档与可演示性** | 5% | 提供 README 启动步骤、演示账号、演示脚本；附带测试数据；可一键复现。 |
| **D10 创新与亮点表达** | 5% | 鸿蒙原生 + 安全体系两大差异化亮点是否在代码与文档中显性体现。 |

**总分 = Σ(维度分 × 权重)。** 众测AI 交付时须附自评表。

---

## 十、验收标准（Definition of Done）

交付物必须同时满足：

1. **可编译**：DevEco Studio 打开 `CampusTutor/` 工程，Build → Build Hap(s) 成功，无 Error。
2. **可运行**：在 HarmonyOS 模拟器或真机安装后，App 可启动到首页，无闪退。
3. **可联调**：后端 `python app.py` 启动，App 登录请求成功返回 token。
4. **核心闭环**：用两个演示账号（1 家长 + 1 家教）完整走完：注册 → 家教上传证件（管理员审核通过）→ 家长发布需求 → 家教投递 → 家长接受 → 双方聊天（联系方式脱敏可见）→ 安全须知弹窗确认 → 生成电子协议 → 互评。
5. **安全生效**：聊天页手机号脱敏展示；未认证家教投递按钮置灰；安全须知未勾选无法继续；管理员可下架需求/封号；举报入口可提交。
6. **AI 降级**：断网或百炼 Key 缺失时，AI 匹配页显示"AI 服务暂不可用，已切换规则匹配"，业务不中断。
7. **文档**：README 含启动命令、演示账号、演示流程、目录说明、自评表。

---

## 十一、开发优先级（众测AI 请严格按序实现）

1. **阶段 A · 工程骨架**：鸿蒙工程 + Flask + SQLite 建表 + 登录注册跑通。
2. **阶段 B · 核心数据流**：家教简历 + 资质上传 + 管理员审核 + 需求发布 + 列表筛选。
3. **阶段 C · 撮合闭环**：投递意向 + 候选人查看 + 接受/拒绝。
4. **阶段 D · 沟通与评价**：聊天（脱敏）+ 安全须知弹窗 + 互评 + 电子协议草稿。
5. **阶段 E · 安全管控**：举报入口 + 管理员下架/封号 + 聊天留痕可查。
6. **阶段 F · AI 模块**：百炼三功能（可插拔 + 降级）。
7. **阶段 G · 收尾**：种子数据、演示脚本、README、自评表。

---

## 十二、给众测AI 的最终指令（Prompt 正文）

```
你是 OpenHarmony ArkTS + Python Flask 全栈工程师。请基于本提示词文档，交付一个可运行的鸿蒙原生 App「校园家教智能匹配平台」。

硬性要求：
1. 鸿蒙工程必须为 ArkTS Stage 模型（API 9+），禁止 H5 套壳/小程序。
2. 必须交付一个 DevEco Studio 可直接 File → Open 加载的完整工程目录 `CampusTutor/`（含 AppScope/entry/build-profile.json5/oh-package.json5），Build → Build Hap(s) 无 Error。
3. 后端 Flask + SQLite，`python app.py` 可独立启动，含建表与种子数据脚本。
4. 注册必须强制身份选择（家长/家教二选一，大卡片单选 UI），登录后按 role 流到不同首页与功能入口，未授权功能对当前身份隐藏，后端接口校验身份权限。
5. 实现「四、完整功能清单」中全部核心功能（F1–F8）与安全机制（F10.1–F10.4）。
6. AI 模块（F9）以可插拔方式实现，失败必须降级为规则匹配，核心业务不中断。
7. 必须满足「十、验收标准」全部 7 条。
8. 按「十一、开发优先级」顺序实现，每阶段产出可编译可运行的中间版本。
9. 交付时附 README（启动步骤 + 演示账号 + 演示脚本）与「九、评分维度」自评表。
10. 安全机制是本项目最大亮点，必须真实生效而非占位 UI。

立即开始，先输出工程目录结构与第一阶段可运行版本（含注册身份选择 + 登录后按身份分流首页）。
```

---

## 十三、项目短板（答辩预案，众测AI 无需实现，仅提示）

- **资金交易不介入**：平台只做信息撮合，不搭建线上支付；课时费双方线下协商。
- **证件仅线上图片初审**：无联网官方核验接口；页面明确标注"平台仅做初步展示，家长自主甄别"。

---

## 十四、差异化亮点（用于答辩 & PPT，众测AI 在 README 中显性体现）

1. 基于 OpenHarmony 原生开发，契合开源鸿蒙生态。
2. 多层资质信任体系（学籍/教资等上传审核）。
3. 内置线下授课安全防护机制（隐私隔离 + 安全提示 + 聊天留痕）。
4. 融合大模型实现智能供需匹配（可插拔 + 降级）。
5. 去中介、免费轻量化对接渠道，降低双方经济成本。
