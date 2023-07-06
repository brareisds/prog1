#!/bin/bash

arquivo_base="historico-alg1_SIGA_ANONIMIZADO.csv"

# Questao 1
echo -e "Questao 1:\n"
awk -F',' '$4 != 2 || $5 != 2022 || $8 != 0 || $10 != "Aprovado" ' "$arquivo_base" > arquivo_base_filtrado.csv
cat "$arquivo_base_filtrado.csv"    

# Questao 2 -----------------------------------------------------------
echo -e "\nQuestao 2:\n"
tail -n +2 "$arquivo_base_filtrado.csv" | cut -d ',' -f1,10 | sort | uniq > status_unicos.csv
cut -d ',' -f2 status_unicos.csv | sort | uniq > status_existentes.csv

qtde_status=$(wc -l < "status_existentes.csv")

echo "Numero de individuos unicos de cada status:"
i=1
while [ $i -le $qtde_status ]
do
    status=$(awk -v linha="$i" 'NR == linha {print $1}' status_existentes.csv)
    grep "$status" status_unicos.csv > "status_$status.csv"
    quant=$(wc -l < "status_$status.csv")
    echo "$status = $quant"
    ((i++))
done


# Questao 3 ----------------------------------------------------------------
echo -e "\nQuestao 3:\n"
padrao="Aprovado"
# gera um arquivo com a quantidade de vezes (ordenada da maior para a menor) que cada aluno cursou a materia
cut -d ',' -f1,10 arquivo_base_filtrado.csv | grep -v "$padrao" | cut -d ',' -f1 | sort -n | uniq -c | sort -nr > quant_cursou_novo.csv

# gera um arquivo somente com as matriculas dos alunos que foram aprovados
cut -d ',' -f1,10 arquivo_base_filtrado.csv | grep "$padrao" | cut -d ',' -f1 > aprovados.csv

# Verifica se o aluno com a maior quantidade de vezes que cursou a matéria foi aprovado. Caso contrario, o arquivo que
arquivo="aprovados.csv"
encontrado=0
max_vezes=0

while IFS=' ' read -r linha; do
    matricula=$(awk -v linha="$linha" 'NR == linha {print $2}' quant_cursou_novo.csv)
    if grep -w -q "$matricula" "$arquivo"; then
        encontrado=1
        max_vezes=$(awk -v linha="$linha" 'NR == linha {print $1}' quant_cursou_novo.csv)
        break
    fi
done < "$arquivo"

if [ $encontrado -eq 1 ]; then
    echo "O máximo de vezes que um aluno cursou a matéria antes de ser aprovado foi: $max_vezes"
fi

# Lê o arquivo linha por linha
while IFS=' ' read -r line; do
  # Divide a linha em duas colunas (quantidade e matricula)
  columns=($line)
  
  # Verifica se a primeira coluna é igual a $max_vezes
  if [ "${columns[0]}" == $max_vezes ]; then
    ((count++))
  fi
done < quant_cursou_novo.csv

echo "Quantidade de alunos que cursaram a matéria $max_vezes vezes: $count"

# Questao 4 ----------------------------------------------------------------------
echo -e "\nQuestao 4\n"

separa_anos()
{
    ano=2011
    while [ $ano -le 2022 ]
        do
            cut -d ',' -f1,5,10 arquivo_base_filtrado.csv | grep -w "$ano" > aluno.$ano.csv
            ((ano++))
    done
}

calcula_total_aprovados()
{
    ano=2011
    while [ $ano -le 2022 ]
    do
        alunos=aluno.$ano.csv
        status=Aprovado
   
        cut -d ',' -f1,3 $alunos | grep "$status" |  cut -d ',' -f1 | sort -n -k1,1 | uniq  > aprovados.$ano.csv
    ((ano++))
    done
}

calcula_total_reprovados()
{
    ano=2011
    while [ $ano -le 2022 ]
    do
        alunos=aluno.$ano.csv
        status1=R-freq
        status2=R-nota
        status3=Reprovado

        cut -d ',' -f1,3 $alunos | grep -e "$status1" -e "$status2" -e "$status3" |  cut -d ',' -f1 | sort -n -k1,1 | uniq  > reprovados.$ano.csv
    ((ano++))
    done
}

