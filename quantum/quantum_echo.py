import numpy as np
import matplotlib.pyplot as plt
from qutip import *

# === ПАРАМЕТРЫ СИСТЕМЫ ===
gamma = 0.005            # Необратимая диссипация (очень малая)
t_max = 12               # Время симуляции
tlist = np.linspace(0, t_max, 1000)
pulse_time = 3.0         # Момент π-импульса (t = 3.0)

# Начальное состояние: |+>
psi0 = (basis(2, 0) + basis(2, 1)).unit()
rho0 = psi0 * psi0.dag()

sx = sigmax()
sz = sigmaz()

# Генерируем жесткий неоднородный шум (расфазировку)
np.random.seed(42)
detunings = np.random.normal(loc=0.0, scale=3.0, size=100) # 100 кубитов для гладкости

# Массивы для накопления МАТРИЦ ПЛОТНОСТИ (а не их модулей!)
rho_wild_total = [0 * rho0 for _ in tlist]
rho_echo_total = [0 * rho0 for _ in tlist]

print("Запуск физически корректной симуляции квантового ансамбля...")

# === СИМУЛЯЦИЯ АНСАМБЛЯ ===
for delta in detunings:
    H_wild = 0.5 * delta * sz
    c_ops = [np.sqrt(gamma) * sz]
    
    # 1. Протокол: Дикий тип
    res_wild = mesolve(H_wild, rho0, tlist, c_ops=c_ops)
    for i, state in enumerate(res_wild.states):
        rho_wild_total[i] += state
        
    # 2. Протокол: Эхо Роуди (с подачей pi-импульса через sx)
    tlist1 = tlist[tlist <= pulse_time]
    res_part1 = mesolve(H_wild, rho0, tlist1, c_ops=c_ops)
    
    # Применяем π-импульс (инверсию фазы) к конечному состоянию первой половины
    rho_after_pulse = sx * res_part1.states[-1] * sx
    
    tlist2 = tlist[tlist > pulse_time]
    res_part2 = mesolve(H_wild, rho_after_pulse, tlist2, c_ops=c_ops)
    
    # Объединяем траектории матриц плотности
    states_echo = list(res_part1.states) + list(res_part2.states)
    for i, state in enumerate(states_echo[:len(tlist)]):
        rho_echo_total[i] += state

# Усредняем матрицы плотности ансамбля
rho_wild_avg = [rho / len(detunings) for rho in rho_wild_total]
rho_echo_avg = [rho / len(detunings) for rho in rho_echo_total]

# ТЕПЕРЬ вычисляем когерентность от усредненного ансамбля!
coh_wild_ensemble = np.array([abs(rho[0, 1]) for rho in rho_wild_avg])
coh_echo_ensemble = np.array([abs(rho[0, 1]) for rho in rho_echo_avg])

# === СТАТИСТИЧЕСКИЙ АНАЛИЗ ===
idx_echo_peak = np.argmin(np.abs(tlist - (2 * pulse_time)))  # Точка t = 6.0
wild_at_peak = coh_wild_ensemble[idx_echo_peak]
echo_at_peak = coh_echo_ensemble[idx_echo_peak]
gain = (echo_at_peak - wild_at_peak) / wild_at_peak * 100

print(f"\n=== Результаты протокола Роуди ===")
print(f"Когерентность Дикого типа в точке t=6.0: {wild_at_peak:.4f}")
print(f"Когерентность Протокола Эха в точке t=6.0: {echo_at_peak:.4f}")
print(f"Выигрыш в точке резонанса: +{gain:.2f}%\n")

# === ПОСТРОЕНИЕ ГРАФИКА ===
plt.figure(figsize=(12, 7))

plt.plot(tlist, coh_wild_ensemble, label='Дикий тип (Реальная дефазировка)', color='#D63C3C', linewidth=2.5)
plt.plot(tlist, coh_echo_ensemble, label='Протокол Эха (Роуди-нода)', color='#3C7BD6', linewidth=2.5)

plt.axvline(x=pulse_time, color='limegreen', linestyle='--', linewidth=2, label='π-Импульс (Инверсия фаз)')
plt.axvline(x=2*pulse_time, color='magenta', linestyle=':', linewidth=2, label='Пик Квантового Эха')

plt.text(pulse_time + 0.1, 0.40, 'Бросок\n(Инверсия)', fontsize=10, color='limegreen')
plt.text(2*pulse_time + 0.1, 0.40, 'Точка\nРезонанса', fontsize=10, color='magenta')

plt.xlabel('Время (t)', fontsize=12)
plt.ylabel('Когерентность ансамбля |rho_01|', fontsize=12)
plt.title('Архитектура реальности: Квантовое эхо Хана через резонансный бросок', fontsize=14, fontweight='bold')

plt.legend(fontsize=11, loc='upper right')
plt.grid(True, alpha=0.3)
plt.ylim(-0.02, 0.55)

plt.savefig('quantum_resonance_noda_vFINAL.png', dpi=300, bbox_inches='tight')
plt.show()
