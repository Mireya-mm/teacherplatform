# Flask 应用入口 - 校园家教智能匹配平台后端
import os
from flask import Flask
from flask_cors import CORS
from models import db

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "campus_tutor.db")


def create_app(init_db=True):
    """创建并配置 Flask 应用"""
    app = Flask(__name__)
    app.config["SQLALCHEMY_DATABASE_URI"] = f"sqlite:///{DB_PATH}"
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
    app.config["JSON_AS_ASCII"] = False

    db.init_app(app)
    CORS(app)  # 允许鸿蒙 App 跨域访问

    # 注册所有蓝图
    from routes.auth import bp as auth_bp
    from routes.users import bp as users_bp
    from routes.tutors import bp as tutors_bp
    from routes.demands import bp as demands_bp
    from routes.applications import bp as applications_bp
    from routes.conversations import bp as conversations_bp
    from routes.orders import bp as orders_bp
    from routes.reviews import bp as reviews_bp
    from routes.reports import bp as reports_bp
    from routes.safety import bp as safety_bp
    from routes.admin import bp as admin_bp
    from routes.ai import bp as ai_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(users_bp)
    app.register_blueprint(tutors_bp)
    app.register_blueprint(demands_bp)
    app.register_blueprint(applications_bp)
    app.register_blueprint(conversations_bp)
    app.register_blueprint(orders_bp)
    app.register_blueprint(reviews_bp)
    app.register_blueprint(reports_bp)
    app.register_blueprint(safety_bp)
    app.register_blueprint(admin_bp)
    app.register_blueprint(ai_bp)

    @app.route("/")
    def index():
        return {"code": 0, "msg": "ok", "data": "校园家教智能匹配平台后端运行中"}

    if init_db:
        with app.app_context():
            db.create_all()

    return app


app = create_app(init_db=True)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
