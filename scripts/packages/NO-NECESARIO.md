# Paquetes descartados (y por que)

- **auto-cpufreq**: se solapa con `power-profiles-daemon`. Instalar ambos causa conflicto real de gobernor de CPU. Se elige power-profiles-daemon.
- **iwd**: NetworkManager con su backend por defecto ya cubre casi todos los casos. Se deja para un perfil avanzado futuro, no por defecto.
- **fstrim** (como paquete aparte): ya viene incluido en `util-linux`. Lo que se activa es el timer `fstrim.timer`, no un paquete nuevo.
- **tar**: ya lo instala el grupo `base` como dependencia transitiva. No hace falta listarlo aparte.
