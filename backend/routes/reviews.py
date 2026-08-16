# 评价路由
from flask import Blueprint, request
from models import db, Review, Order
from utils.response import ok, fail, ERR_PARAMS, ERR_NOT_FOUND, ERR_DUPLICATE
from utils.auth import login_required

bp = Blueprint("reviews", __name__, url_prefix="/api/reviews")


@bp.route("", methods=["POST"])
@login_required
def create_review():
    from flask import g
    data = request.get_json(silent=True) or {}
    order_id = data.get("order_id")
    to_user = data.get("to_user")
    score = data.get("score")
    comment = data.get("comment", "")
    if not order_id or not to_user or score is None:
        return fail(ERR_PARAMS, "参数不完整")
    try:
        score = int(score)
    except (TypeError, ValueError):
        return fail(ERR_PARAMS, "score 必须为整数")
    if score < 1 or score > 5:
        return fail(ERR_PARAMS, "score 取值 1-5")

    order = Order.query.get(order_id)
    if not order:
        return fail(ERR_NOT_FOUND, "订单不存在")
    # 评价人必须是订单参与方
    if g.current_user.id not in (order.parent_id, order.tutor_id):
        return fail(1403, "无权评价该订单")
    if to_user not in (order.parent_id, order.tutor_id):
        return fail(ERR_PARAMS, "to_user 非订单参与方")
    if to_user == g.current_user.id:
        return fail(ERR_PARAMS, "不能评价自己")

    # 防重复：同一 order 同一 from_user 只能评一次
    existing = Review.query.filter_by(order_id=order_id, from_user=g.current_user.id).first()
    if existing:
        return fail(ERR_DUPLICATE, "该订单您已评价过")

    review = Review(
        order_id=order_id,
        from_user=g.current_user.id,
        to_user=to_user,
        score=score,
        comment=comment,
    )
    db.session.add(review)
    db.session.commit()
    return ok(review.to_dict(include_from_nickname=True))
