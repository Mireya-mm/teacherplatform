# 投递管理路由：处理投递 / 我的投递
from flask import Blueprint, request
from models import db, Application, Demand
from utils.response import ok, fail, ERR_PARAMS, ERR_NOT_FOUND, ERR_FORBIDDEN_OP
from utils.auth import role_required

bp = Blueprint("applications", __name__, url_prefix="/api/applications")


@bp.route("/mine", methods=["GET"])
@role_required("tutor")
def my_applications():
    from flask import g
    apps = Application.query.filter_by(tutor_id=g.current_user.id).order_by(Application.id.desc()).all()
    return ok([a.to_dict(include_tutor=True, include_demand=True) for a in apps])


@bp.route("/<int:app_id>", methods=["PATCH", "PUT"])
@role_required("parent")
def patch_application(app_id):
    from flask import g
    data = request.get_json(silent=True) or {}
    status = (data.get("status") or "").strip()
    if status not in ("accepted", "rejected"):
        return fail(ERR_PARAMS, "status 必须为 accepted/rejected")

    app = Application.query.get(app_id)
    if not app:
        return fail(ERR_NOT_FOUND, "投递记录不存在")
    demand = Demand.query.get(app.demand_id)
    if not demand or demand.parent_id != g.current_user.id:
        return fail(1403, "无权操作该投递")

    app.status = status
    if status == "accepted":
        # 该需求其他投递自动置为 rejected
        others = Application.query.filter(
            Application.demand_id == app.demand_id,
            Application.id != app.id,
        ).all()
        for o in others:
            o.status = "rejected"
        demand.status = "matched"
    db.session.commit()
    return ok(app.to_dict(include_tutor=True))
