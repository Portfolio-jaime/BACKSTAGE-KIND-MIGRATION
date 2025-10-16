#!/bin/bash
# Script interactivo para seleccionar y cambiar el contexto de kubectl

set -e

# Obtener la lista de contextos
contexts=( $(kubectl config get-contexts -o name) )

if [ ${#contexts[@]} -eq 0 ]; then
  echo "No se encontraron contextos de Kubernetes configurados."
  exit 1
fi

echo "Contextos disponibles:"
for i in "${!contexts[@]}"; do
  printf "%3d) %s\n" $((i+1)) "${contexts[$i]}"
done

echo ""
read -p "Selecciona el número del contexto al que deseas conectarte: " selection

# Validar que la selección sea un número válido
echo ""
if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#contexts[@]} ]; then
  echo "Selección inválida."
  exit 1
fi

selected_context="${contexts[$((selection-1))]}"

kubectl config use-context "$selected_context"

if [ $? -eq 0 ]; then
  echo "Contexto cambiado exitosamente a: $selected_context"
  echo "Contexto actual: $(kubectl config current-context)"
else
  echo "Error al cambiar el contexto."
  exit 1
fi
