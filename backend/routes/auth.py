# 认证路由：注册 / 登录
import secrets
from flask import Blueprint, request
from models import db, User
from utils.response import ok, fail, ERR_PARAMS, ERR_DUPLICATE, ERR_NOT_FOUND
from utils.auth import login_required

bp = Blueprint("auth", __name__, url_prefix="/api/auth")


@bp.route("/register", methods=["POST"])
def register():
    data = request.get_json(silent=True) or {}
    phone = (data.get("phone") or "").strip()
    password = data.get("password") or ""
    nickname = (data.get("nickname") or "").strip()
    school = (data.get("school") or "").strip()
    role = (data.get("role") or "").strip()

    if not phone or not password or not nickname or not role:
        return fail(ERR_PARAMS, "参数不完整")
    if role not in ("parent", "tutor", "admin"):
        return fail(ERR_PARAMS, "role 必须为 parent/tutor/admin")
    if role == "tutor" and not school:
        return fail(ERR_PARAMS, "家教注册需填写学校")

    if User.query.filter_by(phone=phone).first():
        return fail(ERR_DUPLICATE, "该手机号已注册")

    token = secrets.token_hex(16)
    user = User(
        phone=phone,
        password=password,
        nickname=nickname,
        role=role,
        school=school or None,
        token=token,
        status="normal",
    )
    db.session.add(user)
    db.session.commit()
    return ok({
        "token": token,
        "role": role,
        "userId": user.id,
        "nickname": user.nickname,
    })


@bp.route("/login", methods=["POST"])
def login():
    data = request.get_json(silent=True) or {}
    phone = (data.get("phone") or "").strip()
    password = data.get("password") or ""
    if not phone or not password:
        return fail(ERR_PARAMS, "参数不完整")

    user = User.query.filter_by(phone=phone).first()
    if not user or user.password != password:
        return fail(ERR_NOT_FOUND, "手机号或密码错误")
    if user.status == "banned":
        return fail(1403, "账号已被封禁")

    # 每次登录刷新 token
    token = secrets.token_hex(16)
    user.token = token
    db.session.commit()
    return ok({
        "token": token,
        "role": user.role,
        "userId": user.id,
        "nickname": user.nickname,
    })
