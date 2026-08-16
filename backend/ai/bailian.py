# 阿里百炼 AI 调用模块（可插拔，失败自动降级为规则匹配）
# 环境变量 DASHSCOPE_API_KEY 缺失时直接走降级路径，不报错
import os
import json
import re

DASHSCOPE_API_KEY = os.environ.get("DASHSCOPE_API_KEY", "").strip()

# 规则匹配用科目关键词表
SUBJECT_KEYWORDS = [
    "数学", "语文", "英语", "物理", "化学", "生物",
    "历史", "地理", "政治", "计算机", "编程", "钢琴", "吉他",
    "美术", "书法", "体育",
]


def _is_available():
    """百炼是否可用（有 key 且 dashscope 已安装）"""
    if not DASHSCOPE_API_KEY:
        return False
    try:
        import dashscope  # noqa: F401
        return True
    except Exception:
        return False


def _qwen_call(prompt):
    """调用通义千问，返回文本内容；失败抛异常"""
    import dashscope
    dashscope.api_key = DASHSCOPE_API_KEY
    resp = dashscope.Generation.call(
        model="qwen-turbo",
        prompt=prompt,
        result_format="message",
    )
    # 兼容不同版本返回结构
    if hasattr(resp, "status_code") and resp.status_code != 200:
        raise RuntimeError(f"百炼调用失败: {getattr(resp, 'code', '')} {getattr(resp, 'message', '')}")
    output = getattr(resp, "output", None) or resp.get("output", {}) if isinstance(resp, dict) else None
    if output is None and isinstance(resp, dict):
        output = resp.get("output", {})
    text = ""
    if isinstance(output, dict):
        choices = output.get("choices", [])
        if choices:
            msg = choices[0].get("message", {})
            text = msg.get("content", "")
        if not text:
            text = output.get("text", "")
    return text


def _parse_json_from_text(text):
    """从模型返回文本中提取 JSON 对象/数组"""
    if not text:
        return None
    # 去掉 ```json ``` 包裹
    m = re.search(r"```(?:json)?\s*([\s\S]*?)```", text)
    if m:
        text = m.group(1)
    text = text.strip()
    # 找到第一个 { 或 [ 开始的 JSON 片段
    for start_char, end_char in [("{", "}"), ("[", "]")]:
        idx = text.find(start_char)
        if idx >= 0:
            end_idx = text.rfind(end_char)
            if end_idx > idx:
                try:
                    return json.loads(text[idx:end_idx + 1])
                except Exception:
                    continue
    try:
        return json.loads(text)
    except Exception:
        return None


# ========== 简历解析 ==========
def parse_resume(text):
    """解析简历文本，返回 (result_dict, degraded_bool)"""
    if _is_available():
        try:
            prompt = (
                "你是简历解析助手。请从以下简历文本中提取家教擅长科目和标签，"
                '严格只返回JSON：{"subjects":"科目1,科目2","tags":"标签1,标签2"}。\n'
                f"简历文本：\n{text}"
            )
            raw = _qwen_call(prompt)
            data = _parse_json_from_text(raw)
            if data and isinstance(data, dict):
                return {
                    "subjects": data.get("subjects", ""),
                    "tags": data.get("tags", ""),
                }, False
        except Exception:
            pass
    # 降级：规则提取
    return _rule_parse_resume(text), True


def _rule_parse_resume(text):
    found = [kw for kw in SUBJECT_KEYWORDS if kw in text]
    return {
        "subjects": ",".join(found) if found else "",
        "tags": "规则提取",
    }


# ========== 需求匹配家教 ==========
def match_demand(demand_text):
    """匹配需求与家教，返回 (results_list, degraded_bool)"""
    # 延迟导入避免循环依赖
    from models import TutorProfile, User

    tutors = TutorProfile.query.all()
    if _is_available() and tutors:
        try:
            tutor_brief = ";".join(
                f"{t.user_id}:{User.query.get(t.user_id).nickname if User.query.get(t.user_id) else ''}"
                f"({t.subjects or ''})"
                for t in tutors
            )
            prompt = (
                "你是家教匹配助手。根据家长需求，从候选家教中推荐最匹配的，"
                '严格只返回JSON数组：[{"tutor_id":1,"nickname":"名字","reason":"推荐理由"}]。\n'
                f"家长需求：{demand_text}\n候选家教：{tutor_brief}"
            )
            raw = _qwen_call(prompt)
            data = _parse_json_from_text(raw)
            if data and isinstance(data, list) and data:
                return data, False
        except Exception:
            pass
    # 降级：科目关键词模糊匹配
    return _rule_match_demand(demand_text, tutors), True


def _rule_match_demand(demand_text, tutors):
    from models import User
    results = []
    demand_subjects = [kw for kw in SUBJECT_KEYWORDS if kw in demand_text]
    for t in tutors:
        tutor_subjects = (t.subjects or "").replace("，", ",").split(",")
        tutor_subjects = [s.strip() for s in tutor_subjects if s.strip()]
        hit = False
        for ds in demand_subjects:
            for ts in tutor_subjects:
                if ds in ts or ts in ds:
                    hit = True
                    break
            if hit:
                break
        if hit or not demand_subjects:
            user = User.query.get(t.user_id)
            results.append({
                "tutor_id": t.user_id,
                "nickname": user.nickname if user else "",
                "reason": "规则匹配：科目相关" if hit else "规则匹配：暂无明确科目，默认推荐",
            })
    return results


# ========== 需求文本归一化 ==========
def normalize_demand(text):
    """把自然语言需求文本归一化为结构化字段，返回 (result_dict, degraded_bool)"""
    if _is_available():
        try:
            prompt = (
                "你是需求解析助手。从以下家长需求文本提取结构化字段，"
                '严格只返回JSON：{"grade":"","subject":"","price_min":0,"price_max":0,'
                '"location":"","mode":"","schedule":"","description":""}。'
                "mode 取 online 或 offline，price 为整数，缺失字段留空或 0。\n"
                f"需求文本：{text}"
            )
            raw = _qwen_call(prompt)
            data = _parse_json_from_text(raw)
            if data and isinstance(data, dict):
                return {
                    "grade": data.get("grade", "") or "",
                    "subject": data.get("subject", "") or "",
                    "price_min": int(data.get("price_min") or 0),
                    "price_max": int(data.get("price_max") or 0),
                    "location": data.get("location", "") or "",
                    "mode": data.get("mode", "") or "",
                    "schedule": data.get("schedule", "") or "",
                    "description": data.get("description", "") or text,
                }, False
        except Exception:
            pass
    # 降级：原文塞进 description
    return {
        "grade": "",
        "subject": "",
        "price_min": 0,
        "price_max": 0,
        "location": "",
        "mode": "",
        "schedule": "",
        "description": text,
    }, True
