# 数据库初始化：建表 + 种子数据（幂等：drop_all -> create_all -> 插入）
# 用法: python db_init.py
import secrets
from app import create_app
from models import db, User, TutorProfile, Certification, Demand, Application, Conversation, Message


def seed():
    app = create_app(init_db=False)
    with app.app_context():
        # 幂等：先清空再重建
        db.drop_all()
        db.create_all()

        # 1. 管理员
        admin = User(
            phone="13800000000", password="123456", nickname="平台管理员",
            role="admin", status="normal", token=secrets.token_hex(16),
        )
        # 2. 家长
        parent = User(
            phone="13800000001", password="123456", nickname="张爸爸",
            role="parent", status="normal", token=secrets.token_hex(16),
        )
        # 3. 家教
        tutor = User(
            phone="13800000002", password="123456", nickname="李同学",
            role="tutor", school="清华大学", status="normal", token=secrets.token_hex(16),
        )
        db.session.add_all([admin, parent, tutor])
        db.session.commit()

        # 4. 家教简历
        profile = TutorProfile(
            user_id=tutor.id,
            subjects="数学,物理",
            experience="两年家教经验",
            price_min=80,
            price_max=150,
            region="海淀区",
            intro="清华数学系大三，擅长初高中数学物理",
        )
        db.session.add(profile)

        # 5. 家教认证（已通过，使该家教 certified=true）
        cert = Certification(
            tutor_id=tutor.id,
            type="student",
            file_path="demo:学籍证明.jpg",
            status="approved",
            reviewed_by=admin.id,
        )
        db.session.add(cert)

        # 6. 家长需求
        demand = Demand(
            parent_id=parent.id,
            grade="高一",
            subject="数学",
            price_min=80,
            price_max=120,
            location="北京市海淀区中关村",
            mode="offline",
            schedule="周末上午",
            description="希望清华北大家教辅导高一数学",
            status="open",
        )
        db.session.add(demand)
        db.session.commit()

        # 7. 家教对该需求的投递
        application = Application(
            demand_id=demand.id,
            tutor_id=tutor.id,
            status="pending",
        )
        db.session.add(application)

        # 8. 会话 + 2 条消息
        conv = Conversation(parent_id=parent.id, tutor_id=tutor.id)
        db.session.add(conv)
        db.session.commit()

        msg1 = Message(
            conversation_id=conv.id,
            sender_id=parent.id,
            content="李同学你好，看到你的简历很符合我们的需求，方便沟通一下吗？",
            is_flagged=0,
        )
        msg2 = Message(
            conversation_id=conv.id,
            sender_id=tutor.id,
            content="张爸爸您好！很高兴您对我的认可，周末上午我可以过来试讲。",
            is_flagged=0,
        )
        db.session.add_all([msg1, msg2])
        db.session.commit()

        print("✅ 数据库初始化完成，种子数据已写入：")
        print(f"   管理员 13800000000 / 123456 (id={admin.id})")
        print(f"   家长   13800000001 / 123456 (id={parent.id})")
        print(f"   家教   13800000002 / 123456 (id={tutor.id})")
        print(f"   需求 id={demand.id}，投递 id={application.id}，会话 id={conv.id}")


if __name__ == "__main__":
    seed()
