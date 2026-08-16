# 举报路由
from flask import Blueprint, request
from models import db, Report
from utils.response import ok, fail, ERR_PARAMS
from utils.auth import login_required

bp = Blueprint("reports", __name__, url_prefix="/api/reports")


@bp.route("", methods=["POST"])
@login_required
def create_report():
    from flask import g
    data = request.get_json(silent=True) or {}
    target_type = (data.get("target_type") or "").strip()
    target_id = data.get("target_id")
    reason = (data.get("reason") or "").strip()
    if not target_type or target_id is None or not reason:
        return fail(ERR_PARAMS, "参数不完整")
    report = Report(
        reporter_id=g.current_user.id,
        target_type=target_type,
        target_id=target_id,
        reason=reason,
        status="pending",
    )
    db.session.add(report)
    db.session.commit()
    return ok(report.to_dict())
