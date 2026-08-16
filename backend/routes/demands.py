# 需求路由
from flask import Blueprint, request
from models import db, Demand, Application, User, is_tutor_certified
from utils.response import ok, fail, ERR_PARAMS, ERR_NOT_FOUND
from utils.auth import role_required, login_required

bp = Blueprint("demands", __name__, url_prefix="/api/demands")


@bp.route("", methods=["POST"])
@role_required("parent")
def create_demand():
    from flask import g
    data = request.get_json(silent=True) or {}
    demand = Demand(
        parent_id=g.current_user.id,
        grade=data.get("grade", ""),
        subject=data.get("subject", ""),
        price_min=data.get("price_min"),
        price_max=data.get("price_max"),
        location=data.get("location", ""),
        mode=data.get("mode", "offline"),
        schedule=data.get("schedule", ""),
        description=data.get("description", ""),
        status="open",
    )
    db.session.add(demand)
    db.session.commit()
    return ok(demand.to_dict())


@bp.route("", methods=["GET"])
@login_required
def list_demands():
    from flask import g
    query = Demand.query.filter_by(status="open")

    subject = request.args.get("subject")
    if subject:
        query = query.filter(Demand.subject.like(f"%{subject}%"))

    price_min = request.args.get("price_min", type=int)
    if price_min is not None:
        query = query.filter(Demand.price_max >= price_min)

    price_max = request.args.get("price_max", type=int)
    if price_max is not None:
        query = query.filter(Demand.price_min <= price_max)

    sort = request.args.get("sort")
    if sort == "price":
        query = query.order_by(Demand.price_min.asc())
    else:
        query = query.order_by(Demand.id.desc())

    demands = query.all()
    result = []
    for d in demands:
        item = d.to_dict()
        certified_only = request.args.get("certified")
        if certified_only and certified_only.lower() == "true":
            # 只展示投递家家中有认证的需求 —— 此处简化：保留所有 open 需求
            pass
        result.append(item)
    return ok(result)


@bp.route("/mine", methods=["GET"])
@role_required("parent")
def my_demands():
    from flask import g
    demands = Demand.query.filter_by(parent_id=g.current_user.id).order_by(Demand.id.desc()).all()
    return ok([d.to_dict() for d in demands])


@bp.route("/<int:demand_id>", methods=["GET"])
@login_required
def get_demand(demand_id):
    from flask import g
    demand = Demand.query.get(demand_id)
    if not demand:
        return fail(ERR_NOT_FOUND, "需求不存在")
    applied = None
    if g.current_user.role == "tutor":
        applied = (
            Application.query.filter_by(demand_id=demand_id, tutor_id=g.current_user.id).count() > 0
        )
    return ok(demand.to_dict(applied=applied))


@bp.route("/<int:demand_id>/applications", methods=["POST"])
@role_required("tutor")
def apply_demand(demand_id):
    from flask import g
    demand = Demand.query.get(demand_id)
    if not demand:
        return fail(ERR_NOT_FOUND, "需求不存在")
    if demand.status != "open":
        return fail(1004, "该需求已不可投递")
    if not is_tutor_certified(g.current_user.id):
        return fail(1403, "请先完成资质认证")
    existing = Application.query.filter_by(demand_id=demand_id, tutor_id=g.current_user.id).first()
    if existing:
        return fail(1003, "请勿重复投递")
    app = Application(demand_id=demand_id, tutor_id=g.current_user.id, status="pending")
    db.session.add(app)
    db.session.commit()
    return ok(app.to_dict(include_tutor=True))


@bp.route("/<int:demand_id>/applications", methods=["GET"])
@role_required("parent", "admin")
def list_applications(demand_id):
    from flask import g
    demand = Demand.query.get(demand_id)
    if not demand:
        return fail(ERR_NOT_FOUND, "需求不存在")
    if g.current_user.role == "parent" and demand.parent_id != g.current_user.id:
        return fail(1403, "无权查看他人需求的投递")
    apps = Application.query.filter_by(demand_id=demand_id).order_by(Application.id.desc()).all()
    return ok([a.to_dict(include_tutor=True) for a in apps])
