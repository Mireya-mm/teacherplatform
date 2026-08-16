# 家教简历与认证路由
import os
import base64
from flask import Blueprint, request
from models import db, User, TutorProfile, Certification, Review, is_tutor_certified
from utils.response import ok, fail, ERR_PARAMS, ERR_NOT_FOUND, ERR_FORBIDDEN
from utils.auth import role_required

bp = Blueprint("tutors", __name__, url_prefix="/api/tutors")

UPLOAD_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "uploads")
ALLOWED_CERT_TYPES = ("student", "degree", "cet4", "teacher")


@bp.route("/profile", methods=["PUT"])
@role_required("tutor")
def update_profile():
    from flask import g
    data = request.get_json(silent=True) or {}
    user = g.current_user
    profile = TutorProfile.query.get(user.id)
    if not profile:
        profile = TutorProfile(user_id=user.id)
        db.session.add(profile)
    profile.subjects = data.get("subjects", profile.subjects)
    profile.experience = data.get("experience", profile.experience)
    profile.price_min = data.get("price_min", profile.price_min)
    profile.price_max = data.get("price_max", profile.price_max)
    profile.region = data.get("region", profile.region)
    profile.intro = data.get("intro", profile.intro)
    db.session.commit()
    return ok(profile.to_dict(include_certified=True, certified=is_tutor_certified(user.id)))


@bp.route("/profile", methods=["GET"])
@role_required("parent", "tutor", "admin")
def get_profile():
    from flask import g
    tutor_id = request.args.get("tutor_id", type=int)
    if tutor_id is None:
        user = g.current_user
        if user.role != "tutor":
            return fail(ERR_FORBIDDEN, "仅家教可查询本人简历")
        tutor_id = user.id
    profile = TutorProfile.query.get(tutor_id)
    if not profile:
        return fail(ERR_NOT_FOUND, "该家教尚未填写简历")
    return ok(profile.to_dict(include_certified=True, certified=is_tutor_certified(tutor_id)))


@bp.route("/certifications", methods=["GET"])
@role_required("tutor")
def list_certifications():
    from flask import g
    certs = Certification.query.filter_by(tutor_id=g.current_user.id).all()
    return ok([c.to_dict() for c in certs])


@bp.route("/certifications", methods=["POST"])
@role_required("tutor")
def upload_certification():
    from flask import g
    data = request.get_json(silent=True) or {}
    cert_type = (data.get("type") or "").strip()
    file_path = data.get("file_path") or ""
    if cert_type not in ALLOWED_CERT_TYPES:
        return fail(ERR_PARAMS, "type 必须为 student/degree/cet4/teacher")
    if not file_path:
        return fail(ERR_PARAMS, "file_path 不能为空")

    # 尝试按 base64 解码存文件；失败则直接存原值（演示用）
    stored_path = file_path
    try:
        if not file_path.startswith("demo:") and not file_path.startswith("/"):
            # 简单判断是否 base64
            decoded = base64.b64decode(file_path, validate=True)
            os.makedirs(UPLOAD_DIR, exist_ok=True)
            filename = f"{cert_type}_{g.current_user.id}_{len(decoded)}.bin"
            abs_path = os.path.join(UPLOAD_DIR, filename)
            with open(abs_path, "wb") as f:
                f.write(decoded)
            stored_path = f"uploads/{filename}"
    except Exception:
        # 解码失败直接存原值
        stored_path = file_path

    cert = Certification(
        tutor_id=g.current_user.id,
        type=cert_type,
        file_path=stored_path,
        status="pending",
    )
    db.session.add(cert)
    db.session.commit()
    return ok(cert.to_dict())


@bp.route("", methods=["GET"])
@role_required("parent", "tutor", "admin")
def list_tutors():
    profiles = TutorProfile.query.all()
    result = [
        p.to_dict(include_certified=True, certified=is_tutor_certified(p.user_id))
        for p in profiles
    ]
    return ok(result)


@bp.route("/<int:tutor_id>/reviews", methods=["GET"])
def list_tutor_reviews(tutor_id):
    reviews = Review.query.filter_by(to_user=tutor_id).all()
    return ok([r.to_dict(include_from_nickname=True) for r in reviews])