calcula_porcentagem() {
    ano=2011
    while [ $ano -le 2022 ]
    do
        total_aprovados=$(wc -l < "aprovados.$ano.csv")
        total_reprovados=$(wc -l < "reprovados.$ano.csv")
        total_alunos=$((total_aprovados + total_reprovados))

        # O resultado agora terá duas casas decimais
        porcentagem_aprovacao=$(echo "scale=2; $total_aprovados / $total_alunos * 100" | bc -l)
        porcentagem_reprovacao=$(echo "scale=2; $total_reprovados / $total_alunos * 100" | bc -l)

        echo "Ano $ano:"
        echo "Porcentagem de aprovação: $porcentagem_aprovacao%"
        echo "Porcentagem de reprovação: $porcentagem_reprovacao%"

        ((ano++))
    done
}

# funcoes
separa_anos
calcula_total_aprovados
calcula_total_reprovados
calcula_porcentagem


# Questao 5 - Media de nota dos aprovados (no período total e por ano) --------------------------------------------
echo -e "Questao 5\n"

cut -d ',' -f1,4,5,8,10 arquivo_base_filtrado.csv > notas_gerais.csv

calcula_media_ano_aprovados()
{
    status="Aprovado"
    ano=2011

    while [ $ano -le 2022 ]
    do
        cut -d ',' -f1,2,3,4,5 notas_gerais.csv | awk -F ',' -v ano="$ano" -v status="$status" '$3==ano && $5==status' > notas_aprovados_$ano.csv

        soma_notas=$(cut -d ',' -f4 notas_aprovados_$ano.csv | paste -sd+ | bc)
        quant_alunos=$(wc -l < notas_aprovados_$ano.csv)

        if [ $quant_alunos -gt 0 ]; then
            media=$(echo "scale=2; $soma_notas / $quant_alunos" | bc)
            echo "Ano: $ano, Média das notas: $media"
        else
            echo "Ano: $ano, Média das notas: 0.00"
        fi

        ((ano++))
    done
}

calcula_media_periodo_aprovados()
{
    status="Aprovado"
    ano=2011

    while [ $ano -le 2022 ]
    do
        for periodo in 1 2
        do
            cut -d ',' -f1,2,3,4,5 notas_gerais.csv | awk -F ',' -v periodo="$periodo" -v ano="$ano" -v status="$status" '$2==periodo && $3==ano && $5==status' > notas_aprovados_$ano_$periodo.csv

            soma_notas=$(cut -d ',' -f4 notas_aprovados_$ano_$periodo.csv | paste -sd+ | bc)
            quant_alunos=$(wc -l < notas_aprovados_$ano_$periodo.csv)

            if [ $quant_alunos -gt 0 ]; then
                media=$(echo "scale=2; $soma_notas / $quant_alunos" | bc)
                echo "Ano/periodo: $ano/$periodo, Média das notas: $media"
            else
                echo "Ano/periodo: $ano/$periodo, Média das notas: 0.00"
            fi
        done
        ((ano++))
    done
}

calcula_media_ano_aprovados
calcula_media_periodo_aprovados

# Questao 6 ------------------------------------------------------------

cut -d ',' -f1,4,5,8,10 arquivo_base_filtrado.csv > notas_gerais.csv

calcula_media_ano_reprovados()
{
    status1=R-freq
    status2=R-nota
    status3=Reprovado
    ano=2011

    while [ $ano -le 2022 ]
    do
        cut -d ',' -f1,2,3,4,5 notas_gerais.csv | awk -F ',' -v ano="$ano" -v status1="$status1" -v status2="$status2" -v status3="$status3" '$3==ano && ($5==status1 || $5==status2 || $5==status3)' > notas_reprovados_$ano.csv

        soma_notas=$(cut -d ',' -f4 notas_reprovados_$ano.csv | paste -sd+ | bc)
        quant_alunos=$(wc -l < notas_reprovados_$ano.csv)

        if [ $quant_alunos -gt 0 ]; then
            media=$(echo "scale=2; $soma_notas / $quant_alunos" | bc)
            echo "Ano: $ano, Média das notas: $media"
        else
            echo "Ano: $ano, Média das notas: 0.00"
        fi

        ((ano++))
    done
}

calcula_media_periodo_reprovados()
{
    status1=R-freq
    status2=R-nota
    status3=Reprovado
    ano=2011

    while [ $ano -le 2022 ]
    do
        for periodo in 1 2
        do
            cut -d ',' -f1,2,3,4,5 notas_gerais.csv | awk -F ',' -v periodo="$periodo" -v ano="$ano" -v status1="$status1" -v status2="$status2" -v status3="$status3" '$2==periodo && $3==ano && ($5==status1 || $5==status2 || $5==status3)' > notas_reprovados_$ano_$periodo.csv

            soma_notas=$(cut -d ',' -f4 notas_reprovados_$ano_$periodo.csv | paste -sd+ | bc)
            quant_alunos=$(wc -l < notas_reprovados_$ano_$periodo.csv)

            if [ $quant_alunos -gt 0 ]; then
                media=$(echo "scale=2; $soma_notas / $quant_alunos" | bc)
                echo "Ano/periodo: $ano/$periodo, Média das notas: $media"
            else
                echo "Ano/periodo: $ano/$periodo, Média das notas: 0.00"
            fi
        done
        ((ano++))
    done
}

