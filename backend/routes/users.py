# 用户路由：当前用户信息
from flask import Blueprint
from utils.response import ok
from utils.auth import login_required

bp = Blueprint("users", __name__, url_prefix="/api/users")


@bp.route("/me", methods=["GET"])
@login_required
def me():
    from flask import g
    return ok(g.current_user.to_dict())
