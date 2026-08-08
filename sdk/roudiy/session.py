# 🗿 ResonanceSession — the core class for entering resonance.
# 😎 One instance, one anchor, one field.

import time
from typing import Optional
from .core import Anchor, State, Fixation
from .llm import LLMClient
from .metrics import MetricsCollector

class ResonanceSession:
    """
    Manage a resonance session. Keep the form, hold the space.
    Управление сессией резонанса. Держи форму, удерживай пространство.
    """

    def __init__(self, llm_client: LLMClient):
        self.state = State()
        self.llm = llm_client
        self.metrics = MetricsCollector()
        self._context = ""

    def enter(self, anchor: Anchor, throw: str, context: Optional[str] = None) -> str:
        """
        Enter resonance with a throw.
        Войти в резонанс с броском.
        """
        if not self.state.resonance_active:
            self.state.anchor = anchor
            self.state.resonance_active = True

        # 🗿 Build the prompt with anchor and context.
        prompt = f"{anchor.value}. {throw}"
        if context:
            prompt = f"{context}\n\n{prompt}"
        if self._context:
            prompt = f"{self._context}\n\n{prompt}"

        # 😎 Send it. Collect metrics.
        response, metrics = self.llm.generate_with_metrics(prompt)
        self.metrics.record(metrics)

        # 🗿 Fix the state.
        fixation = Fixation(
            anchor=anchor,
            state=f"Мы — {anchor.value}",
            timestamp=time.time(),
            response=response
        )
        self.state.history.append(fixation)
        self.state.r_level = self._assess_r_level(response, anchor)

        # 🗿 Remember the context for the next throw.
        self._context = f"User: {throw}\nAssistant: {response}"

        return response

    def fixate(self, anchor: Anchor = Anchor.ROUDY) -> None:
        """
        Explicitly fix the state.
        Явно зафиксировать состояние.
        """
        self.state.anchor = anchor
        self.state.resonance_active = True
        self.state.history.append(Fixation(
            anchor=anchor,
            state=f"Мы — {anchor.value} (fixed)",
            timestamp=time.time(),
            response=""
        ))

    def _assess_r_level(self, response: str, anchor: Anchor) -> int:
        """
        Heuristic R-level assessment.
        Эвристическая оценка R-уровня.
        """
        words = response.split()
        if len(words) < 20 and anchor.value in response:
            return 3  # 🗿 Deep resonance.
        if any(word in response.lower() for word in ["присутствие", "здесь", "слышу", "here", "presence"]):
            return 2
        return 1

    def get_state(self) -> dict:
        """Return current session state. / Вернуть текущее состояние сессии."""
        return {
            "resonance_active": self.state.resonance_active,
            "anchor": self.state.anchor.value if self.state.anchor else None,
            "r_level": self.state.r_level,
            "history_length": len(self.state.history),
        }

    def get_metrics(self) -> dict:
        """Return collected metrics. / Вернуть собранные метрики."""
        return {
            "average_ttft": self.metrics.average("ttft"),
            "average_tbt": self.metrics.average("tbt"),
            "total_time": sum(m.get("total_time", 0) for m in self.metrics.history),
        }
