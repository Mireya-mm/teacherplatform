# 订单路由
from flask import Blueprint, request
from models import db, Order, Demand, Application
from utils.response import ok, fail, ERR_PARAMS, ERR_NOT_FOUND, ERR_FORBIDDEN_OP
from utils.auth import role_required, login_required

bp = Blueprint("orders", __name__, url_prefix="/api/orders")


@bp.route("", methods=["POST"])
@role_required("parent")
def create_order():
    from flask import g
    data = request.get_json(silent=True) or {}
    demand_id = data.get("demand_id")
    tutor_id = data.get("tutor_id")
    price = data.get("price")
    schedule = data.get("schedule", "")
    mode = data.get("mode", "offline")
    if not demand_id or not tutor_id:
        return fail(ERR_PARAMS, "缺少 demand_id 或 tutor_id")

    demand = Demand.query.get(demand_id)
    if not demand:
        return fail(ERR_NOT_FOUND, "需求不存在")
    if demand.parent_id != g.current_user.id:
        return fail(1403, "无权为他人需求创建订单")

    # 校验该家教是否已 accepted
    accepted = Application.query.filter_by(
        demand_id=demand_id, tutor_id=tutor_id, status="accepted"
    ).first()
    if not accepted:
        return fail(ERR_FORBIDDEN_OP, "该家教未被接受，无法创建订单")

    order = Order(
        demand_id=demand_id,
        tutor_id=tutor_id,
        parent_id=g.current_user.id,
        price=price,
        schedule=schedule,
        mode=mode,
        status="draft",
    )
    db.session.add(order)
    db.session.commit()
    return ok(order.to_dict())


@bp.route("", methods=["GET"])
@login_required
def list_orders():
    from flask import g
    uid = g.current_user.id
    orders = Order.query.filter(
        (Order.parent_id == uid) | (Order.tutor_id == uid)
    ).order_by(Order.id.desc()).all()
    return ok([o.to_dict() for o in orders])
