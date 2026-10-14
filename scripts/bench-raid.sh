#!/bin/bash
# bench-raid.sh : mesure les performances d'un volume avec fio
# Usage : ./bench-raid.sh <point_de_montage> <etiquette> [fichier_resultats]
# Exemple : ./bench-raid.sh /mnt/bench raid5
set -euo pipefail

MNT="$1"
LABEL="$2"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="${3:-${SCRIPT_DIR}/resultats.csv}"

# Crée l'en-tête du fichier de résultats s'il n'existe pas encore
if [ ! -f "${OUT}" ]; then
    echo "niveau,test,debit_MiB_s,iops" > "${OUT}"
fi

run_test() {
    local name="$1" rw="$2" bs="$3" dir="$4"
    local json="/tmp/fio-${name}.json"

    fio --name="${name}" --directory="${MNT}" --rw="${rw}" --bs="${bs}" \
        --size=512M --runtime=15 --time_based --direct=1 \
        --ioengine=libaio --iodepth=16 --numjobs=1 --group_reporting \
        --output-format=json > "${json}"

    local bw iops mib
    bw=$(jq ".jobs[0].${dir}.bw" "${json}")
    iops=$(jq ".jobs[0].${dir}.iops" "${json}")
    mib=$(awk -v b="${bw}" 'BEGIN { printf "%.1f", b / 1024 }')
    iops=$(awk -v i="${iops}" 'BEGIN { printf "%.0f", i }')

    echo "${LABEL},${name},${mib},${iops}" >> "${OUT}"
    printf "%-12s %-14s %10s MiB/s %10s IOPS\n" "${LABEL}" "${name}" "${mib}" "${iops}"

    rm -f "${MNT}/${name}.0.0" "${json}"
}

run_test ecriture-seq  write     1M write
run_test lecture-seq   read      1M read
run_test lecture-alea  randread  4k read
run_test ecriture-alea randwrite 4k write