#!/usr/bin/env python3
"""Consulta las bases de datos sync de Arch (core.db, extra.db, multilib.db) SIN pacman.
Formato confirmado en la documentacion de Arch: tar.gz con un 'desc' por paquete (%NAME%, %GROUPS%, %PROVIDES%).

Uso:    arch_db_lookup.py DIR_CON_LOS_DB repo1 repo2 ... < nombres (uno por linea)
Salida: ESTADO<TAB>nombre<TAB>detalle   con ESTADO = OK | PROVIDE | GRUPO | MULTILIB | FALTA
"""
import os
import re
import sys
import tarfile


def parse_desc(text):
    secciones, actual = {}, None
    for linea in text.splitlines():
        m = re.fullmatch(r"%([A-Z0-9]+)%", linea.strip())
        if m:
            actual = m.group(1)
            secciones[actual] = []
        elif actual and linea.strip():
            secciones[actual].append(linea.strip())
    return secciones


def cargar(ruta, repo, nombres, grupos, provides):
    with tarfile.open(ruta, "r:*") as tf:
        for miembro in tf:
            if not miembro.isfile() or not miembro.name.endswith("/desc"):
                continue
            sec = parse_desc(tf.extractfile(miembro).read().decode("utf-8", "replace"))
            nombre = (sec.get("NAME") or [None])[0]
            if not nombre:
                continue
            nombres.setdefault(nombre, repo)
            for g in sec.get("GROUPS", []):
                grupos.setdefault(g, repo)
            for p in sec.get("PROVIDES", []):
                provides.setdefault(re.split(r"[<>=]", p)[0], nombre)


def main():
    if len(sys.argv) < 3:
        sys.stderr.write(__doc__)
        return 2
    carpeta, repos = sys.argv[1], sys.argv[2:]
    nombres, grupos, provides = {}, {}, {}
    for repo in repos:
        ruta = os.path.join(carpeta, repo + ".db")
        if not os.path.isfile(ruta):
            if repo == "multilib":
                continue  # opcional
            sys.stderr.write(f"ERROR: falta {ruta}\n")
            return 2
        try:
            cargar(ruta, repo, nombres, grupos, provides)
        except (tarfile.TarError, OSError) as e:
            sys.stderr.write(f"ERROR: no pude leer {ruta}: {e}\n")
            return 2
    for linea in sys.stdin:
        n = linea.strip()
        if not n:
            continue
        if n in nombres:
            repo = nombres[n]
            print("\t".join(["MULTILIB" if repo == "multilib" else "OK", n, repo]))
        elif n in grupos:
            print("\t".join(["GRUPO", n, grupos[n]]))
        elif n in provides:
            print("\t".join(["PROVIDE", n, provides[n]]))
        else:
            print("\t".join(["FALTA", n, "-"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
