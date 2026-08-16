# 统一响应封装
# 成功: {"code": 0, "msg": "ok", "data": ...}
# 失败: {"code": <非0>, "msg": <描述>, "data": None}
from flask import jsonify


def ok(data=None, msg="ok"):
    """成功响应"""
    return jsonify({"code": 0, "msg": msg, "data": data})


def fail(code, msg, data=None):
    """失败响应

    业务错误用 1001+；鉴权失败 1401；权限不足 1403
    """
    return jsonify({"code": code, "msg": msg, "data": data})


# 业务错误码约定
ERR_PARAMS = 1001          # 参数错误
ERR_NOT_FOUND = 1002       # 资源不存在
ERR_DUPLICATE = 1003       # 重复操作
ERR_FORBIDDEN_OP = 1004    # 业务禁止操作
ERR_UNAUTHORIZED = 1401    # 鉴权失败
ERR_FORBIDDEN = 1403       # 权限不足
