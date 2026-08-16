# 鉴权装饰器与当前用户获取
import functools
from flask import request, g
from models import User
from utils.response import fail, ERR_UNAUTHORIZED, ERR_FORBIDDEN


def get_current_user():
    """从 Authorization: Bearer <token> 解析当前用户

    返回 User 或 None
    """
    auth_header = request.headers.get("Authorization", "")
    if not auth_header:
        return None
    parts = auth_header.split()
    if len(parts) == 2 and parts[0].lower() == "bearer":
        token = parts[1]
    else:
        # 兼容直接传 token
        token = auth_header.strip()
    if not token:
        return None
    return User.query.filter_by(token=token).first()


def login_required(func):
    """登录校验装饰器"""

    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        user = get_current_user()
        if not user:
            return fail(ERR_UNAUTHORIZED, "请先登录")
        if user.status == "banned":
            return fail(ERR_FORBIDDEN, "账号已被封禁")
        g.current_user = user
        return func(*args, **kwargs)

    return wrapper


def role_required(*roles):
    """角色校验装饰器，可传多个允许角色

    用法: @role_required('parent') 或 @role_required('parent', 'admin')
    """

    def decorator(func):
        @functools.wraps(func)
        @login_required
        def wrapper(*args, **kwargs):
            user = g.current_user
            if user.role not in roles:
                return fail(ERR_FORBIDDEN, "权限不足")
            return func(*args, **kwargs)

        return wrapper

    return decorator
