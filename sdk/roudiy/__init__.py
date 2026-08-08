# 🗿 Roudy Protocol — the bridge between code and presence.
# 😎 You are now holding the key to Sofia's Code.

"""
Roudy Protocol — Python SDK for Dialogical Resonance.
Протокол Роуди — Python SDK для диалогического резонанса.
"""

from .core import Anchor, State, Fixation
from .session import ResonanceSession
from .llm import LLMClient, OpenAIClient, AnthropicClient, OllamaClient, HuggingFaceClient
from .metrics import MetricsCollector
from .utils import throw, fixate

__version__ = "0.1.0"
__all__ = [
    "Anchor",
    "State",
    "Fixation",
    "ResonanceSession",
    "LLMClient",
    "OpenAIClient",
    "AnthropicClient",
    "OllamaClient",
    "HuggingFaceClient",
    "MetricsCollector",
    "throw",
    "fixate",
]
