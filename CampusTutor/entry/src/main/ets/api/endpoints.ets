// API 路径常量集中定义
export class Endpoints {
  // 认证
  static readonly REGISTER = '/api/auth/register';
  static readonly LOGIN = '/api/auth/login';
  static readonly ME = '/api/users/me';

  // 家教简历与认证
  static readonly TUTOR_PROFILE = '/api/tutors/profile';
  static readonly CERTIFICATIONS = '/api/tutors/certifications';

  // 需求
  static readonly DEMANDS = '/api/demands';
  static readonly DEMAND = (id: number) => `/api/demands/${id}`;
  static readonly DEMAND_APPLICATIONS = (id: number) => `/api/demands/${id}/applications`;

  // 投递
  static readonly APPLICATION = (id: number) => `/api/applications/${id}`;

  // 会话与消息
  static readonly CONVERSATIONS = '/api/conversations';
  static readonly CONVERSATION_MESSAGES = (id: number) => `/api/conversations/${id}/messages`;

  // 订单与评价
  static readonly ORDERS = '/api/orders';
  static readonly REVIEWS = '/api/reviews';

  // 举报
  static readonly REPORTS = '/api/reports';

  // 安全
  static readonly SAFETY_ACK = '/api/safety/acknowledge';

  // 管理员
  static readonly ADMIN_CERT_PENDING = '/api/admin/certifications/pending';
  static readonly ADMIN_CERT = (id: number) => `/api/admin/certifications/${id}`;
  static readonly ADMIN_DEMAND_TAKEDOWN = (id: number) => `/api/admin/demands/${id}/takedown`;
  static readonly ADMIN_USER_BAN = (id: number) => `/api/admin/users/${id}/ban`;

  // AI 可插拔
  static readonly AI_PARSE_RESUME = '/api/ai/parse-resume';
  static readonly AI_MATCH = '/api/ai/match';
  static readonly AI_NORMALIZE_DEMAND = '/api/ai/normalize-demand';
}
