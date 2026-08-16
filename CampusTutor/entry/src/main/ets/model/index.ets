// 数据模型定义 - 校园家教平台
// API 统一返回结构 { code, msg, data }

export interface ApiResponse<T> {
  code: number;
  msg: string;
  data: T | null;
}

export type Role = 'parent' | 'tutor' | 'admin';

export type CertType = 'student' | 'degree' | 'cet4' | 'teacher';
export type CertStatus = 'pending' | 'approved' | 'rejected';
export type DemandStatus = 'open' | 'matched' | 'closed';
export type ApplicationStatus = 'pending' | 'accepted' | 'rejected';
export type TeachMode = 'online' | 'offline';
export type OrderStatus = 'draft' | 'confirmed';
export type UserStatus = 'normal' | 'banned';

// 用 Record<string, string> 代替 Record<UnionType, string>（ArkTS 严格模式不支持联合类型键的 Record 字面量）
export const CERT_TYPE_LABEL: Record<string, string> = {
  'student': '学籍证明',
  'degree': '学历证书',
  'cet4': '四六级证书',
  'teacher': '教资证书'
};

export const CERT_STATUS_LABEL: Record<string, string> = {
  'pending': '待审核',
  'approved': '已通过',
  'rejected': '已驳回'
};

export const DEMAND_STATUS_LABEL: Record<string, string> = {
  'open': '发布中',
  'matched': '已撮合',
  'closed': '已关闭'
};

export const APPLICATION_STATUS_LABEL: Record<string, string> = {
  'pending': '待处理',
  'accepted': '已接受',
  'rejected': '已拒绝'
};

export const ORDER_STATUS_LABEL: Record<string, string> = {
  'draft': '草稿',
  'confirmed': '已确认'
};

export interface LoginInfo {
  token: string;
  role: Role;
  userId: number;
  nickname: string;
}

export interface UserInfo {
  id: number;
  phone: string;
  nickname: string;
  role: Role;
  school: string;
  status: UserStatus;
  created_at?: string;
}

export interface TutorProfile {
  user_id: number;
  nickname: string;
  school: string;
  subjects: string;
  experience: string;
  price_min: number;
  price_max: number;
  region: string;
  intro: string;
  certified: boolean;
}

export interface Certification {
  id: number;
  tutor_id: number;
  type: CertType;
  file_path: string;
  status: CertStatus;
  created_at: string;
}

export interface Demand {
  id: number;
  parent_id: number;
  parent_nickname?: string;
  grade: string;
  subject: string;
  price_min: number;
  price_max: number;
  location: string;
  mode: TeachMode;
  schedule: string;
  description: string;
  status: DemandStatus;
  created_at: string;
  applied?: boolean;
}

export interface Application {
  id: number;
  demand_id: number;
  tutor_id: number;
  tutor_nickname?: string;
  tutor_school?: string;
  tutor_certified?: boolean;
  status: ApplicationStatus;
  created_at: string;
}

export interface Conversation {
  id: number;
  parent_id: number;
  tutor_id: number;
  parent_nickname?: string;
  tutor_nickname?: string;
  last_message?: string;
  last_time?: string;
}

export interface Message {
  id: number;
  conversation_id: number;
  sender_id: number;
  content: string;
  created_at: string;
  is_flagged?: boolean;
}

export interface Order {
  id: number;
  demand_id: number;
  tutor_id: number;
  parent_id: number;
  price: number;
  schedule: string;
  mode: TeachMode;
  status: OrderStatus;
  created_at: string;
}

export interface Review {
  id: number;
  order_id: number;
  from_user: number;
  to_user: number;
  score: number;
  comment: string;
  created_at: string;
  from_nickname?: string;
  to_nickname?: string;
}

export interface Report {
  id: number;
  reporter_id: number;
  target_type: string;
  target_id: number;
  reason: string;
  status: string;
  created_at: string;
}

// ========== service.ets 所需的 payload / return 接口 ==========
// ArkTS 不允许内联对象字面量作为类型（arkts-no-obj-literals-as-types）

export interface RegisterPayload {
  phone: string;
  password: string;
  nickname: string;
  school: string;
  role: Role;
}

export interface LoginPayload {
  phone: string;
  password: string;
}

export interface UploadCertPayload {
  type: CertType;
  file_path: string;
}

export interface ListDemandsParams {
  subject?: string;
  price_min?: number;
  price_max?: number;
  certified?: boolean;
  sort?: string;
}

export interface StatusPayload {
  status: string;
}

export interface SendMessagePayload {
  content: string;
}

export interface CreateReviewPayload {
  order_id: number;
  to_user: number;
  score: number;
  comment: string;
}

export interface CreateReportPayload {
  target_type: string;
  target_id: number;
  reason: string;
}

export interface AckSafetyPayload {
  demand_id?: number;
  tutor_id?: number;
  ack_text: string;
}

export interface PostConversationPayload {
  other_user_id: number;
}

export interface CreateOrderPayload {
  demand_id?: number;
  tutor_id: number;
  price: number;
  schedule: string;
  mode: TeachMode;
}

export interface AiParseResumeResult {
  subjects: string;
  tags: string;
}

export interface AiMatchResultItem {
  tutor_id: number;
  nickname: string;
  reason: string;
}

export interface AiNormalizeDemandResult {
  grade?: string;
  subject?: string;
  price_min?: number;
  price_max?: number;
  location?: string;
  mode?: TeachMode;
  schedule?: string;
  description?: string;
}

export interface TextPayload {
  text: string;
}

export interface AiMatchPayload {
  demand_text: string;
}
