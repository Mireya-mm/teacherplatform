# 管理员路由（role=admin）
from flask import Blueprint, request
from models import db, Certification, Demand, User, Report
from utils.response import ok, fail, ERR_PARAMS, ERR_NOT_FOUND
from utils.auth import role_required

bp = Blueprint("admin", __name__, url_prefix="/api/admin")


@bp.route("/certifications/pending", methods=["GET"])
@role_required("admin")
def pending_certs():
    certs = Certification.query.filter_by(status="pending").order_by(Certification.id.desc()).all()
    return ok([c.to_dict(include_tutor=True) for c in certs])


@bp.route("/certifications/<int:cert_id>", methods=["PATCH", "PUT"])
@role_required("admin")
def review_cert(cert_id):
    from flask import g
    data = request.get_json(silent=True) or {}
    status = (data.get("status") or "").strip()
    if status not in ("approved", "rejected"):
        return fail(ERR_PARAMS, "status 必须为 approved/rejected")
    cert = Certification.query.get(cert_id)
    if not cert:
        return fail(ERR_NOT_FOUND, "认证记录不存在")
    cert.status = status
    cert.reviewed_by = g.current_user.id
    db.session.commit()
    return ok(cert.to_dict(include_tutor=True))


@bp.route("/demands", methods=["GET"])
@role_required("admin")
def list_all_demands():
    demands = Demand.query.order_by(Demand.id.desc()).all()
    return ok([d.to_dict() for d in demands])


@bp.route("/demands/<int:demand_id>/takedown", methods=["POST"])
@role_required("admin")
def takedown_demand(demand_id):
    demand = Demand.query.get(demand_id)
    if not demand:
        return fail(ERR_NOT_FOUND, "需求不存在")
    demand.status = "closed"
    db.session.commit()
    return ok(demand.to_dict())


@bp.route("/users", methods=["GET"])
@role_required("admin")
def list_users():
    users = User.query.order_by(User.id.asc()).all()
    return ok([u.to_dict() for u in users])


@bp.route("/users/<int:user_id>/ban", methods=["POST"])
@role_required("admin")
def ban_user(user_id):
    user = User.query.get(user_id)
    if not user:
        return fail(ERR_NOT_FOUND, "用户不存在")
    user.status = "banned"
    db.session.commit()
    return ok(user.to_dict())


@bp.route("/reports", methods=["GET"])
@role_required("admin")
def list_reports():
    reports = Report.query.order_by(Report.id.desc()).all()
    return ok([r.to_dict() for r in reports])
