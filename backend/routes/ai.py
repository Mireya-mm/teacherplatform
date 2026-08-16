# AI 可插拔路由（百炼失败自动降级为规则匹配）
from flask import Blueprint, request
from models import db
from ai import bailian
from utils.response import ok, fail, ERR_PARAMS
from utils.auth import login_required

bp = Blueprint("ai", __name__, url_prefix="/api/ai")


@bp.route("/parse-resume", methods=["POST"])
@login_required
def parse_resume():
    data = request.get_json(silent=True) or {}
    text = data.get("text") or ""
    if not text.strip():
        return fail(ERR_PARAMS, "text 不能为空")
    result, degraded = bailian.parse_resume(text)
    result["ai_degraded"] = degraded
    return ok(result)


@bp.route("/match", methods=["POST"])
@login_required
def match():
    data = request.get_json(silent=True) or {}
    demand_text = data.get("demand_text") or ""
    if not demand_text.strip():
        return fail(ERR_PARAMS, "demand_text 不能为空")
    results, degraded = bailian.match_demand(demand_text)
    # 前端期望直接返回数组；ai_degraded 信号附加在每个匹配项上
    for item in results:
        item["ai_degraded"] = degraded
    return ok(results)


@bp.route("/normalize-demand", methods=["POST"])
@login_required
def normalize_demand():
    data = request.get_json(silent=True) or {}
    text = data.get("text") or ""
    if not text.strip():
        return fail(ERR_PARAMS, "text 不能为空")
    result, degraded = bailian.normalize_demand(text)
    result["ai_degraded"] = degraded
    return ok(result)