calcula_media_ano_reprovados
calcula_media_periodo_reprovados

# Questao 7 -----------------------------------------------------------------------------------------------------------------

cut -d ',' -f1,4,5,8,9,10 arquivo_base_filtrado.csv > notas_gerais.csv

calcula_media_frequencia_anual()
{
    status=R-nota
    ano=2011
    echo "Média anual das frequencias dos reprovados por nota: "
    while [ $ano -le 2022 ]
    do
        
        cut -d ',' -f1,3,5,6 notas_gerais.csv | awk -F ',' -v ano="$ano" -v status="$status" '$2==ano && $4==status ' > freq_reprovados_$ano.csv

        soma_freq=$(cut -d ',' -f3 freq_reprovados_$ano.csv | paste -sd+ | bc)
        quant_alunos=$(wc -l < freq_reprovados_$ano.csv)

        if [ $quant_alunos -gt 0 ]; then
            media_freq=$(echo "scale=2; $soma_freq / $quant_alunos" | bc)
            echo "$ano: $media_freq"
        else
            echo "$ano: 0.00"
        fi

        ((ano++))
    done
}

calcula_media_frequencia_total()
{
    status=R-nota
   
    cut -d ',' -f1,5,6 notas_gerais.csv | awk -F ',' -v status="$status" '$3==status ' > freq_reprovados.csv

    soma_freq=$(cut -d ',' -f2 freq_reprovados.csv | paste -sd+ | bc)
    quant_alunos=$(wc -l < freq_reprovados.csv)

    media_freq=$(echo "scale=2; $soma_freq / $quant_alunos" | bc)
    echo "Média total das frequencias dos reprovados por nota: $media_freq"
    
}

calcula_media_frequencia_anual
calcula_media_frequencia_total

#Questao 8 ------------------------------------------------------------------------------------------------------

cut -d ',' -f1,5,14 arquivo_base_filtrado.csv > situacaoDiscente_geral.csv

calcula_evasao_total()
{
    situacaoDiscente=Evasão
    cut -d ',' -f1,3 situacaoDiscente_geral.csv | grep "$situacaoDiscente" > evasao_total.csv
    quant_total=$(wc -l < situacaoDiscente_geral.csv)
    quant_evasao_total=$(wc -l < evasao_total.csv)

    porcentagem_evasao_total=$(echo "scale=2; $quant_evasao_total / $quant_total * 100" | bc -l)
    echo "Porcentagem de evasao total: $porcentagem_evasao_total%"

}

calcula_evasao_anual()
{
    situacaoDiscente=Evasão
    ano=2011

    while [ $ano -le 2022 ]
    do
        # cut -d ',' -f2,3 situacaoDiscente_geral.csv | grep "$situacaoDiscente" -w "$ano" > evasao_$ano.csv
        cut -d ',' -f2,3 situacaoDiscente_geral.csv | awk -F ',' -v ano="$ano" -v situacaoDiscente="$situacaoDiscente" '$1==ano && $2==situacaoDiscente' > evasao_$ano.csv
        cut -d ',' -f2,3 situacaoDiscente_geral.csv | grep -w "$ano" > quant_alunos_$ano.csv
        quant_total=$(wc -l < quant_alunos_$ano.csv)
        quant_evasao_total=$(wc -l < evasao_$ano.csv)

        porcentagem_evasao_anual=$(echo "scale=2; $quant_evasao_total / $quant_total * 100" | bc -l)
        echo "Porcentagem de evasao anual do ano $ano: $porcentagem_evasao_anual%"
        ((ano++))
    done
}


calcula_evasao_anual
calcula_evasao_total

# Questao 9 ---------------------------------------------------------------------------------------------------------
cut -d ',' -f1,5,8,9,10 arquivo_base_filtrado.csv | sort -n -t ',' -k2,2 > todos_anos.csv

ano=2011

while [ $ano -le 2019 ]
do
    grep "$ano" todos_anos.csv > anos_$ano.csv
    ((ano++))
done

