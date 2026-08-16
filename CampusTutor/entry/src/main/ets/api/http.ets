// HTTP 封装：统一处理 token、解析 ApiResponse
import http from '@ohos.net.http';
import { BASE_URL, HTTP_TIMEOUT } from './config';
import { getAuthToken } from '../store';
import type { ApiResponse } from '../model';

export class ApiError extends Error {
  code: number;
  constructor(code: number, msg: string) {
    super(msg);
    this.code = code;
  }
}

async function request<T>(method: http.RequestMethod, path: string, data?: object): Promise<T> {
  const url = BASE_URL + path;
  const httpRequest = http.createHttp();
  try {
    const token = getAuthToken();
    const header: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    if (token) {
      header['Authorization'] = `Bearer ${token}`;
    }
    const options: http.HttpRequestOptions = {
      method,
      header,
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: HTTP_TIMEOUT,
      readTimeout: HTTP_TIMEOUT,
      usingCache: false
    };
    if (data !== undefined) {
      options.extraData = JSON.stringify(data);
    }
    const resp = await httpRequest.request(url, options);
    const code = resp.responseCode;
    if (code < 200 || code >= 300) {
      throw new ApiError(code, `网络错误 ${code}`);
    }
    let body: ApiResponse<T>;
    const text = resp.result as string;
    if (!text) {
      throw new ApiError(-1, '空响应');
    }
    body = JSON.parse(text) as ApiResponse<T>;
    if (body.code !== 0 && body.code !== 200) {
      throw new ApiError(body.code, body.msg || '请求失败');
    }
    return body.data as T;
  } finally {
    httpRequest.destroy();
  }
}

export function get<T>(path: string): Promise<T> {
  return request<T>(http.RequestMethod.GET, path);
}

export function post<T>(path: string, data?: object): Promise<T> {
  return request<T>(http.RequestMethod.POST, path, data);
}

export function put<T>(path: string, data?: object): Promise<T> {
  return request<T>(http.RequestMethod.PUT, path, data);
}

// 注意：ArkTS http.RequestMethod 枚举无 PATCH，用 PUT 代替；后端对应路由已改为接受 PUT
export function patch<T>(path: string, data?: object): Promise<T> {
  return request<T>(http.RequestMethod.PUT, path, data);
}
