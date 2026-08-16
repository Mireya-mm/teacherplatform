# 数据库模型定义 - 校园家教智能匹配平台
from datetime import datetime
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()


def now_str():
    """统一的当前时间字符串"""
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


class User(db.Model):
    __tablename__ = "users"
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    phone = db.Column(db.Text, unique=True, nullable=False)
    password = db.Column(db.Text, nullable=False)
    nickname = db.Column(db.Text)
    role = db.Column(db.Text, nullable=False)  # parent|tutor|admin
    school = db.Column(db.Text)
    created_at = db.Column(db.Text, default=now_str)
    status = db.Column(db.Text, default="normal")  # normal|banned
    token = db.Column(db.Text)

    def to_dict(self):
        return {
            "id": self.id,
            "phone": self.phone,
            "nickname": self.nickname,
            "role": self.role,
            "school": self.school or "",
            "status": self.status,
            "created_at": self.created_at,
        }


class TutorProfile(db.Model):
    __tablename__ = "tutor_profiles"
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), primary_key=True)
    subjects = db.Column(db.Text)
    experience = db.Column(db.Text)
    price_min = db.Column(db.Integer)
    price_max = db.Column(db.Integer)
    region = db.Column(db.Text)
    intro = db.Column(db.Text)

    def to_dict(self, include_certified=False, certified=False):
        user = User.query.get(self.user_id)
        data = {
            "user_id": self.user_id,
            "nickname": user.nickname if user else "",
            "school": user.school if user else "",
            "subjects": self.subjects or "",
            "experience": self.experience or "",
            "price_min": self.price_min or 0,
            "price_max": self.price_max or 0,
            "region": self.region or "",
            "intro": self.intro or "",
        }
        if include_certified:
            data["certified"] = certified
        return data


class Certification(db.Model):
    __tablename__ = "certifications"
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    tutor_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    type = db.Column(db.Text, nullable=False)  # student|degree|cet4|teacher
    file_path = db.Column(db.Text)
    status = db.Column(db.Text, default="pending")  # pending|approved|rejected
    reviewed_by = db.Column(db.Integer)
    created_at = db.Column(db.Text, default=now_str)

    def to_dict(self, include_tutor=False):
        data = {
            "id": self.id,
            "tutor_id": self.tutor_id,
            "type": self.type,
            "file_path": self.file_path or "",
            "status": self.status,
            "created_at": self.created_at,
        }
        if include_tutor:
            tutor = User.query.get(self.tutor_id)
            data["tutor_nickname"] = tutor.nickname if tutor else ""
        return data


class Demand(db.Model):
    __tablename__ = "demands"
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    parent_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    grade = db.Column(db.Text)
    subject = db.Column(db.Text)
    price_min = db.Column(db.Integer)
    price_max = db.Column(db.Integer)
    location = db.Column(db.Text)
    mode = db.Column(db.Text)  # online|offline
    schedule = db.Column(db.Text)
    description = db.Column(db.Text)
    status = db.Column(db.Text, default="open")  # open|matched|closed
    created_at = db.Column(db.Text, default=now_str)

    def to_dict(self, include_parent_nickname=True, applied=None):
        data = {
            "id": self.id,
            "parent_id": self.parent_id,
            "grade": self.grade or "",
            "subject": self.subject or "",
            "price_min": self.price_min or 0,
            "price_max": self.price_max or 0,
            "location": self.location or "",
            "mode": self.mode or "",
            "schedule": self.schedule or "",
            "description": self.description or "",
            "status": self.status,
            "created_at": self.created_at,
        }
        if include_parent_nickname:
            parent = User.query.get(self.parent_id)
            data["parent_nickname"] = parent.nickname if parent else ""
        if applied is not None:
            data["applied"] = applied
        return data


class Application(db.Model):
    __tablename__ = "applications"
    __table_args__ = (db.UniqueConstraint("demand_id", "tutor_id", name="uq_demand_tutor"),)
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    demand_id = db.Column(db.Integer, db.ForeignKey("demands.id"), nullable=False)
    tutor_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    status = db.Column(db.Text, default="pending")  # pending|accepted|rejected
    created_at = db.Column(db.Text, default=now_str)

    def to_dict(self, include_tutor=False, include_demand=False):
        data = {
            "id": self.id,
            "demand_id": self.demand_id,
            "tutor_id": self.tutor_id,
            "status": self.status,
            "created_at": self.created_at,
        }
        if include_tutor:
            tutor = User.query.get(self.tutor_id)
            data["tutor_nickname"] = tutor.nickname if tutor else ""
            data["tutor_school"] = tutor.school if tutor else ""
            data["tutor_certified"] = is_tutor_certified(self.tutor_id)
        if include_demand:
            demand = Demand.query.get(self.demand_id)
            if demand:
                parent = User.query.get(demand.parent_id)
                data["demand_subject"] = demand.subject or ""
                data["demand_grade"] = demand.grade or ""
                data["demand_parent_nickname"] = parent.nickname if parent else ""
        return data