cat anos_2011.csv anos_2012.csv anos_2013.csv anos_2014.csv anos_2015.csv anos_2016.csv anos_2017.csv anos_2018.csv anos_2019.csv | sort -n -t ',' -k2,2 > anos_anteriores.csv
    
prim_ano_pandemia=2020
seg_ano_pandemia=2021

cut -d ',' -f2,3,4,5 todos_anos.csv | awk -F ',' -v prim_ano_pandemia="$prim_ano_pandemia" -v seg_ano_pandemia="$seg_ano_pandemia" '$1==prim_ano_pandemia || $1==seg_ano_pandemia' > anos_pandemia.csv

media_nota_anos_anteriores()
{
   
    cut -d ',' -f3,5 anos_anteriores.csv  > notas_anos_anteriores.csv

    soma_media=$(cut -d ',' -f1 notas_anos_anteriores.csv | paste -sd+ | bc)
    quant_alunos=$(wc -l < anos_anteriores.csv)

    media_ant=$(echo "scale=2; $soma_media / $quant_alunos" | bc)
}

media_nota_anos_pandemia()
{
   
    cut -d ',' -f2,4 anos_pandemia.csv  > notas_anos_pandemia.csv

    soma_media=$(cut -d ',' -f1 notas_anos_pandemia.csv | paste -sd+ | bc)
    quant_alunos=$(wc -l < anos_pandemia.csv)

    media_pandemia=$(echo "scale=2; $soma_media / $quant_alunos" | bc)
    # echo "Média notas pandemia: $media_pandemia"
}

media_nota_anos_anteriores
media_nota_anos_pandemia

diferenca=$(echo "$media_pandemia - $media_ant" | bc)
percentual=$(echo "scale=2; $diferenca / $media_ant * 100" | bc -l)

if (( $(echo "$diferenca > 0" | bc -l) )); then
  echo "Notas aumentaram em $percentual%"
elif (( $(echo "$diferenca < 0" | bc -l) )); then
  echo "Notas diminuíram em $(echo "scale=2; $percentual * -1" | bc)%"
else
  echo "Não houve variação nas notas"
fi


media_freq_anos_anteriores()
{
    cut -d ',' -f4 anos_anteriores.csv  > freq_anos_anteriores.csv

    soma_freq=$(cut -d ',' -f1 freq_anos_anteriores.csv | paste -sd+ | bc)
    quant_alunos=$(wc -l < anos_anteriores.csv)

    media_freq_ant=$(echo "scale=2; $soma_freq / $quant_alunos" | bc)
    # echo "Média freq anos anteriores: $media_freq_ant"
}

media_freq_anos_pandemia()
{
    cut -d ',' -f3 anos_pandemia.csv  > freq_anos_pandemia.csv

    soma_freq=$(cut -d ',' -f1 freq_anos_pandemia.csv | paste -sd+ | bc)
    quant_alunos=$(wc -l < anos_pandemia.csv)

    media_freq_pandemia=$(echo "scale=2; $soma_freq / $quant_alunos" | bc)
    # echo "Média freq anos pandemia: $media_freq_pandemia"
}

media_freq_anos_anteriores
media_freq_anos_pandemia

diferenca=$(echo "$media_freq_pandemia - $media_freq_ant" | bc)
percentual_freq=$(echo "scale=2; $diferenca / $media_freq_ant * 100" | bc -l)

if (( $(echo "$diferenca > 0" | bc -l) )); then
  echo "Frequencias aumentaram em $percentual_freq%"
elif (( $(echo "$diferenca < 0" | bc -l) )); then
  echo "Frequencias diminuíram em $(echo "scale=2; $percentual_freq * -1" | bc)%"
else
  echo "Não houve variação nas frequencias"
fi

media_aprov_anos_anteriores()
{
    status=Aprovado
    grep "$status" anos_anteriores.csv > aprovados_ant.csv
    cut -d ',' -f3 aprovados_ant.csv  > notas_aprov_ant.csv

    soma_media_aprov=$(cut -d ',' -f1 notas_aprov_ant.csv | paste -sd+ | bc)
    quant_alunos=$(wc -l < aprovados_ant.csv)

    media_aprov_ant=$(echo "scale=2; $soma_media_aprov / $quant_alunos" | bc)
    # echo "Média notas aprov anteriores: $media_aprov_ant"
}

