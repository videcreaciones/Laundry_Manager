#!/bin/bash
# ============================================================
# setup_phase1.sh — Laundry Manager · Fase 1
# Ejecutar desde la raíz del proyecto Flutter
# ============================================================

set -e  # Detener ante cualquier error

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  LAUNDRY MANAGER — Fase 1: Setup y Dominio"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── PASO 0: Verificar entorno ─────────────────────────────────
echo ""
echo "▶ Verificando entorno Flutter..."
flutter --version
echo ""

# ── PASO 1: Instalar dependencias ────────────────────────────
echo "▶ Instalando dependencias (flutter pub get)..."
flutter pub get
echo "✅ Dependencias instaladas"
echo ""

# ── PASO 2: Verificar integridad del dominio ─────────────────
echo "▶ Analizando capa de dominio (flutter analyze)..."
flutter analyze lib/domain/
echo "✅ Análisis completado"
echo ""

# ── PASO 3: Ejecutar tests de dominio (T-01 a T-11) ──────────
echo "▶ Ejecutando tests del dominio..."
echo ""

flutter test test/domain/value_objects/garment_status_test.dart \
  --reporter expanded \
  --name "T-0[6-9]|T-10|T-11|guardada|lavando|devuelta|label"

echo ""

flutter test test/domain/entities/garment_entity_test.dart \
  --reporter expanded \
  --name "T-0[1-5]|T-03b|camino|validacion|copyWith|igualdad"

echo ""

# ── PASO 4: Coverage del dominio ─────────────────────────────
echo "▶ Generando reporte de cobertura del dominio..."
flutter test test/domain/ \
  --coverage \
  --reporter compact

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Fase 1 completada — Dominio validado"
echo ""
echo "  Próximo paso: Fase 2 — Capa de Datos (Hive)"
echo "  Comando: flutter test test/domain/ --reporter expanded"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