class Conversation(db.Model):
    __tablename__ = "conversations"
    __table_args__ = (
        db.UniqueConstraint("parent_id", "tutor_id", name="uq_parent_tutor"),
    )
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    parent_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    tutor_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    created_at = db.Column(db.Text, default=now_str)

    def to_dict(self, current_user_id=None):
        parent = User.query.get(self.parent_id)
        tutor = User.query.get(self.tutor_id)
        last_msg = (
            Message.query.filter_by(conversation_id=self.id)
            .order_by(Message.id.desc())
            .first()
        )
        return {
            "id": self.id,
            "parent_id": self.parent_id,
            "tutor_id": self.tutor_id,
            "parent_nickname": parent.nickname if parent else "",
            "tutor_nickname": tutor.nickname if tutor else "",
            "last_message": last_msg.content if last_msg else "",
            "last_time": last_msg.created_at if last_msg else "",
        }


class Message(db.Model):
    __tablename__ = "messages"
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    conversation_id = db.Column(db.Integer, db.ForeignKey("conversations.id"), nullable=False)
    sender_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    content = db.Column(db.Text)
    created_at = db.Column(db.Text, default=now_str)
    is_flagged = db.Column(db.Integer, default=0)

    def to_dict(self):
        return {
            "id": self.id,
            "conversation_id": self.conversation_id,
            "sender_id": self.sender_id,
            "content": self.content or "",
            "created_at": self.created_at,
            "is_flagged": bool(self.is_flagged),
        }


class Order(db.Model):
    __tablename__ = "orders"
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    demand_id = db.Column(db.Integer, db.ForeignKey("demands.id"), nullable=False)
    tutor_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    parent_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    price = db.Column(db.Integer)
    schedule = db.Column(db.Text)
    mode = db.Column(db.Text)
    status = db.Column(db.Text, default="draft")  # draft|confirmed
    created_at = db.Column(db.Text, default=now_str)

    def to_dict(self):
        return {
            "id": self.id,
            "demand_id": self.demand_id,
            "tutor_id": self.tutor_id,
            "parent_id": self.parent_id,
            "price": self.price or 0,
            "schedule": self.schedule or "",
            "mode": self.mode or "",
            "status": self.status,
            "created_at": self.created_at,
        }


class Review(db.Model):
    __tablename__ = "reviews"
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    order_id = db.Column(db.Integer, db.ForeignKey("orders.id"), nullable=False)
    from_user = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    to_user = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    score = db.Column(db.Integer)
    comment = db.Column(db.Text)
    created_at = db.Column(db.Text, default=now_str)

    def to_dict(self, include_from_nickname=False):
        data = {
            "id": self.id,
            "order_id": self.order_id,
            "from_user": self.from_user,
            "to_user": self.to_user,
            "score": self.score or 0,
            "comment": self.comment or "",
            "created_at": self.created_at,
        }
        if include_from_nickname:
            u = User.query.get(self.from_user)
            data["from_nickname"] = u.nickname if u else ""
        return data


class Report(db.Model):
    __tablename__ = "reports"
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    reporter_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    target_type = db.Column(db.Text)
    target_id = db.Column(db.Integer)
    reason = db.Column(db.Text)
    status = db.Column(db.Text, default="pending")  # pending|handled
    created_at = db.Column(db.Text, default=now_str)

    def to_dict(self):
        return {
            "id": self.id,
            "reporter_id": self.reporter_id,
            "target_type": self.target_type or "",
            "target_id": self.target_id or 0,
            "reason": self.reason or "",
            "status": self.status,
            "created_at": self.created_at,
        }


class SafetyAcknowledgement(db.Model):
    __tablename__ = "safety_acknowledgements"
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    demand_id = db.Column(db.Integer)
    tutor_id = db.Column(db.Integer)
    ack_text = db.Column(db.Text)
    created_at = db.Column(db.Text, default=now_str)

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "demand_id": self.demand_id,
            "tutor_id": self.tutor_id,
            "ack_text": self.ack_text or "",
            "created_at": self.created_at,
        }


def is_tutor_certified(tutor_id):
    """是否有任一 approved 认证"""
    return (
        Certification.query.filter_by(tutor_id=tutor_id, status="approved").count() > 0
    )
