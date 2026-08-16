// preferences 封装：登录态持久化 + 内存缓存
import preferences from '@ohos.data.preferences';
import type common from '@ohos.app.ability.common';
import type { Role, LoginInfo } from '../model';

const STORE_NAME = 'campus_tutor';

let prefs: preferences.Preferences | null = null;
let memToken: string = '';
let memRole: Role | null = null;
let memUserId: number = 0;
let memNickname: string = '';

export async function initStore(context: common.UIAbilityContext): Promise<void> {
  try {
    prefs = await preferences.getPreferences(context, STORE_NAME);
    memToken = (await prefs.get('token', '')) as string;
    const roleStr = (await prefs.get('role', '')) as string;
    memRole = roleStr ? (roleStr as Role) : null;
    memUserId = (await prefs.get('user_id', 0)) as number;
    memNickname = (await prefs.get('nickname', '')) as string;
  } catch (e) {
    console.error(`[store] init failed: ${JSON.stringify(e)}`);
  }
}

export function getAuthToken(): string {
  return memToken;
}

export function getRole(): Role | null {
  return memRole;
}

export function getUserId(): number {
  return memUserId;
}

export function getNickname(): string {
  return memNickname;
}

export function isLoggedIn(): boolean {
  return memToken.length > 0 && memRole !== null;
}

export async function saveLoginInfo(info: LoginInfo): Promise<void> {
  memToken = info.token;
  memRole = info.role;
  memUserId = info.userId;
  memNickname = info.nickname;
  if (prefs) {
    await prefs.put('token', info.token);
    await prefs.put('role', info.role);
    await prefs.put('user_id', info.userId);
    await prefs.put('nickname', info.nickname);
    await prefs.flush();
  }
}

export async function clearLoginInfo(): Promise<void> {
  memToken = '';
  memRole = null;
  memUserId = 0;
  memNickname = '';
  if (prefs) {
    await prefs.delete('token');
    await prefs.delete('role');
    await prefs.delete('user_id');
    await prefs.delete('nickname');
    await prefs.flush();
  }
}

// 演示模式：免登录直接以指定身份进入主页（不连后端）
interface DemoUser {
  id: number;
  nickname: string;
}

const DEMO_USERS: Record<string, DemoUser> = {
  'parent': { id: 1, nickname: '演示家长' } as DemoUser,
  'tutor': { id: 2, nickname: '演示家教' } as DemoUser,
  'admin': { id: 0, nickname: '管理员' } as DemoUser
};

export async function enterAsDemo(role: Role): Promise<void> {
  const u = DEMO_USERS[role];
  const info: LoginInfo = {
    token: 'demo-' + role + '-' + Date.now(),
    role: role,
    userId: u.id,
    nickname: u.nickname
  };
  await saveLoginInfo(info);
}
