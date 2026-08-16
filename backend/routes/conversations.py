# 会话与消息路由（含手机号/地址脱敏）
import re
from flask import Blueprint, request
from models import db, Conversation, Message, User
from utils.response import ok, fail, ERR_PARAMS, ERR_NOT_FOUND
from utils.auth import login_required

bp = Blueprint("conversations", __name__, url_prefix="/api/conversations")

PHONE_RE = re.compile(r"1[3-9]\d{9}")


def mask_content(content):
    """检测并脱敏：11位手机号替换为 138****1234；含'地址'关键词标记"""
    is_flagged = 0
    masked = content
    if PHONE_RE.search(content):
        is_flagged = 1
        masked = PHONE_RE.sub(lambda m: m.group(0)[:3] + "****" + m.group(0)[-4:], masked)
    if "地址" in content or "住址" in content:
        is_flagged = 1
    return masked, is_flagged


def is_participant(conv, user_id):
    return conv.parent_id == user_id or conv.tutor_id == user_id


@bp.route("", methods=["GET"])
@login_required
def list_conversations():
    from flask import g
    uid = g.current_user.id
    convs = (
        Conversation.query.filter(
            (Conversation.parent_id == uid) | (Conversation.tutor_id == uid)
        )
        .order_by(Conversation.id.desc())
        .all()
    )
    return ok([c.to_dict(current_user_id=uid) for c in convs])


@bp.route("", methods=["POST"])
@login_required
def create_conversation():
    from flask import g
    data = request.get_json(silent=True) or {}
    other_user_id = data.get("other_user_id")
    if not other_user_id:
        return fail(ERR_PARAMS, "缺少 other_user_id")
    other = User.query.get(other_user_id)
    if not other:
        return fail(ERR_NOT_FOUND, "对方用户不存在")

    me = g.current_user
    # 自动判断谁是 parent 谁是 tutor
    if me.role == "parent" and other.role == "tutor":
        parent_id, tutor_id = me.id, other.id
    elif me.role == "tutor" and other.role == "parent":
        parent_id, tutor_id = other.id, me.id
    else:
        return fail(ERR_PARAMS, "会话双方需为家长与家教")

    conv = Conversation.query.filter_by(parent_id=parent_id, tutor_id=tutor_id).first()
    if not conv:
        conv = Conversation(parent_id=parent_id, tutor_id=tutor_id)
        db.session.add(conv)
        db.session.commit()
    return ok(conv.to_dict(current_user_id=me.id))


@bp.route("/<int:conv_id>/messages", methods=["GET"])
@login_required
def list_messages(conv_id):
    from flask import g
    conv = Conversation.query.get(conv_id)
    if not conv:
        return fail(ERR_NOT_FOUND, "会话不存在")
    if not is_participant(conv, g.current_user.id):
        return fail(1403, "无权查看该会话")
    messages = Message.query.filter_by(conversation_id=conv_id).order_by(Message.id.asc()).all()
    # 返回时对 content 做脱敏展示（不改变存储）
    result = []
    for m in messages:
        d = m.to_dict()
        masked, _ = mask_content(m.content or "")
        d["content"] = masked
        result.append(d)
    return ok(result)


@bp.route("/<int:conv_id>/messages", methods=["POST"])
@login_required
def send_message(conv_id):
    from flask import g
    conv = Conversation.query.get(conv_id)
    if not conv:
        return fail(ERR_NOT_FOUND, "会话不存在")
    if not is_participant(conv, g.current_user.id):
        return fail(1403, "无权在该会话发言")
    data = request.get_json(silent=True) or {}
    content = data.get("content") or ""
    if not content.strip():
        return fail(ERR_PARAMS, "消息内容不能为空")

    masked, is_flagged = mask_content(content)
    msg = Message(
        conversation_id=conv_id,
        sender_id=g.current_user.id,
        content=masked,
        is_flagged=is_flagged,
    )
    db.session.add(msg)
    db.session.commit()
    return ok(msg.to_dict())
