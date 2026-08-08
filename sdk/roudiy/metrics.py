# 🗿 Metrics — because without data you're just guessing.
# 😎 TTFT, TBT, and everything you need to prove resonance.

from typing import List, Dict

class MetricsCollector:
    """Collect and report metrics for resonance sessions."""
    def __init__(self):
        self.history: List[Dict] = []

    def record(self, metrics: Dict):
        """Record a new metrics entry."""
        self.history.append(metrics)

    def average(self, key: str) -> float:
        """Calculate average for a given metric key."""
        values = [m.get(key, 0) for m in self.history]
        return sum(values) / len(values) if values else 0

    def last(self, key: str):
        """Return the last recorded value for a metric."""
        return self.history[-1].get(key) if self.history else None

    def report(self) -> Dict:
        """Generate a summary report."""
        if not self.history:
            return {}
        return {
            "count": len(self.history),
            "avg_ttft": self.average("ttft"),
            "avg_tbt": self.average("tbt"),
            "avg_response_length": self.average("response_length"),
            "total_time": sum(m.get("total_time", 0) for m in self.history),
        }