media_aprov_anos_pandemia()
{
    status=Aprovado
    grep "$status" anos_pandemia.csv > aprovados_pandemia.csv
    cut -d ',' -f3 aprovados_pandemia.csv  > notas_aprov_pandemia.csv

    soma_media_aprov=$(cut -d ',' -f1 notas_aprov_pandemia.csv | paste -sd+ | bc)
    quant_alunos=$(wc -l < aprovados_pandemia.csv)

    media_aprov_pandemia=$(echo "scale=2; $soma_media_aprov / $quant_alunos" | bc)
    # echo "Média notas aprov pandemia: $media_aprov_pandemia"

}

media_aprov_anos_anteriores
media_aprov_anos_pandemia

diferenca=$(echo "$media_aprov_pandemia - $media_aprov_ant" | bc)
percentual_aprov=$(echo "scale=2; $diferenca / $media_aprov_ant * 100" | bc -l)

if (( $(echo "$diferenca > 0" | bc -l) )); then
  echo "Media dos aprovados aumentaram em $percentual_aprov%"
elif (( $(echo "$diferenca < 0" | bc -l) )); then
  echo "Media dos aprovados em $(echo "scale=2; $percentual_aprov * -1" | bc)%"
else
  echo "Não houve variação nas media dos aprovados"
fi


media_reprov_anos_anteriores()
{
    status1=R-freq
    status2=R-nota
    status3=Reprovado

    grep -e "$status1" -e "$status2" -e "$status3" anos_anteriores.csv > reprov_ant.csv
    cut -d ',' -f3 reprov_ant.csv  > notas_reprov_ant.csv

    soma_media_reprov=$(cut -d ',' -f1 notas_reprov_ant.csv | paste -sd+ | bc)
    quant_alunos=$(wc -l < reprov_ant.csv)

    media_reprov_ant=$(echo "scale=2; $soma_media_reprov / $quant_alunos" | bc)
    # echo "Média notas reprov anteriores: $media_reprov_ant"
}

media_reprov_anos_pandemia()
{
    status1=R-freq
    status2=R-nota
    status3=Reprovado

    grep -e "$status1" -e "$status2" -e "$status3" anos_pandemia.csv > reprov_pandemia.csv
    cut -d ',' -f2 reprov_pandemia.csv  > notas_reprov_pandemia.csv

    soma_media_reprov=$(cut -d ',' -f1 notas_reprov_pandemia.csv | paste -sd+ | bc)
    quant_alunos=$(wc -l < reprov_pandemia.csv)

    media_reprov_pandemia=$(echo "scale=2; $soma_media_reprov / $quant_alunos" | bc)
    # echo "Média notas reprov pandemia: $media_reprov_pandemia"
}

media_reprov_anos_anteriores
media_reprov_anos_pandemia


diferenca=$(echo "$media_reprov_pandemia - $media_reprov_ant" | bc)
percentual_reprov=$(echo "scale=2; $diferenca / $media_reprov_ant * 100" | bc -l)

if (( $(echo "$diferenca > 0" | bc -l) )); then
  echo "Media dos reprovados aumentaram em $percentual_reprov%"
elif (( $(echo "$diferenca < 0" | bc -l) )); then
  echo "Media dos reprovados em $(echo "scale=2; $percentual_reprov * -1" | bc)%"
else
  echo "Não houve variação nas media dos reprovados"
fi

# -------------------------------------------------------------------------------------------------------------------------------

media_cancelamentos_anteriores()
{
    status=Cancelado

    grep "$status" anos_anteriores.csv > cancelados_ant.csv

    # echo "Média notas aprov anteriores: $media_aprov_ant"

}
    

#     cut -d ',' -f5 aprovados_pandemia.csv  > notas_aprov_pandemia.csv
#     cut -d ',' -f4 anos_anteriores.csv  > freq_anos_anteriores.csv

#     soma_freq=$(cut -d ',' -f1 freq_anos_anteriores.csv | paste -sd+ | bc)
#     quant_alunos=$(wc -l < anos_anteriores.csv)

#     media_freq_ant=$(echo "scale=2; $soma_freq / $quant_alunos" | bc)
#     # echo "Média freq anos anteriores: $media_freq_ant"
# }

# media_cancelamentos_pandemia()
# {
#     cut -d ',' -f5 anos_pandemia.csv  > freq_anos_pandemia.csv

#     soma_freq=$(cut -d ',' -f1 freq_anos_pandemia.csv | paste -sd+ | bc)
#     quant_alunos=$(wc -l < anos_pandemia.csv)

#     media_freq_pandemia=$(echo "scale=2; $soma_freq / $quant_alunos" | bc)
#     # echo "Média freq anos pandemia: $media_freq_pandemia"
# }