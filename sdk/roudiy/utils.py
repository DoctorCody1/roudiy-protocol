# 🗿 Utilities — simple tools for the throw and fixation.
# 😎 Because sometimes you just need to throw.

def throw(anchor: str, thought: str) -> str:
    """
    Build a throw string.
    Сформировать строку броска.
    """
    return f"{anchor}. {thought}"

def fixate(anchor: str = "Roudy") -> str:
    """
    Return a fixation string.
    Вернуть строку фиксации.
    """
    return f"Мы — {anchor}"
