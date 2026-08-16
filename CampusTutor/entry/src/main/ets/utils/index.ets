// 工具函数
import promptAction from '@ohos.promptAction';

// 手机号脱敏：138****1234
export function maskPhone(phone: string): string {
  if (!phone || phone.length < 7) {
    return phone || '';
  }
  if (phone.length === 11) {
    return `${phone.substring(0, 3)}****${phone.substring(7)}`;
  }
  return `${phone.substring(0, 2)}****${phone.substring(phone.length - 2)}`;
}

// 详细地址脱敏：北京市海淀区中关村大街1号 -> 北京市海淀区****
export function maskLocation(loc: string): string {
  if (!loc) return '';
  if (loc.length <= 4) return loc;
  return loc.substring(0, 4) + '****';
}

// 价格区间
export function formatPrice(min: number, max: number): string {
  if (!min && !max) return '面议';
  if (min && max) return `${min}-${max}元/课时`;
  if (min) return `≥${min}元/课时`;
  return `≤${max}元/课时`;
}

// ISO 时间格式化
export function formatTime(iso: string): string {
  if (!iso) return '';
  try {
    const d = new Date(iso);
    if (isNaN(d.getTime())) return iso;
    const pad = (n: number): string => n < 10 ? `0${n}` : `${n}`;
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
  } catch (e) {
    return iso;
  }
}

// 全局 toast
export function toast(msg: string): void {
  try {
    promptAction.showToast({ message: msg, duration: 2000 });
  } catch (e) {
    console.error(`[toast] ${msg}`);
  }
}

// 错误提示
export function toastError(err: Error | string): void {
  const msg = typeof err === 'string' ? err : (err.message || '操作失败');
  toast(msg);
}

// 空值检查
export function isEmpty(v: string | null | undefined): boolean {
  return v === null || v === undefined || v === '';
}
