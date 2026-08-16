# 安全路由：安全须知确认留痕 + 须知清单
from flask import Blueprint, request
from models import db, SafetyAcknowledgement
from utils.response import ok, fail, ERR_PARAMS
from utils.auth import login_required

bp = Blueprint("safety", __name__, url_prefix="/api/safety")

SAFETY_CHECKLIST = [
    "平台禁止线下首次单独约见，建议选择公共场所或有家长陪同。",
    "请勿在聊天中泄露手机号、家庭住址、身份证号等敏感信息（系统会自动脱敏）。",
    "家教需完成学籍/学历等资质认证后方可接单，请认准认证标识。",
    "费用请通过平台订单流程确认，禁止私下转账，谨防诈骗。",
    "如遇可疑行为或人身安全风险，请立即举报并联系平台管理员。",
    "未成年学生家长应全程参与辅导安排，保障未成年人权益。",
]


@bp.route("/acknowledge", methods=["POST"])
@login_required
def acknowledge():
    from flask import g
    data = request.get_json(silent=True) or {}
    ack_text = (data.get("ack_text") or "").strip()
    if not ack_text:
        return fail(ERR_PARAMS, "ack_text 不能为空")
    ack = SafetyAcknowledgement(
        user_id=g.current_user.id,
        demand_id=data.get("demand_id"),
        tutor_id=data.get("tutor_id"),
        ack_text=ack_text,
    )
    db.session.add(ack)
    db.session.commit()
    return ok(ack.to_dict())


@bp.route("/checklist", methods=["GET"])
def checklist():
    return ok(SAFETY_CHECKLIST)
