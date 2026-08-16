// 业务 API 服务层 - 集中调用后端接口
import { get, post, put } from './http';
import { Endpoints } from './endpoints';
import type {
  LoginInfo, UserInfo, TutorProfile, Certification, Demand, Application,
  Conversation, Message, Order, Review, Report, Role, CertType,
  RegisterPayload, LoginPayload, UploadCertPayload, ListDemandsParams,
  StatusPayload, SendMessagePayload, CreateReviewPayload, CreateReportPayload,
  AckSafetyPayload, PostConversationPayload, CreateOrderPayload,
  AiParseResumeResult, AiMatchResultItem, AiNormalizeDemandResult,
  TextPayload, AiMatchPayload
} from '../model';

// ========== 认证 ==========
export function register(payload: RegisterPayload): Promise<LoginInfo> {
  return post<LoginInfo>(Endpoints.REGISTER, payload);
}

export function login(phone: string, password: string): Promise<LoginInfo> {
  const payload: LoginPayload = { phone: phone, password: password };
  return post<LoginInfo>(Endpoints.LOGIN, payload);
}

export function getMe(): Promise<UserInfo> {
  return get<UserInfo>(Endpoints.ME);
}

// ========== 家教简历与认证 ==========
export function updateTutorProfile(payload: Partial<TutorProfile>): Promise<TutorProfile> {
  return put<TutorProfile>(Endpoints.TUTOR_PROFILE, payload);
}

export function getTutorProfile(tutorId?: number): Promise<TutorProfile> {
  const path = tutorId ? `${Endpoints.TUTOR_PROFILE}?tutor_id=${tutorId}` : Endpoints.TUTOR_PROFILE;
  return get<TutorProfile>(path);
}

export function getCertifications(): Promise<Certification[]> {
  return get<Certification[]>(Endpoints.CERTIFICATIONS);
}

export function uploadCertification(type: CertType, base64: string): Promise<Certification> {
  const payload: UploadCertPayload = { type: type, file_path: base64 };
  return post<Certification>(Endpoints.CERTIFICATIONS, payload);
}

// ========== 需求 ==========
export function createDemand(payload: Partial<Demand>): Promise<Demand> {
  return post<Demand>(Endpoints.DEMANDS, payload);
}

export function listDemands(params?: ListDemandsParams): Promise<Demand[]> {
  let qs = '';
  if (params) {
    const arr: string[] = [];
    if (params.subject) arr.push(`subject=${encodeURIComponent(params.subject)}`);
    if (params.price_min !== undefined) arr.push(`price_min=${params.price_min}`);
    if (params.price_max !== undefined) arr.push(`price_max=${params.price_max}`);
    if (params.certified !== undefined) arr.push(`certified=${params.certified}`);
    if (params.sort) arr.push(`sort=${params.sort}`);
    if (arr.length > 0) qs = '?' + arr.join('&');
  }
  return get<Demand[]>(Endpoints.DEMANDS + qs);
}

export function getDemand(id: number): Promise<Demand> {
  return get<Demand>(Endpoints.DEMAND(id));
}

// ========== 投递 ==========
export function applyDemand(demandId: number): Promise<Application> {
  return post<Application>(Endpoints.DEMAND_APPLICATIONS(demandId));
}

export function listCandidates(demandId: number): Promise<Application[]> {
  return get<Application[]>(Endpoints.DEMAND_APPLICATIONS(demandId));
}

export function patchApplication(id: number, status: string): Promise<Application> {
  const payload: StatusPayload = { status: status };
  return put<Application>(Endpoints.APPLICATION(id), payload);
}

// ========== 会话与消息 ==========
export function listConversations(): Promise<Conversation[]> {
  return get<Conversation[]>(Endpoints.CONVERSATIONS);
}

export function listMessages(conversationId: number): Promise<Message[]> {
  return get<Message[]>(Endpoints.CONVERSATION_MESSAGES(conversationId));
}

export function sendMessage(conversationId: number, content: string): Promise<Message> {
  const payload: SendMessagePayload = { content: content };
  return post<Message>(Endpoints.CONVERSATION_MESSAGES(conversationId), payload);
}

// ========== 订单与评价 ==========
export function createOrder(payload: CreateOrderPayload): Promise<Order> {
  return post<Order>(Endpoints.ORDERS, payload);
}

export function listOrders(): Promise<Order[]> {
  return get<Order[]>(Endpoints.ORDERS);
}

export function createReview(payload: CreateReviewPayload): Promise<Review> {
  return post<Review>(Endpoints.REVIEWS, payload);
}

export function listReviewsByTutor(tutorId: number): Promise<Review[]> {
  return get<Review[]>(`/api/tutors/${tutorId}/reviews`);
}

// ========== 举报 ==========
export function createReport(payload: CreateReportPayload): Promise<Report> {
  return post<Report>(Endpoints.REPORTS, payload);
}

// ========== 安全 ==========
export function ackSafety(payload: AckSafetyPayload): Promise<void> {
  return post<void>(Endpoints.SAFETY_ACK, payload);
}

// ========== 管理员 ==========
export function adminListPendingCerts(): Promise<Certification[]> {
  return get<Certification[]>(Endpoints.ADMIN_CERT_PENDING);
}

export function adminReviewCert(id: number, status: string): Promise<Certification> {
  const payload: StatusPayload = { status: status };
  return put<Certification>(Endpoints.ADMIN_CERT(id), payload);
}

export function adminTakedownDemand(id: number): Promise<void> {
  return post<void>(Endpoints.ADMIN_DEMAND_TAKEDOWN(id));
}

export function adminBanUser(id: number): Promise<void> {
  return post<void>(Endpoints.ADMIN_USER_BAN(id));
}

// ========== AI（可插拔） ==========
export function aiParseResume(text: string): Promise<AiParseResumeResult> {
  const payload: TextPayload = { text: text };
  return post<AiParseResumeResult>(Endpoints.AI_PARSE_RESUME, payload);
}

export function aiMatch(demandText: string): Promise<AiMatchResultItem[]> {
  const payload: AiMatchPayload = { demand_text: demandText };
  return post<AiMatchResultItem[]>(Endpoints.AI_MATCH, payload);
}

export function aiNormalizeDemand(text: string): Promise<AiNormalizeDemandResult> {
  const payload: TextPayload = { text: text };
  return post<AiNormalizeDemandResult>(Endpoints.AI_NORMALIZE_DEMAND, payload);
}
