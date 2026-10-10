# .bash_profile - arranca MEAL Recovery directo al hacer login en tty1
if [ -z "$MEAL_RECOVERY_LANZADO" ] && [ "$(tty)" = "/dev/tty1" ]; then
    export MEAL_RECOVERY_LANZADO=1
    /opt/meal/scripts/recovery/meal-recovery.sh
fi
