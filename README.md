# Macro L2

Aplicativo para Windows que repete uma sequência configurável de teclas enquanto a janela escolhida está em primeiro plano.

## Download para Windows

[**Baixar MacroL2.zip**](https://github.com/arilsonbc/MacroL2/releases/latest/download/MacroL2.zip)

Extraia o ZIP e abra **Iniciar.cmd**. Não precisa instalar Python nem baixar o código pelo botão Code.

[Ver versões e arquivos de verificação](https://github.com/arilsonbc/MacroL2/releases)

## Usar

1. Baixe o projeto, extraia os arquivos e abra `Iniciar.cmd`.
2. Preencha a sequência, uma tecla e o intervalo após ela em milissegundos por linha:

   ```text
   F1, 800
   F2, 1000
   F3, 1500
   ```

3. Informe um trecho do título da janela do jogo, como `Lineage`.
4. Clique no campo do atalho e pressione a combinação para ligar/desligar.
5. Clique em **Salvar configuração** para recuperar suas escolhas na próxima execução.
6. Volte ao jogo e use o atalho escolhido para iniciar ou interromper.

Na primeira execução, todos os campos começam vazios. Nenhum atalho global é obrigatório para abrir o programa. F12 não é reservado. Se um atalho salvo estiver ocupado, a janela permanece aberta para escolher outro.

Aceita F1–F12, A–Z, 0–9 e NumPad0–9. Intervalos: 50 a 600000 ms. Requer Windows PowerShell 5.1 e .NET Framework, normalmente incluídos no Windows. O inicializador permite scripts apenas no processo que abre; não altera a política de execução do sistema.

## Comportamento

A sequência se repete até ser desligada. Ao trocar de janela, pausa; ao voltar, continua. O alvo é selecionado no próprio jogo. Desligue antes de escrever no chat: o aplicativo não distingue o chat da interface de combate. Fechar a janela encerra o macro.

O arquivo `config.json` é local e não entra no Git. Teclas são enviadas usando `SendInput`, sem ler memória ou contornar anticheat. Alguns clientes podem bloquear o envio. Confira as regras do servidor antes de usar automação.

## Validação

Verificados: compilação da integração com Windows, construção da interface e abertura com configuração vazia e F12 ocupado. Compatibilidade dentro do Lineage 2 ainda não verificada.
